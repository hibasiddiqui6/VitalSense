import unittest
import requests

BASE_URL = "https://vitalsense-flask-backend.fly.dev"

class IntegrationTests(unittest.TestCase):

    def test_01_ping(self):
        """Server should respond with status online"""
        res = requests.get(f"{BASE_URL}/ping")
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.json(), {"status": "online"})

    def test_02_login_patient_success(self):
        """Should login with correct credentials"""
        payload = {
            "email": "integration.patient@example.com",
            "password": "testpass123"
        }
        res = requests.post(f"{BASE_URL}/login/patient", json=payload)
        self.assertEqual(res.status_code, 200)
        self.assertIn("patient_id", res.json())
        print(f"Login response: {res.status_code} => {res.json()}")

    def test_03_login_patient_fail_wrong_password(self):
        payload = {
            "email": "integration.patient@example.com",
            "password": "wrongpassword123"  # intentionally wrong
        }
        res = requests.post(f"{BASE_URL}/login/patient", json=payload)
        
        print(f"Wrong password login => {res.status_code}, {res.json()}")
        
        # Assert response status is 401
        self.assertEqual(res.status_code, 401)
        
        # Optional: You can also assert error message if it’s consistent
        self.assertIn("message", res.json())
        self.assertEqual(res.json()["message"], "Invalid email or password")


    def test_04_get_patient_profile_missing_id(self):
        """Should fail if patient ID is missing"""
        res = requests.get(f"{BASE_URL}/get_patient_profile")
        self.assertEqual(res.status_code, 400)
        self.assertIn("error", res.json())

    def test_05_classify_temp_status(self):
        """Should classify temperature"""
        res = requests.post(f"{BASE_URL}/classify_temp_status", json={"temperature": 39.2})
        self.assertEqual(res.status_code, 200)
        self.assertIn("status", res.json())
        print(f"Classification: {res.json()}")

    def test_06_sensor_batch_missing_field(self):
        payload = [
            {
                # "patient_id" is missing
                "smartshirt_id": "SHIRT123",
                "age": 28,
                "gender": "F",
                "ecg": [0.1, 0.2, 0.3]
            }
        ]
        res = requests.post(f"{BASE_URL}/sensor", json=payload)
        self.assertEqual(res.status_code, 400)
        self.assertIn("error", res.json())
        print(f"Missing field test => {res.status_code}, {res.json()}")

    def test_07_ecg_batch_invalid_format(self):
        """Should fail if the format is not a list"""
        payload = {
            "patient_id": "12345",
            "smartshirt_id": "SHIRT123",
            "age": 28,
            "gender": "F",
            "ecg": [0.1, 0.2, 0.3]
        }
        res = requests.post(f"{BASE_URL}/ecg_batch", json=payload)
        self.assertEqual(res.status_code, 400)
        self.assertIn("error", res.json())
        self.assertEqual(res.json()["error"], "Invalid request format — expected a list of ECG batches")
        print(f"Invalid format test => {res.status_code}, {res.json()}")

    def test_08_ecg_batch_empty_payload(self):
        """Should fail if the payload is empty"""
        res = requests.post(f"{BASE_URL}/ecg_batch", json=[])
        self.assertEqual(res.status_code, 400)
        self.assertIn("error", res.json())
        self.assertEqual(res.json()["error"], "Invalid request format — expected a list of ECG batches")
        print(f"Empty payload test => {res.status_code}, {res.json()}")

    def test_09_register_mac_existing_smartshirt(self):
        """Should return existing SmartShirt entry if already registered"""
        payload = {
            "mac_address": "D4:8A:FC:C8:DC:A0", 
            "patient_id": '2c3d0ea6-6bb9-40c8-90c9-7c2b72b7a810'
        }
        res = requests.post(f"{BASE_URL}/register_mac", json=payload)
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.json()["message"], "SmartShirt already registered!")
        print(f"Existing SmartShirt test => {res.status_code}, {res.json()}")

if __name__ == "__main__":
    unittest.main()
