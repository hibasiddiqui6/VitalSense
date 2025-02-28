from flask import Flask, request, jsonify
from flask_cors import CORS
import bcrypt  # For secure password hashing
from db_utils import fetch_data, fetch_all_data, modify_data  # Import database utility functions
import time

app = Flask(__name__)
CORS(app, resources={r"/*": {"origins": "*"}})

# Store received sensor data (temporary storage for testing)
sensor_data = {}

#Register a Patient
@app.route('/register/patient', methods=['POST'])
def register_patient():
    data = request.json
    try:
        # Hash the password using bcrypt
        hashed_password = bcrypt.hashpw(data['Password'].encode(), bcrypt.gensalt())

        # Insert the new user into the users table
        sql_user = """
        INSERT INTO users (FullName, Email, Password, Role) 
        VALUES (%s, %s, %s, %s)
        """
        modify_data(sql_user, (data['FullName'], data['Email'], hashed_password, 'patient'))

        # Retrieve UserID by looking up the user via email
        sql_check_user = "SELECT UserID FROM users WHERE Email = %s"
        user_check_result = fetch_data(sql_check_user, (data['Email'],))

        if user_check_result is None:
            return jsonify({"error": "Failed to retrieve UserID from users table"}), 500

        user_id = user_check_result['UserID']
        print(f"Retrieved UserID from users table: {user_id}")  # Debugging output

        # Now insert the patient details into the patients table
        sql_patient = """
        INSERT INTO patients (UserID, Gender, Age, Contact) 
        VALUES (%s, %s, %s, %s)
        """
        modify_data(sql_patient, (user_id, data['Gender'], data['Age'], data['Contact']))

        return jsonify({"message": "Patient registered successfully!"}), 201
    except Exception as e:
        print(f"Error: {e}")  # Debugging the full error
        return jsonify({"error": f"An error occurred: {e}"}), 500

# Login for a patient
@app.route('/login/patient', methods=['POST'])
def login_patient():
    data = request.json
    try:
        # Fetch the user data based on the email
        sql = "SELECT * FROM users WHERE Email = %s"
        user = fetch_data(sql, (data['Email'],))

        if user and user['Role'] == 'patient':  # Ensure user exists and is a patient
            # Fetch the patient details based on UserID
            sql_patient = "SELECT * FROM patients WHERE UserID = %s"
            patient = fetch_data(sql_patient, (user['UserID'],))

            if patient:  # Ensure patient details exist
                # Check the hashed password using bcrypt
                if bcrypt.checkpw(data['Password'].encode(), user['Password'].encode('utf-8')):
                    return jsonify({"message": "Login successful!", "patient_id": patient['PatientID']}), 200
                else:
                    return jsonify({"message": "Invalid email or password"}), 401
            else:
                return jsonify({"message": "Patient details not found"}), 404
        else:
            return jsonify({"message": "Invalid email or password"}), 401
    except Exception as e:
        return jsonify({"error": "An error occurred, please try again later."}), 500

# Register a Specialist
@app.route('/register/specialist', methods=['POST'])
def register_specialist():
    data = request.json
    try:
        # Hash the password using bcrypt
        hashed_password = bcrypt.hashpw(data['Password'].encode(), bcrypt.gensalt())

        # Insert the new user into the users table
        sql_user = """
        INSERT INTO users (FullName, Email, Password, Role) 
        VALUES (%s, %s, %s, %s)
        """
        modify_data(sql_user, (data['FullName'], data['Email'], hashed_password, 'healthcare specialist'))

        # Retrieve UserID by looking up the user via email
        sql_check_user = "SELECT UserID FROM users WHERE Email = %s"
        user_check_result = fetch_data(sql_check_user, (data['Email'],))

        if user_check_result is None:
            return jsonify({"error": "Failed to retrieve UserID from users table"}), 500

        user_id = user_check_result['UserID']
        print(f"Retrieved UserID from users table: {user_id}")  # Debugging output

        # Now insert the specialist details into the health_specialist table
        sql_specialist = """
        INSERT INTO health_specialist (UserID, Profession, Speciality) 
        VALUES (%s, %s, %s)
        """
        modify_data(sql_specialist, (user_id, data['Profession'], data['Speciality']))

        return jsonify({"message": "Specialist registered successfully!"}), 201
    except Exception as e:
        print(f"Error: {e}")  # Debugging the full error
        return jsonify({"error": f"An error occurred: {e}"}), 500

# Login for a health specialist
@app.route('/login/specialist', methods=['POST'])
def login_specialist():
    data = request.json
    try:
        # Fetch the user data based on the email
        sql = "SELECT * FROM users WHERE Email = %s"
        user = fetch_data(sql, (data['Email'],))

        if user and user['Role'] == 'healthcarespecialist':  # Ensure user exists and is a health specialist
            # Fetch the health specialist details based on UserID
            sql_specialist = "SELECT * FROM health_specialist WHERE UserID = %s"
            specialist = fetch_data(sql_specialist, (user['UserID'],))

            if specialist:  # Ensure health specialist details exist
                # Check the hashed password using bcrypt
                if bcrypt.checkpw(data['Password'].encode(), user['Password'].encode('utf-8')):
                    return jsonify({"message": "Login successful!", "specialist_id": specialist['SpecialistID']}), 200
                else:
                    return jsonify({"message": "Invalid email or password"}), 401
            else:
                return jsonify({"message": "Health specialist details not found"}), 404
        else:
            return jsonify({"message": "Invalid email or password"}), 401
    except Exception as e:
        return jsonify({"error": "An error occurred, please try again later."}), 500

@app.route('/sensor', methods=['POST'])
def receive_sensor_data():
    global sensor_data
    try:
        data = request.json
        sensor_data = {
            "ecg": data.get("ecg", 0),
            "respiration": data.get("respiration", 0),
            "temperature": data.get("temperature", 0),
            "timestamp": time.time()
        }
        print(f"Received Data: {sensor_data}")
        return jsonify({"status": "success", "data": sensor_data}), 200
    except Exception as e:
        return jsonify({"error": f"An error occurred: {e}"}), 500

@app.route('/get_sensor', methods=['GET'])
def get_sensor_data():
    if not sensor_data:
        return jsonify({"error": "No sensor data"}), 500

    # **Check if the data is older than 10 seconds**
    current_time = time.time()
    if current_time - sensor_data["timestamp"] > 10:
        return jsonify({"error": "No recent sensor data"}), 500

    return jsonify(sensor_data)

@app.route('/get_patient_id', methods=['GET'])
def get_patient_id():
    """Fetches the patient ID using the email address."""
    try:
        email = request.args.get("email")
        if not email:
            return jsonify({"error": "Email is required"}), 400

        # Fetch user details using email
        sql_user = "SELECT UserID FROM users WHERE Email = %s"
        user = fetch_data(sql_user, (email,))

        if not user:
            return jsonify({"error": "User not found"}), 404

        # Fetch the corresponding patient ID
        sql_patient = "SELECT PatientID FROM patients WHERE UserID = %s"
        patient = fetch_data(sql_patient, (user['UserID'],))

        if not patient:
            return jsonify({"error": "Patient record not found"}), 404

        return jsonify({"patient_id": patient['PatientID']}), 200

    except Exception as e:
        return jsonify({"error": f"An error occurred: {e}"}), 500

# ---------------------------- SMARTSHIRT REGISTRATION -----------------------------------

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
        patient_check = fetch_data("SELECT * FROM patients WHERE PatientID = %s", (patient_id,))
        if not patient_check:
            return jsonify({"error": "Invalid Patient ID. Patient does not exist."}), 404

        # Check if the SmartShirt is already registered
        existing_entry = fetch_data("SELECT * FROM smartshirt WHERE DeviceMAC = %s", (mac_address,))
        if existing_entry:
            return jsonify({"message": "SmartShirt already registered!", "smartshirt_id": existing_entry['smartshirtID']}), 200

        # Register new SmartShirt
        sql = "INSERT INTO smartshirt (patientID, DeviceMAC, ShirtStatus) VALUES (%s, %s, %s)"
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

        result = fetch_data("SELECT DeviceMAC, ShirtStatus FROM smartshirt WHERE DeviceMAC = %s", (mac_address,))
        if result:
            return jsonify({"exists": True, "shirt_status": bool(result["ShirtStatus"])}), 200
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

        results = fetch_all_data("SELECT DeviceMAC, ShirtStatus FROM smartshirt WHERE patientID = %s", (patient_id,))
        if results:
            # Convert ShirtStatus to boolean
            for result in results:
                result["ShirtStatus"] = bool(result["ShirtStatus"])
            return jsonify({"smartshirts": results}), 200
        else:
            return jsonify({"message": "No SmartShirts found"}), 404
    except Exception as e:
        return jsonify({"error": f"An error occurred: {e}"}), 500
    
@app.route('/send_mac_to_app', methods=['POST'])
def receive_mac_from_esp():
    try:
        data = request.json
        mac_address = data.get("mac_address")

        if not mac_address:
            return jsonify({"error": "MAC address is required"}), 400

        print(f"Received MAC Address from ESP32: {mac_address}")

        return jsonify({"message": "MAC Address received successfully!"}), 200

    except Exception as e:
        return jsonify({"error": f"An error occurred: {e}"}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False) 