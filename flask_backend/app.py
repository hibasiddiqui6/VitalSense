from flask import Flask, request, jsonify
from flask_cors import CORS
import bcrypt  # For secure password hashing
from db_utils import fetch_data, modify_data  # Import database utility functions

app = Flask(__name__)
CORS(app)

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
                if bcrypt.checkpw(data['Password'].encode(), user['Password'].encode()):
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
                if bcrypt.checkpw(data['Password'].encode(), user['Password'].encode()):
                    return jsonify({"message": "Login successful!", "specialist_id": specialist['SpecialistID']}), 200
                else:
                    return jsonify({"message": "Invalid email or password"}), 401
            else:
                return jsonify({"message": "Health specialist details not found"}), 404
        else:
            return jsonify({"message": "Invalid email or password"}), 401
    except Exception as e:
        return jsonify({"error": "An error occurred, please try again later."}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
