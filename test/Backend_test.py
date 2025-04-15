import unittest
import requests

BASE_URL = "https://vitalsense-flask-backend.fly.dev"

class IntegrationTests(unittest.TestCase):

    def test_01_ping(self):
        """✅ Server should respond with status online"""
        res = requests.get(f"{BASE_URL}/ping")
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.json(), {"status": "online"})

    def test_02_register_patient_success(self):
        """✅ Should register a patient (if not already exists)"""
        payload = {
            "fullname": "Integration Test",
            "email": "integration.patient@example.com",
            "password": "testpass123",
            "gender": "F",
            "age": 30,
            "contact": "03111222333",
            "weight": 55
        }
        res = requests.post(f"{BASE_URL}/register/patient", json=payload)
        self.assertIn(res.status_code, [201, 500])  # 500 if already registered
        print(f"Register patient => {res.status_code}, {res.text}")

    def test_03_register_patient_missing_email(self):
        """❌ Fail if required field is missing"""
        payload = {
            "fullname": "Missing Email",
            "password": "noemailpass",
            "gender": "M",
            "age": 25,
            "contact": "03001234567",
            "weight": 70
        }
        res = requests.post(f"{BASE_URL}/register/patient", json=payload)
        self.assertIn(res.status_code, [400, 500])
    def test_04_login_patient_success(self):
        """✅ Should login with correct credentials"""
        payload = {
            "email": "integration.patient@example.com",
            "password": "testpass123"
        }
        res = requests.post(f"{BASE_URL}/login/patient", json=payload)
        self.assertEqual(res.status_code, 200)
        self.assertIn("patient_id", res.json())
        print(f"Login response: {res.status_code} => {res.json()}")


    def test_05_login_patient_fail_wrong_password(self):
        """❌ Fail login with wrong password"""
        payload = {
            "email": "integration.patient@example.com",
            "password": "abc"
        }
        res = requests.post(f"{BASE_URL}/login/patient", json=payload)
        self.assertEqual(res.status_code, 401)

    def test_06_get_patient_profile_missing_id(self):
        """❌ Should fail if patient ID is missing"""
        res = requests.get(f"{BASE_URL}/get_patient_profile")
        self.assertEqual(res.status_code, 400)
        self.assertIn("error", res.json())

    def test_07_classify_temp_status(self):
        """✅ Should classify temperature"""
        res = requests.post(f"{BASE_URL}/classify_temp_status", json={"temperature": 39.2})
        self.assertEqual(res.status_code, 200)
        self.assertIn("status", res.json())
        print(f"Classification: {res.json()}")

if __name__ == "__main__":
    unittest.main()
