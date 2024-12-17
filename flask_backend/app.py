from flask import Flask, request, jsonify
from flask_cors import CORS
import bcrypt  # For secure password hashing
from db_utils import fetch_data, modify_data  # Import database utility functions

app = Flask(__name__)
CORS(app)

@app.route('/register', methods=['POST'])
def register_patient():
    data = request.json
    try:
        # Hash the password using bcrypt
        hashed_password = bcrypt.hashpw(data['Password'].encode(), bcrypt.gensalt())

        sql = """
        INSERT INTO patient_details (FullName, Gender, Age, Email, Password) 
        VALUES (%s, %s, %s, %s, %s)
        """
        modify_data(sql, (data['FullName'], data['Gender'], data['Age'], data['Email'], hashed_password))
        return jsonify({"message": "Patient registered successfully!"}), 201
    except Exception as e:
        return jsonify({"error": "An error occurred, please try again later."}), 500

@app.route('/login', methods=['POST'])
def login_patient():
    data = request.json
    try:
        sql = "SELECT * FROM patient_details WHERE Email = %s"
        patient = fetch_data(sql, (data['Email'],))

        if patient:  # Ensure patient exists
            # Check the hashed password using bcrypt
            if bcrypt.checkpw(data['Password'].encode(), patient['Password'].encode()):
                return jsonify({"message": "Login successful!", "patient_id": patient['PatientID']}), 200
            else:
                return jsonify({"message": "Invalid email or password"}), 401
        else:
            return jsonify({"message": "Invalid email or password"}), 401
    except Exception as e:
        return jsonify({"error": "An error occurred, please try again later."}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
