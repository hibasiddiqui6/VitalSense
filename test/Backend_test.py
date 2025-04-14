import unittest
import json
import os
import sys
from unittest.mock import patch, MagicMock
import flask_backend.db_utils
sys.modules['db_utils'] = flask_backend.db_utils
import flask_backend.vitals_classifier
sys.modules['vitals_classifier'] = flask_backend.vitals_classifier

from flask_backend.app import app  # Adjust if path differs

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

class FlaskAppTestCase(unittest.TestCase):
    def setUp(self):
        self.client = app.test_client()
        self.client.testing = True

    def test_ping(self):
        response = self.client.get('/ping')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.get_json(), {"status": "online"})
        
    @patch('db_utils.modify_data')
    @patch('db_utils.fetch_data')
    def test_register_patient_success(self, mock_fetch, mock_modify):
        """✅ Successful patient registration"""
        mock_fetch.side_effect = [{'userid': 1}]
        payload = {
            "fullname": "Test User",
            "email": "test@example.com",
            "password": "securepass",
            "gender": "M",
            "age": 30,
            "contact": "1234567890",
            "weight": 70
        }
        res = self.client.post('/register/patient', json=payload)
        self.assertEqual(res.status_code, 201)
        self.assertIn("Patient registered successfully", res.get_data(as_text=True))

    def test_register_patient_missing_email(self):
        """❌ Fail registration if email is missing"""
        payload = {
            "fullname": "Test User",
            "password": "securepass",
            "gender": "M",
            "age": 30,
            "contact": "1234567890",
            "weight": 70
        }
        res = self.client.post('/register/patient', json=payload)
        self.assertIn(res.status_code, [400, 500])

    @patch('db_utils.fetch_data')
    def test_login_patient_invalid_credentials(self, mock_fetch):
        mock_fetch.side_effect = [
            {'userid': 1, 'password': 'fakehash', 'role': 'patient'},
            {'patientid': 10}
        ]

        response = self.client.post('/login/patient', json={
            "email": "fake@example.com",
            "password": "wrongpass"
        })
        self.assertIn(response.status_code, [401])

    def test_classify_temp_status(self):
        response = self.client.post('/classify_temp_status', json={"temperature": 38.5})
        self.assertEqual(response.status_code, 200)
        self.assertIn("status", response.get_json())

    def test_login_patient_invalid(self):
        response = self.client.post('/login/patient', json={
            "email": "fake@example.com",
            "password": "wrongpass"
        })
        self.assertIn(response.status_code, [401, 404])

    def test_get_patient_profile_unauthorized(self):
        response = self.client.get('/get_patient_profile')
        self.assertEqual(response.status_code, 400)
        self.assertIn("error", response.get_json())
    
    def test_get_patient_profile_missing_id(self):
        """❌ Fail if patient_id is missing in profile request"""
        res = self.client.get('/get_patient_profile')
        self.assertEqual(res.status_code, 400)
        self.assertIn("Patient ID is required", res.get_data(as_text=True))
    
if __name__ == '__main__':
    unittest.main()
