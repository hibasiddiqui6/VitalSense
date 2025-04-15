from flask import Flask, request, jsonify, Response
from flask_cors import CORS
import bcrypt  
from db_utils import fetch_data, fetch_all_data, modify_data, fetch_latest_data, modify_and_return, get_connection
from datetime import datetime, timedelta
import os
import psycopg2
import traceback
import threading
import time
import json
from pytz import timezone
import gevent
from greenlet import getcurrent
from vitals_classifier import classify_temp, classify_respiration
from ecg_realtime_processor import process_ecg_batch
from flask import send_file
from generate_pdf_report import create_pdf
from psycopg2.extras import execute_values
from psycopg2.errors import UniqueViolation

app = Flask(__name__)
CORS(app, resources={r"/*": {"origins": "*"}})

# Store received sensor data (temporary storage for testing)
sensor_data = {}
# In-memory cache to store latest ESP32 MAC and IP (for testing/demo)
mac_ip_cache = {}

app.linked_ids = None
app.last_linked_refresh = None
REFRESH_INTERVAL_SECONDS = 300 

PKT = timezone("Asia/Karachi")

@app.route('/')
def home():
    return 'API is running!', 200

def insert_postgres_only(sensor_data, ids):
    try:
        insert_query = """
            INSERT INTO health_vitals (timestamp, ecg, respiration_rate, temperature, patientID, smartshirtID)
            VALUES (%s, %s, %s, %s, %s, %s)
            RETURNING id
        """
        values = (
            sensor_data["timestamp"],
            sensor_data["ecg"],
            sensor_data["respiration"],
            sensor_data["temperature"],
            ids["patient_id"],
            ids["smartshirt_id"],
        )

        result = modify_and_return(insert_query, values)
        if not result:
            print("⚠️ Insert failed or returned no ID — skipping classification.")
            return

        hv_id = result["id"]
        print(f"[SUCCESS] Inserted ECG record into Postgres with id={hv_id}")

        # Only classify if insert succeeded
        gevent.spawn_later(2, classify_and_insert_temp_status, sensor_data["temperature"], hv_id)
        gevent.spawn_later(2, classify_and_insert_resp_status, sensor_data["respiration"], hv_id)

    except psycopg2.errors.UniqueViolation:
        print("⚠️ Duplicate entry blocked by DB constraint — skipping insert.")
    except Exception as e:
        print(f"❌ insert_postgres_only failed: {e}")
        traceback.print_exc()

def insert_multiple_postgres(sensor_list, ids):
    try:
        insert_query = """
            INSERT INTO health_vitals (timestamp, ecg, respiration_rate, temperature, patientID, smartshirtID)
            VALUES %s
            ON CONFLICT DO NOTHING
            RETURNING id
        """

        values = []
        for sensor_data in sensor_list:
            utc_time = datetime.fromisoformat(sensor_data["timestamp"].replace("Z", "+00:00"))
            values.append((
                utc_time,
                sensor_data["ecg_raw"],
                sensor_data["respiration"],
                sensor_data["temperature"],
                ids["patient_id"],
                ids["smartshirt_id"]
            ))

        conn = get_connection()
        cur = conn.cursor()
        execute_values(cur, insert_query, values)
        returned_ids = cur.fetchall()
        conn.commit()

        inserted_count = len(returned_ids)
        print(f"[SUCCESS] Inserted {inserted_count} batched readings")

        # Classify only inserted entries
        for hv_id, sensor_data in zip([row[0] for row in returned_ids], sensor_list[:inserted_count]):
            gevent.spawn_later(1, classify_and_insert_temp_status, sensor_data["temperature"], hv_id)
            gevent.spawn_later(1, classify_and_insert_resp_status, sensor_data["respiration"], hv_id)

    except UniqueViolation:
        print("⚠️ One or more duplicate entries — some inserts skipped.")
    except Exception as e:
        print(f"❌ insert_multiple_postgres failed: {e}")
        traceback.print_exc()

@app.route('/sensor', methods=['POST'])
def receive_sensor_data():
    try:
        data = request.get_json(force=True)

        if isinstance(data, list):  # Batch mode
            print(f"[BATCH RECEIVED] {len(data)} readings")

            required_fields = ["patient_id", "smartshirt_id", "age", "gender"]
            for field in required_fields:
                if field not in data[0]:
                    return jsonify({"error": f"Missing '{field}' in readings"}), 400

            ids = {
                "patient_id": data[0]["patient_id"],
                "smartshirt_id": data[0]["smartshirt_id"],
                "age": int(data[0].get("age", 0)),
                "gender": data[0].get("gender", "Male")
            }

            gevent.spawn(insert_multiple_postgres, data, ids)
            return jsonify({"status": "batch_received", "count": len(data)}), 200

        # Otherwise fallback to single reading
        process_single_sensor_reading(data)
        return jsonify({"status": "success"}), 200

    except Exception as e:
        print(f"[EXCEPTION] /sensor error: {e}")
        traceback.print_exc()
        return jsonify({"error": "Server error"}), 500

def process_single_sensor_reading(data):
    try:
        ecg = data.get("ecg_raw")
        respiration = data.get("respiration")
        temperature = data.get("temperature")
        raw_timestamp = data.get("timestamp")
        patient_id = data.get("patient_id")
        smartshirt_id = data.get("smartshirt_id")
        age = int(data.get("age", 0))
        gender = data.get("gender", "Male")

        if None in [respiration, temperature, ecg, raw_timestamp, patient_id, smartshirt_id]:
            print("⚠️ Skipped: Missing required sensor fields")
            return

        print(f"[RECEIVED] ECG={ecg}, Resp={respiration}, Temp={temperature}, Time={raw_timestamp}, PID={patient_id}, SID={smartshirt_id}")

        utc_time = datetime.fromisoformat(raw_timestamp.replace("Z", "+00:00"))

        sensor_data = {
            "ecg": ecg,
            "respiration": respiration,
            "temperature": temperature,
            "timestamp": utc_time
        }

        ids = {
            "patient_id": patient_id,
            "smartshirt_id": smartshirt_id,
            "age": age,
            "gender": gender
        }

        # Use gevent for async insert
        gevent.spawn(insert_postgres_only, sensor_data, ids)

    except Exception as e:
        print(f"❌ Failed to process reading: {e}")
        traceback.print_exc()
    
@app.route("/ecg_batch", methods=["POST"])
def ecg_batch():
    try:
        data = request.get_json()
        if not data or not isinstance(data, list):
            return jsonify({"error": "Invalid request format — expected a list of ECG batches"}), 400

        process_ecg_batch(data)
        return jsonify({"message": "Batch processed successfully"}), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500
    
@app.route('/register/patient', methods=['POST'])
def register_patient():
    data = request.json
    try:
        # Always store email in lowercase
        email = data['email'].lower()  

        # Hash and decode password
        hashed_password = bcrypt.hashpw(data['password'].encode(), bcrypt.gensalt()).decode('utf-8')

        # Insert user
        sql_user = "INSERT INTO users (fullname, email, password, role) VALUES (%s, %s, %s, %s)"
        modify_data(sql_user, (data['fullname'], email, hashed_password, 'patient'))

        # Get user ID
        sql_check_user = "SELECT userid FROM users WHERE email = %s"
        user_check_result = fetch_data(sql_check_user, (email,))
        if user_check_result is None:
            return jsonify({"error": "Failed to retrieve UserID from users table"}), 500
        user_id = user_check_result['userid']

        # Insert patient
        sql_patient = "INSERT INTO patients (userid, gender, age, contact, weight) VALUES (%s, %s, %s, %s, %s)"
        modify_data(sql_patient, (user_id, data['gender'], data['age'], data['contact'], data['weight']))

        return jsonify({"message": "Patient registered successfully!"}), 201
    except Exception as e:
        print(f"Error: {e}")
        return jsonify({"error": f"An error occurred: {e}"}), 500

@app.route('/login/patient', methods=['POST'])
def login_patient():
    data = request.json
    try:
        # Fetch user by email in lowercase
        email = data['email'].lower()

        sql = "SELECT * FROM users WHERE LOWER(email) = %s"
        user = fetch_data(sql, (email,))

        if user and user['role'] == 'patient':
            # Fetch patient by userid
            sql_patient = "SELECT * FROM patients WHERE userid = %s"
            patient = fetch_data(sql_patient, (user['userid'],))  

            if patient:
                # Check password
                if bcrypt.checkpw(data['password'].encode(), user['password'].encode()):
                    return jsonify({
                        "message": "Login successful!",
                        "patient_id": patient['patientid'],
                        "age": patient['age'],
                        "gender": patient['gender']
                    }), 200

                else:
                    return jsonify({"message": "Invalid email or password"}), 401
            else:
                return jsonify({"message": "Patient details not found"}), 404
        else:
            return jsonify({"message": "Invalid email or password"}), 401
    except Exception as e:
        print(f"Error during login: {e}")
        return jsonify({"error": "An error occurred, please try again later."}), 500

@app.route('/register/specialist', methods=['POST'])
def register_specialist():
    data = request.json
    try:
        email = data['email'].lower()  

        hashed_password = bcrypt.hashpw(data['password'].encode(), bcrypt.gensalt()).decode('utf-8')

        sql_user = """
        INSERT INTO users (FullName, Email, Password, Role) 
        VALUES (%s, %s, %s, %s)
        """
        modify_data(sql_user, (data['fullname'], email, hashed_password, 'specialist'))

        sql_check_user = "SELECT userid FROM users WHERE email = %s"
        user_check_result = fetch_data(sql_check_user, (email,))

        if user_check_result is None:
            return jsonify({"error": "Failed to retrieve UserID from users table"}), 500

        user_id = user_check_result['userid']  
        print(f"Retrieved UserID from users table: {user_id}")

        sql_specialist = """
        INSERT INTO health_specialist (userid, profession, speciality) 
        VALUES (%s, %s, %s)
        """
        modify_data(sql_specialist, (user_id, data['profession'], data['speciality']))

        return jsonify({"message": "Specialist registered successfully!"}), 201
    except Exception as e:
        print(f"Error: {e}")
        return jsonify({"error": f"An error occurred: {e}"}), 500

@app.route('/login/specialist', methods=['POST'])
def login_specialist():
    data = request.json
    try:
        email = data['email'].lower()  

        sql = "SELECT * FROM users WHERE LOWER(email) = %s"
        user = fetch_data(sql, (email,))

        if user and user['role'] == 'specialist':
            sql_specialist = "SELECT * FROM health_specialist WHERE userid = %s"
            specialist = fetch_data(sql_specialist, (user['userid'],))  

            if specialist:
                if bcrypt.checkpw(data['password'].encode(), user['password'].encode()):
                    return jsonify({"message": "Login successful!", "specialist_id": specialist['specialistid']}), 200  
                else:
                    return jsonify({"message": "Invalid email or password"}), 401
            else:
                return jsonify({"message": "Health specialist details not found"}), 404
        else:
            return jsonify({"message": "Invalid email or password"}), 401
    except Exception as e:
        print(f"Error during specialist login: {e}")
        return jsonify({"error": "An error occurred, please try again later."}), 500

@app.route('/get_patient_id', methods=['GET'])
def get_patient_id():
    """Fetches the patient ID and role using the email address."""
    try:
        email = request.args.get("email")
        if not email:
            return jsonify({"error": "Email is required"}), 400

        # Fetch user details using email
        sql_user = "SELECT userid, role FROM users WHERE email = %s"
        user = fetch_data(sql_user, (email,))

        if not user:
            return jsonify({"error": "User not found"}), 404

        # Fetch the corresponding patient ID
        sql_patient = "SELECT patientid FROM patients WHERE userid = %s"
        patient = fetch_data(sql_patient, (user['userid'],))

        if not patient:
            return jsonify({"error": "Patient record not found"}), 404

        # Return both patient_id and role
        return jsonify({"patient_id": patient['patientid'], "role": user['role']}), 200

    except Exception as e:
        return jsonify({"error": f"An error occurred: {e}"}), 500

@app.route('/get_specialist_id', methods=['GET'])
def get_specialist_id():
    """Fetches the specialist ID using the email address."""
    try:
        email = request.args.get("email")
        if not email:
            return jsonify({"error": "Email is required"}), 400

        # Fetch user details using email
        sql_user = "SELECT userid, role FROM users WHERE email = %s"
        user = fetch_data(sql_user, (email,))

        if not user:
            return jsonify({"error": "User not found"}), 404

        # Fetch the corresponding specialist ID
        sql_specialist = "SELECT specialistid FROM health_specialist WHERE userid = %s"
        specialist = fetch_data(sql_specialist, (user['userid'],))

        if not specialist:
            return jsonify({"error": "Specialist record not found"}), 404

        return jsonify({"specialist_id": specialist['specialistid'], "role": user['role']}), 200

    except Exception as e:
        return jsonify({"error": f"An error occurred: {e}"}), 500
    
@app.route('/register_mac', methods=['POST'])
def register_mac():
    """Registers the ESP32 MAC address separately before sending sensor data."""
    try:
        data = request.json
        mac_address = data.get("mac_address")
        patient_id = data.get("patient_id")

        if not mac_address or not patient_id:
            return jsonify({"error": "MAC address and patient ID are required"}), 400

        # Check if the patient exists
        patient_check = fetch_data("SELECT * FROM patients WHERE patientid = %s", (patient_id,))
        if not patient_check:
            return jsonify({"error": "Invalid Patient ID. Patient does not exist."}), 404

        # Check if the SmartShirt is already registered
        existing_entry = fetch_data("SELECT * FROM smartshirt WHERE devicemac = %s", (mac_address,))
        if existing_entry:
            return jsonify({"message": "SmartShirt already registered!", "smartshirt_id": existing_entry['smartshirtid']}), 200

        # Register new SmartShirt
        sql = "INSERT INTO smartshirt (patientid, devicemac, shirtstatus) VALUES (%s, %s, %s)"
        modify_data(sql, (patient_id, mac_address, True))

        return jsonify({"message": "MAC registered successfully!"}), 201

    except Exception as e:
        return jsonify({"error": f"An error occurred: {e}"}), 500

@app.route('/check_smartshirt', methods=['GET'])
def check_smartshirt():
    try:
        mac_address = request.args.get("mac_address")
        if not mac_address:
            return jsonify({"error": "MAC address is required"}), 400

        result = fetch_data("SELECT devicemac, shirtstatus FROM smartshirt WHERE devicemac = %s", (mac_address,))
        if result:
            return jsonify({"exists": True, "shirt_status": bool(result["shirtstatus"])}), 200
        else:
            return jsonify({"exists": False}), 404
    except Exception as e:
        return jsonify({"error": f"An error occurred: {e}"}), 500

@app.route('/get_smartshirts', methods=['GET'])
def get_smartshirts():
    try:
        patient_id = request.args.get("patient_id")
        if not patient_id:
            return jsonify({"error": "Patient ID is required"}), 400

        results = fetch_all_data("""
            SELECT smartshirtid, devicemac, shirtstatus 
            FROM smartshirt 
            WHERE patientid = %s
        """, (patient_id,))

        if results:
            # Convert ShirtStatus to boolean
            for result in results:
                result["shirtstatus"] = bool(result["shirtstatus"])
            return jsonify({"smartshirts": results}), 200
        else:
            return jsonify({"message": "No SmartShirts found"}), 404
    except Exception as e:
        return jsonify({"error": f"An error occurred: {e}"}), 500
    
@app.route('/delete_smartshirt', methods=['DELETE'])
def delete_smartshirt():
    try:
        data = request.json
        mac = data.get("mac_address")

        if not mac:
            return jsonify({"error": "MAC address is required"}), 400

        # Delete SmartShirt entry
        modify_data("DELETE FROM smartshirt WHERE devicemac = %s", (mac,))
        return jsonify({"message": "SmartShirt deleted"}), 200
    except Exception as e:
        return jsonify({"error": f"Failed to delete SmartShirt: {e}"}), 500
    
@app.route('/send_mac_to_app', methods=['POST'])
def receive_mac():
    data = request.json
    mac = data.get("mac_address")
    ip = data.get("ip_address")

    if not mac or not ip:
        return jsonify({"error": "Missing MAC or IP address"}), 400

    mac_ip_cache["latest"] = {
        "mac_address": mac,
        "ip_address": ip,
        "timestamp": datetime.now()
    }

    print(f"✅ Received MAC: {mac}, IP: {ip}")
    return jsonify({"status": "saved"}), 200

@app.route('/get_latest_mac_ip', methods=['GET'])
def get_latest_mac_ip():
    latest = mac_ip_cache.get("latest")
    if not latest:
        return jsonify({"error": "No ESP32 MAC/IP available"}), 404

    return jsonify({
        "mac_address": latest["mac_address"],
        "ip_address": latest["ip_address"]
    }), 200

@app.route('/get_patient_profile', methods=['GET'])
def get_patient_profile():
    try:
        patient_id = request.args.get("patient_id")

        if not patient_id:
            return jsonify({"error": "Patient ID is required"}), 400

        print(f"🟢 Fetching profile for Patient ID: {patient_id}")

        # **SQL Query to fetch FullName, Gender, and Age**
        sql_query = """
        SELECT u.fullname, u.email, p.gender, p.age, p.contact, p.patientid, p.weight
        FROM patients p
        JOIN users u ON p.userid = u.userid
        WHERE p.patientid = %s
        """
        #, p.Weight
        patient_profile = fetch_data(sql_query, (patient_id,))

        if not patient_profile:
            return jsonify({"error": "No user profile found"}), 404

        return jsonify(patient_profile), 200

    except Exception as e:
        return jsonify({"error": f"An error occurred: {e}"}), 500

@app.route('/get_specialist_profile', methods=['GET'])
def get_specialist_profile():
    try:
        specialist_id = request.args.get("specialist_id")

        if not specialist_id:
            return jsonify({"error": "Specialist ID is required"}), 400

        print(f"🟢 Fetching profile for Specialist ID: {specialist_id}")

        sql_query = """
        SELECT u.fullname, u.email, h.profession, h.speciality, h.specialistid
        FROM health_specialist h
        JOIN users u ON h.userid = u.userid
        WHERE h.specialistid = %s
        """
        
        specialist_profile = fetch_data(sql_query, (specialist_id,))

        if not specialist_profile:
            print(f"No profile found for Specialist ID: {specialist_id}")  # Debugging output
            return jsonify({"error": "No user profile found"}), 404

        return jsonify(specialist_profile), 200

    except Exception as e:
        print(f"Exception occurred: {e}")
        return jsonify({"error": f"An error occurred: {e}"}), 500

@app.route('/update_patient_profile', methods=['POST'])
def update_patient_profile():
    try:
        data = request.json
        patient_id = data.get("patient_id")
        full_name = data.get("full_name")
        gender = data.get("gender")
        age = data.get("age")
        email = data.get("email")
        contact = data.get("contact")
        weight = data.get("weight")

        if not patient_id:
            return jsonify({"error": "Patient ID is required"}), 400

        # **Update `users` table (Full Name & Email)**
        update_user_query = """
        UPDATE users 
        SET fullname = %s, email = %s 
        WHERE userid = (SELECT userid FROM patients WHERE patientid = %s)
        """
        modify_data(update_user_query, (full_name, email, patient_id))

        # **Update `patients` table (Gender, Age, Contact)**
        update_patient_query = """
        UPDATE patients 
        SET gender = %s, age = %s, contact = %s, weight = %s 
        WHERE patientid = %s
        """
        modify_data(update_patient_query, (gender, age, contact, weight, patient_id))

        return jsonify({"message": "Profile updated successfully"}), 200

    except Exception as e:
        return jsonify({"error": f"An error occurred: {e}"}), 500

@app.route('/update_specialist_profile', methods=['POST'])
def update_specialist_profile():
    try:
        data = request.json
        specialist_id = data.get("specialist_id")
        full_name = data.get("full_name")
        email = data.get("email")
        profession = data.get("profession")
        speciality = data.get("speciality")

        if not specialist_id:
            return jsonify({"error": "Specialist ID is required"}), 400

        # Update FullName & Email in users table via UserID lookup
        update_user_query = """
        UPDATE users 
        SET fullname = %s, email = %s 
        WHERE userid = (SELECT userid FROM health_specialist WHERE specialistid = %s)
        """
        modify_data(update_user_query, (full_name, email, specialist_id))

        # Update Profession & Speciality in health_specialist
        update_specialist_query = """
        UPDATE health_specialist 
        SET profession = %s, speciality = %s
        WHERE specialistid = %s
        """
        modify_data(update_specialist_query, (profession, speciality, specialist_id))

        return jsonify({"message": "Specialist profile updated successfully"}), 200

    except Exception as e:
        print(f"Error updating specialist profile: {e}")
        return jsonify({"error": f"An error occurred: {e}"}), 500

@app.route('/get_trusted_contacts', methods=['GET'])
def get_trusted_contacts():
    try:
        patient_id = request.args.get("patient_id")
        if not patient_id:
            return jsonify({"error": "Patient ID is required"}), 400

        print(f"🟢 Fetching trusted contacts for Patient ID: {patient_id}")

        sql_query = """
        SELECT contactid, contactname, contactnumber
        FROM trusted_contacts
        WHERE patientid = %s
        """

        contacts = fetch_all_data(sql_query, (patient_id,))

        if not contacts:
            print("⚠ No contacts found in the database.")
            return jsonify([]), 200  # Return an empty list instead of 404

        return jsonify(contacts), 200  # Always return a list

    except Exception as e:
        print(f"Error fetching contacts: {e}")
        return jsonify({"error": "An error occurred"}), 500

@app.route('/add_trusted_contact', methods=['POST'])
def add_trusted_contact():
    try:
        data = request.json
        patient_id = data.get("patient_id")
        contact_name = data.get("contact_name")
        contact_number = data.get("contact_number")

        if not (patient_id and contact_name and contact_number):
            return jsonify({"error": "Missing required fields"}), 400

        query = "INSERT INTO trusted_contacts (patientid, contactname, contactnumber) VALUES (%s, %s, %s)"
        modify_data(query, (patient_id, contact_name, contact_number))

        return jsonify({"message": "Contact added successfully"}), 201
    except Exception as e:
        return jsonify({"error": f"An error occurred: {e}"}), 500

@app.route('/update_trusted_contact', methods=['POST'])
def update_trusted_contact():
    try:
        data = request.json
        contact_id = data.get("contact_id")
        contact_name = data.get("contact_name")
        contact_number = data.get("contact_number")

        if not (contact_id and contact_name and contact_number):
            return jsonify({"error": "Missing required fields"}), 400

        query = "UPDATE trusted_contacts SET contactname = %s, contactnumber = %s WHERE contactid = %s"
        modify_data(query, (contact_name, contact_number, contact_id))

        return jsonify({"message": "Contact updated successfully"}), 200
    except Exception as e:
        return jsonify({"error": f"An error occurred: {e}"}), 500

@app.route('/delete_trusted_contact', methods=['POST'])
def delete_trusted_contact():
    try:
        data = request.json
        contact_id = data.get("contact_id")

        if not contact_id:
            return jsonify({"error": "Contact ID is required"}), 400

        query = "DELETE FROM trusted_contacts WHERE contactid = %s"
        modify_data(query, (contact_id,))

        return jsonify({"message": "Contact deleted successfully"}), 200
    except Exception as e:
        return jsonify({"error": f"An error occurred: {e}"}), 500
    
@app.route('/specialist/add_patient', methods=['POST'])
def add_patient_to_specialist():
    data = request.json
    try:
        specialist_id = data['specialistid']  # From logged-in specialist context or request
        short_patient_id = data['patientid'].lower()  # e.g., "804dc24d-ec75"

        # Correct to use UUID casted as text
        sql_patient_lookup = """
        SELECT patientid FROM patients 
        WHERE LOWER(SUBSTRING(patientid::text, 1, 13)) = %s
        """
        patient = fetch_data(sql_patient_lookup, (short_patient_id,))

        if not patient:
            return jsonify({"message": "Patient not found"}), 404

        patient_id = patient['patientid']

        # Step 2: Insert into bridge table (patient_specialist)
        sql_add_relation = """
        INSERT INTO patient_specialist (specialistid, patientid)
        VALUES (%s, %s)
        """
        modify_data(sql_add_relation, (specialist_id, patient_id))

        return jsonify({"message": "Patient successfully added!"}), 201

    except Exception as e:
        print(f"Error: {e}")
        return jsonify({"error": "An error occurred while adding the patient."}), 500

@app.route('/specialist/patients/<specialist_id>', methods=['GET'])
def get_specialist_patients(specialist_id):
    try:
        sql = """
        SELECT 
            p.patientid, 
            u.fullname, 
            u.email
        FROM patient_specialist ps
        JOIN patients p ON ps.patientid = p.patientid
        JOIN users u ON p.userid = u.userid
        WHERE ps.specialistid = %s
        ORDER BY ps.hsp_relation_id DESC
        """

        patients = fetch_all_data(sql, (specialist_id,))
        return jsonify({"patients": patients}), 200
    except Exception as e:
        return jsonify({"error": f"Failed to fetch patients: {e}"}), 500

@app.route('/patient_insights/<patient_id>', methods=['GET'])
def get_patient_insights(patient_id):
    try:
        # Check if patient exists
        sql_patient_check = "SELECT * FROM patients WHERE patientid = %s"
        patient_exists = fetch_data(sql_patient_check, (patient_id,))

        if not patient_exists:
            return jsonify({"error": "Patient not found"}), 404

        # Fetch latest health vitals
        sql_vitals = """
        SELECT 
            respiration_rate, 
            temperature, 
            ecg, 
            timestamp
        FROM health_vitals 
        WHERE patientid = %s 
        ORDER BY timestamp DESC 
        LIMIT 1
        """
        vitals = fetch_data(sql_vitals, (patient_id,))

        # Fetch basic patient profile (like gender, age, weight)
        sql_profile = """
        SELECT 
            p.gender, 
            p.age,
            p.weight, 
            u.fullname 
        FROM patients p
        JOIN users u ON p.userid = u.userid
        WHERE p.patientid = %s
        """
        profile = fetch_data(sql_profile, (patient_id,))

        if not profile:
            return jsonify({"error": "Patient profile not found"}), 404

        # Format timestamp to ISO 8601 if exists
        last_updated = None
        if vitals and vitals.get('timestamp'):
            try:
                # Parse SQL timestamp
                raw_timestamp = vitals.get('timestamp')
                dt_object = datetime.strptime(str(raw_timestamp), '%Y-%m-%d %H:%M:%S.%f')
                # Convert to ISO 8601
                last_updated = dt_object.isoformat()  # "2025-03-01T20:27:13.000"
            except Exception as e:
                print(f"Timestamp format issue: {e}")
                last_updated = None

        # Prepare final response
        response = {
            "fullname": profile.get("fullname", "Unknown"),
            "gender": profile.get("gender", "-"),
            "age": profile.get("age", "-"),
            "weight": profile.get("weight", "-"), 
            "respiration_rate": vitals.get("respiration_rate") if vitals else "-",
            "temperature": vitals.get("temperature") if vitals else "-",
            "ecg": vitals.get("ecg") if vitals else "-",
            "last_updated": last_updated if last_updated else None
        }
        print(response)

        return jsonify(response), 200

    except Exception as e:
        print(f"Error fetching patient insights: {e}")
        return jsonify({"error": f"An error occurred: {e}"}), 500

@app.route("/classify_temp_status", methods=["POST"])
def classify_temp_status():
    data = request.get_json()
    temp = float(data.get("temperature", -100))
    age = int(data.get("age", 0))
    gender = data.get("gender", "Male")

    classification = classify_temp(temp, age, gender)
    return jsonify(classification)

def classify_and_insert_temp_status(temp_str, hv_id):
    try:
        query = "SELECT hv.patientid, p.age, p.gender FROM health_vitals hv JOIN patients p ON hv.patientid = p.patientid WHERE hv.id = %s"
        result = fetch_data(query, (hv_id,))
        if not result:
            print(f"[WARN] Skipping classification: hv_id {hv_id} not found")
            return

        age = result["age"]
        gender = result["gender"]

        temp = float(temp_str)
        classification = classify_temp(temp, age, gender)

        status = classification["status"]
        disease = classification["disease"]

        if status == "Sensor Disconnected" or temp > 120:
            # print(f"[SKIP] Temperature status '{status}' — not inserting")
            return

        insert_query = """
            INSERT INTO temperature (healthvitalsid, temperature, temperaturestatus, detecteddisease)
            VALUES (%s, %s, %s, %s)
        """
        modify_data(insert_query, (hv_id, temp, status, disease))
        print(f"[SUCCESS] Inserted temperature for hv_id {hv_id}")

    except Exception as e:
        print(f"❌ classify_and_insert_temp_status failed: {e}")

@app.route('/temperature_trends', methods=['GET'])
def get_temperature_trends():
    patient_id = request.args.get("patient_id")
    range_type = request.args.get("range", "24h").lower()

    if not patient_id:
        return jsonify({"error": "Patient ID is required"}), 400

    now = datetime.now(timezone("Asia/Karachi"))  # Use PKT timezone

    if range_type == "week":
        start_time = now - timedelta(days=7)
    elif range_type == "month":
        start_time = now - timedelta(days=30)
    else:
        start_time = now - timedelta(hours=24)

    query = """
        SELECT hv.timestamp, t.temperature, t.temperaturestatus
        FROM health_vitals hv
        JOIN temperature t ON hv.id = t.healthvitalsid
        WHERE hv.patientID = %s AND hv.timestamp >= %s
        ORDER BY hv.timestamp ASC
    """
    result = fetch_all_data(query, (patient_id, start_time))

    # Convert timestamps to ISO format
    for row in result:
        row["timestamp"] = row["timestamp"].astimezone(timezone("Asia/Karachi")).isoformat()

    return jsonify(result)

@app.route("/classify_respiration_status", methods=["POST"])
def classify_respiration_status():
    data = request.get_json()
    resp = float(data.get("respiration", -1))
    age = int(data.get("age", 0))
    classification = classify_respiration(resp, age)
    return jsonify(classification)

def classify_and_insert_resp_status(resp_str, hv_id):
    try:
        # Ensure health_vitals ID is valid
        query = """
            SELECT patients.age
            FROM health_vitals
            JOIN patients ON patients.patientid = health_vitals.patientid
            WHERE health_vitals.id = %s
        """
        result = fetch_data(query, (hv_id,))
        if not result:
            print(f"[WARN] Skipping respiration classification: hv_id {hv_id} not linked to patient.")
            return

        age = int(result["age"])
        resp = float(resp_str)
        result = classify_respiration(resp, age)

        status = result['status']
        disease = result['disease']

        if status == "Sensor Disconnected" or resp <= 5.0:
            # print(f"[SKIP] Respiration status '{status}' — not inserting")
            return

        insert_query = """
            INSERT INTO respiration (healthvitalsid, respiration, respirationstatus, detecteddisease)
            VALUES (%s, %s, %s, %s)
        """
        modify_data(insert_query, (hv_id, resp, status, disease))
        print(f"[SUCCESS] Inserted respiration for hv_id {hv_id}")

    except Exception as e:
        print(f"❌ classify_and_insert_resp_status failed: {e}")

@app.route('/respiration_trends', methods=['GET'])
def get_respiration_trends():
    patient_id = request.args.get("patient_id")
    range_type = request.args.get("range", "24h").lower()

    if not patient_id:
        return jsonify({"error": "Patient ID is required"}), 400

    now = datetime.now(timezone("Asia/Karachi"))  # Use PKT timezone

    if range_type == "week":
        start_time = now - timedelta(days=7)
    elif range_type == "month":
        start_time = now - timedelta(days=30)
    else:
        start_time = now - timedelta(hours=24)

    query = """
        SELECT hv.timestamp, r.respiration, r.respirationstatus
        FROM health_vitals hv
        JOIN respiration r ON hv.id = r.healthvitalsid
        WHERE hv.patientID = %s AND hv.timestamp >= %s
        ORDER BY hv.timestamp ASC
    """
    result = fetch_all_data(query, (patient_id, start_time))

    # Convert timestamps to ISO format
    for row in result:
        row["timestamp"] = row["timestamp"].astimezone(timezone("Asia/Karachi")).isoformat()

    return jsonify(result)

@app.route('/latest_ecg_status')
def get_latest_ecg_status():
    patient_id = request.args.get("patient_id")
    if not patient_id:
        return jsonify({"error": "Missing patient_id"}), 400

    query = """
        SELECT e.bpm, e.ecgstatus
        FROM ecg e
        JOIN health_vitals hv ON hv.smartshirtid = e.smartshirtid
        WHERE hv.patientID = %s
        ORDER BY hv.timestamp DESC
        LIMIT 1
    """
    result = fetch_data(query, (patient_id,))
    return jsonify(result) if result else jsonify({"error": "No ECG found"}), 200

@app.route("/latest-ecg-segments/<patient_id>", methods=["GET"])
def get_latest_ecg_segments(patient_id):
    try:
        query = """
            SELECT e.bpm, e.hrv, e.rr, e.pr, e.p, e.qrs, e.qt, e.qtc, e.ecgstatus
            FROM ecg e
            JOIN health_vitals hv ON e.healthvitalsid = hv.id
            WHERE hv.patientID = %s
            ORDER BY hv.timestamp DESC
            LIMIT 1
        """
        row = fetch_data(query, (patient_id,))
        if not row:
            return jsonify({"error": "No ECG data found"}), 404

        keys = ["bpm", "hrv", "rr", "pr", "p", "qrs", "qt", "qtc", "ecgstatus"]
        result = dict(zip(keys, row[0]))
        return jsonify(result), 200
    except Exception as e:
        print(f"❌ Error in /latest-ecg-segments: {e}")
        return jsonify({"error": "Server error"}), 500

@app.route('/ecg_trends', methods=['GET'])
def get_ecg_trends():
    patient_id = request.args.get("patient_id")
    range_type = request.args.get("range", "24h").lower()

    if not patient_id:
        return jsonify({"error": "Patient ID is required"}), 400

    now = datetime.now(timezone("Asia/Karachi"))  # Use PKT timezone

    if range_type == "week":
        start_time = now - timedelta(days=7)
    elif range_type == "month":
        start_time = now - timedelta(days=30)
    else:
        start_time = now - timedelta(hours=24)

    query = """
        SELECT hv.timestamp, e.bpm, e.ecgstatus
        FROM health_vitals hv
        JOIN ecg e ON hv.id = e.healthvitalsid
        WHERE hv.patientID = %s AND hv.timestamp >= %s
        ORDER BY hv.timestamp ASC
    """
    result = fetch_all_data(query, (patient_id, start_time))

    # Convert timestamps to ISO format
    for row in result:
        row["timestamp"] = row["timestamp"].astimezone(timezone("Asia/Karachi")).isoformat()

    return jsonify(result)

def schedule_report_generation(patient_id, smartshirt_id, session_start, delay_sec=10):
    def task():
        print(f"⏳ Scheduling report generation in {delay_sec} seconds...")
        time.sleep(delay_sec)
        session_end = datetime.now(PKT)

        # Use a local alias just in case we want to modify it later
        localized_start = session_start

        print(f"[Scheduled] session_start: {localized_start} ({localized_start.tzinfo})")
        print(f"[Scheduled] session_end: {session_end} ({session_end.tzinfo})")

        try:
            with app.app_context():
                generate_report_logic(patient_id, smartshirt_id, localized_start, session_end)
            print("✅ Background report generation complete.")
        except Exception as e:
            print(f"❌ Failed in background report gen: {e}")
    threading.Thread(target=task).start()

@app.route("/generate_report", methods=["POST"])
def generate_report():
    try:
        data = request.get_json()
        patient_id = data["patient_id"]
        smartshirt_id = data["smartshirt_id"]
        session_start = datetime.fromisoformat(data["session_start"])
        session_end = datetime.fromisoformat(data["session_end"])

        if session_start.tzinfo is None:
            session_start = session_start.replace(tzinfo=PKT)

        if session_end.tzinfo is None:
            session_end = session_end.replace(tzinfo=PKT)

        print(f"session_start: {session_start} ({session_start.tzinfo})")
        print(f"session_end: {session_end} ({session_end.tzinfo})")

        result = generate_report_logic(patient_id, smartshirt_id, session_start, session_end)
        if "error" in result:
            return jsonify(result), 404
        return jsonify(result), 200

    except Exception as e:
        print(f"❌ Failed to generate report: {e}")
        traceback.print_exc()
        return jsonify({"error": "Server error"}), 500
    
def generate_report_logic(patient_id, smartshirt_id, session_start, session_end):
    # Fetch joined classified data within the session range
    query = """
        SELECT 
            u.fullname, p.age, p.gender, p.weight,
            e.bpm, e.ecgstatus, e.pr, e.qrs, e.qt, e.rr, e.p, e.qtc, e.hrv,
            t.temperature, t.temperaturestatus,
            r.respiration, r.respirationstatus
        FROM health_vitals hv
        LEFT JOIN ecg e ON e.healthvitalsid = hv.id
        LEFT JOIN temperature t ON t.healthvitalsid = hv.id
        LEFT JOIN respiration r ON r.healthvitalsid = hv.id
        JOIN patients p ON hv.patientid = p.patientid
        JOIN users u ON p.userid = u.userid
        WHERE hv.patientid = %s AND hv.timestamp BETWEEN %s AND %s

    """
    rows = fetch_all_data(query, (patient_id, session_start, session_end))
    if not rows:
        print("⚠️ No vitals found for session.")
        return {"error": "No vitals found for session"}

    bpms = [float(r["bpm"]) for r in rows if r["bpm"] not in [None, "", "-"]]
    temps = [float(r["temperature"]) for r in rows if r["temperature"] not in [None, "", "-"]]
    resps = [float(r["respiration"]) for r in rows if r["respiration"] not in [None, "", "-"]]

    ecg_statuses = [r["ecgstatus"] for r in rows if r["ecgstatus"] not in [None, "", "Sensor Disconnected"]]
    temp_statuses = [r["temperaturestatus"] for r in rows if r["temperaturestatus"] not in [None, "", "Sensor Disconnected"]]
    resp_statuses = [r["respirationstatus"] for r in rows if r["respirationstatus"] not in [None, "", "Sensor Disconnected"]]

    bpm_avg = sum(bpms) / len(bpms) if bpms else None
    temp_avg = sum(temps) / len(temps) if temps else None
    resp_avg = sum(resps) / len(resps) if resps else None

    from collections import Counter
    def most_common(statuses): return Counter(statuses).most_common(1)[0][0] if statuses else "-"

    ecg_status = most_common(ecg_statuses)
    temp_status = most_common(temp_statuses)
    resp_status = most_common(resp_statuses)

    # Get specific recommendations
    temp_rec = get_recommendation_by_vital("Temperature", temp_status)
    resp_rec = get_recommendation_by_vital("Respiration", resp_status)
    ecg_rec = get_recommendation_by_vital("ECG", ecg_status)

    # Fallbacks
    default_title = "No Recommendation"
    default_msg = "Please consult your healthcare provider."

    # Compose recommendations
    recommendation = {
        "temperature": {
            "title": temp_rec["title"] if temp_rec else default_title,
            "message": temp_rec["message"] if temp_rec else default_msg
        },
        "respiration": {
            "title": resp_rec["title"] if resp_rec else default_title,
            "message": resp_rec["message"] if resp_rec else default_msg
        },
        "ecg": {
            "title": ecg_rec["title"] if ecg_rec else default_title,
            "message": ecg_rec["message"] if ecg_rec else default_msg
        }
    }

    # Determine severity and main recommendation based on the most critical vital
    vital_statuses = {
        "temperature": temp_status,
        "respiration": resp_status,
        "ecg": ecg_status,
    }
    most_critical_vital = min(vital_statuses, key=lambda v: get_priority_index(vital_statuses[v]))
    most_critical_status = vital_statuses[most_critical_vital]
    severity = most_critical_status if most_critical_status != "Normal" else "Normal"
    recommendation_title = recommendation[most_critical_vital]["title"]

    patient_info = rows[0]
    # Collect ECG metrics dynamically
    ecg_metrics = {
        k: v for k, v in {
            "PR Interval": patient_info.get("pr"),
            "QRS Complex": patient_info.get("qrs"),
            "QT Interval": patient_info.get("qt"),
            "RR": patient_info.get("rr"),
            "P": patient_info.get("p"),
            "QTC": patient_info.get("qtc"),
            "HRV": patient_info.get("hrv"),
        }.items() if v not in [None, "", "-"]
    }

    insert_query = """
        INSERT INTO reports (
            patient_id, smartshirt_id, session_start, session_end,
            full_name, age, gender, weight,
            avg_bpm, avg_temp, avg_resp,
            temp_status, resp_status, ecg_status,
            severity, recommendation,
            recommendations_by_vital
        )
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        RETURNING id
    """
    report_id = modify_and_return(insert_query, (
        patient_id, smartshirt_id, session_start, session_end,
        patient_info["fullname"], patient_info["age"], patient_info["gender"], patient_info["weight"],
        round(bpm_avg, 1) if bpm_avg else None,
        round(temp_avg, 1) if temp_avg else None,
        round(resp_avg, 1) if resp_avg else None,
        temp_status, resp_status, ecg_status,
        severity, recommendation_title,
        json.dumps(recommendation) 
    ))["id"]

    return {
        "status": "success",
        "report_id": report_id,
        "severity": severity,
        "recommendation": recommendation_title,  # main summary
        "recommendations_by_vital": recommendation,  # per-vital details
        "avg_bpm": round(bpm_avg, 1) if bpm_avg else "-",
        "avg_temp": round(temp_avg, 1) if temp_avg else "-",
        "avg_resp": round(resp_avg, 1) if resp_avg else "-",
        "temp_status": temp_status,
        "resp_status": resp_status,
        "ecg_status": ecg_status,
        "ecg_metrics": ecg_metrics,
        "date": session_end.date().isoformat(),
        "time": session_end.time().isoformat(timespec='minutes')
    }

@app.route("/end_session", methods=["POST"])
def end_session():
    try:
        data = request.get_json()
        patient_id = data["patient_id"]
        smartshirt_id = data["smartshirt_id"]
        session_start = datetime.fromisoformat(data["session_start"])

        if session_start.tzinfo is None:
            session_start = PKT.localize(session_start)

        # Launch background scheduler
        schedule_report_generation(patient_id, smartshirt_id, session_start)

        return jsonify({"status": "Report will be generated shortly"}), 200

    except Exception as e:
        print(f"❌ /end_session error: {e}")
        traceback.print_exc()
        return jsonify({"error": "Server error"}), 500

@app.route("/get_reports", methods=["GET"])
def get_reports():
    patient_id = request.args.get("patient_id")
    range_type = request.args.get("range", "24h").lower()

    if not patient_id:
        return jsonify({"error": "Missing patient ID"}), 400

    now = datetime.now()
    if range_type == "week":
        start_time = now - timedelta(days=7)
    elif range_type == "month":
        start_time = now - timedelta(days=30)
    else:
        start_time = now - timedelta(hours=24)

    query = """
        SELECT id, full_name, age, gender, weight,
            avg_bpm, avg_temp, avg_resp,
            temp_status, resp_status, ecg_status,
            severity, recommendation,
            recommendations_by_vital,
            session_start::text as session_start,
            session_end::text as session_end,  
            to_char(session_end, 'YYYY-MM-DD') as date,
            to_char(session_end, 'HH24:MI') as time
        FROM reports
        WHERE patient_id = %s AND session_end >= %s
        ORDER BY session_end DESC

    """
    rows = fetch_all_data(query, (patient_id, start_time))

    # Format timestamp fields to ISO 8601 with +05:00
    for row in rows:
        if isinstance(row.get("session_start"), datetime):
            row["session_start"] = row["session_start"].isoformat()
        if isinstance(row.get("session_end"), datetime):
            row["session_end"] = row["session_end"].isoformat()

    return jsonify(rows) 

@app.route('/delete_report/<int:report_id>', methods=['DELETE'])
def delete_report(report_id):
    query = "DELETE FROM reports WHERE id = %s RETURNING id"
    deleted = modify_and_return(query, (report_id,))  # ✅ use proper function

    if not deleted:
        return jsonify({"error": "Report not found"}), 404

    return jsonify({"message": "Report deleted", "deleted_id": deleted["id"]}), 200

@app.route('/download_report/<int:report_id>', methods=['GET'])
def download_report(report_id):
    query = "SELECT * FROM reports WHERE id = %s"
    report = fetch_data(query, (report_id,))
    if not report:
        return jsonify({"error": "Report not found"}), 404

    pdf_buffer = create_pdf(report)
    return send_file(pdf_buffer, as_attachment=True, download_name=f"report_{report_id}.pdf", mimetype='application/pdf')

def get_priority_index(status):
        order = ["Critical", "Very High", "High", "Low", "Slow", "Rapid", "Elevated", "Below Normal", "Unknown", "Normal"]
        return order.index(status) if status in order else len(order)

def get_recommendation_by_vital(vital_name, status):
    query = """
        SELECT title, message FROM recommendations
        WHERE vital_name = %s AND status = %s AND active = TRUE
    """
    rec = fetch_data(query, (vital_name, status))
    
    if not rec:
        print(f"⚠️ No recommendation found for {vital_name} with status '{status}'")

    print(f"Recommendation found for {vital_name} with status '{status}'")
    return rec

@app.route('/testhook', methods=['POST'])
def testhook():
    print(f"[HOOK] Received: {request.json}")
    return jsonify({"status": "received"}), 200

@app.route('/ping', methods=['GET'])
def ping():
    return jsonify({"status": "online"}), 200

@app.before_request
def log_start():
    print(f"[greenlet-{id(getcurrent())}] ▶️ {datetime.now()} {request.method} {request.path}")

@app.after_request
def log_end(response):
    print(f"[greenlet-{id(getcurrent())}] ✅ {datetime.now()} Done: {request.method} {request.path}")
    return response

if __name__ == '__main__':
    # For local testing only
    from gevent.pywsgi import WSGIServer
    port = int(os.environ.get('PORT', 5000))
    print(f"🌐 Starting dev server on port {port}")
    http_server = WSGIServer(('0.0.0.0', port), app)
    http_server.serve_forever()
