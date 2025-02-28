import mysql.connector
from mysql.connector import Error

# Database connection setup
def get_db_connection():
    try:
        # Try connecting to the database
        connection = mysql.connector.connect(
            host="localhost",
            user="root",
            password="Hiba@123",
            database="vitalsense_db"
        )
        if connection.is_connected():
            return connection
    except Error as e:
        print(f"Error: Unable to connect to the database. {e}")
        raise e  # Reraise the error after logging it

# Function to execute SELECT queries
def fetch_data(query, params=None):
    db = None
    cursor = None
    try:
        db = get_db_connection()
        cursor = db.cursor(dictionary=True)
        cursor.execute(query, params or ())
        result = cursor.fetchone()  # Fetch a single result, not all results
        return result  # Return the first (or None if not found)
    except Error as e:
        print(f"Error executing SELECT query: {e}")
        return None
    finally:
        if cursor:
            cursor.close()
        if db:
            db.close()

def fetch_all_data(query, params=None):
    db = None
    cursor = None
    try:
        db = get_db_connection()
        cursor = db.cursor(dictionary=True)
        cursor.execute(query, params or ())
        results = cursor.fetchall()  # Fetch all matching records
        return results  # Return a list of results
    except Error as e:
        print(f"Error executing SELECT query: {e}")
        return []
    finally:
        if cursor:
            cursor.close()
        if db:
            db.close()

# Function to execute INSERT, UPDATE, DELETE queries
def modify_data(query, params=None):
    db = None
    cursor = None
    try:
        db = get_db_connection()
        cursor = db.cursor()
        cursor.execute(query, params or ())
        db.commit()
    except Error as e:
        print(f"Error executing query: {e}")
        db.rollback()  # Rollback in case of an error
        raise e  # Reraise the error after logging it
    finally:
        if cursor:
            cursor.close()
        if db:
            db.close()
