# vitalsense/test/__init__.py
# Marks this directory as a Python package and can be used for shared test setup

import os

# Set environment to testing mode (optional)
os.environ["FLASK_ENV"] = "testing"

# Optional: if you use a separate test database
# os.environ["DATABASE_URL"] = "postgresql://localhost/test_db"

# You can define shared fixtures, mocks, or setup code here
