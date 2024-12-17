import mysql.connector

# Database connection setup
def get_db_connection():
    return mysql.connector.connect(
        host="localhost",
        user="root",
        password="Hiba@123",
        database="vitalsense_db"
    )

# Function to execute SELECT queries
def fetch_data(query, params=None):
    db = get_db_connection()
    cursor = db.cursor(dictionary=True)
    cursor.execute(query, params or ())
    result = cursor.fetchone()  # Fetch a single result, not all results
    cursor.close()
    db.close()
    return result  # Return the first (or None if not found)

# Function to execute INSERT, UPDATE, DELETE queries
def modify_data(query, params=None):
    db = get_db_connection()
    cursor = db.cursor()
    cursor.execute(query, params or ())
    db.commit()
    cursor.close()
    db.close()
