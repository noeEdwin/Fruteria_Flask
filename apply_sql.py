from config.db import get_db
import os

def apply_sql():
    try:
        print("Connecting to database...")
        conn = get_db()
        cursor = conn.cursor()
        
        print("Reading SQL file...")
        with open('fruteria_functions_triggers.sql', 'r') as f:
            sql = f.read()
            
        print("Executing SQL...")
        cursor.execute(sql)
        conn.commit()
        print("SQL applied successfully!")
        
    except Exception as e:
        print(f"Error: {e}")
        if 'conn' in locals():
            conn.rollback()
    finally:
        if 'cursor' in locals():
            cursor.close()
        # Connection is managed by get_db/g, but here we are in a script
        if 'conn' in locals():
            conn.close()

if __name__ == "__main__":
    # Mocking flask g and session for get_db to work roughly or just importing the connection logic directly would be better
    # But get_db relies on flask.g. 
    # Let's bypass get_db and use psycopg2 directly with config
    from config.config import DB_CONFIG
    import psycopg2
    
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        cursor = conn.cursor()
        with open('fruteria_functions_triggers.sql', 'r') as f:
            sql = f.read()
        cursor.execute(sql)
        conn.commit()
        print("SQL applied successfully via direct connection!")
        conn.close()
    except Exception as e:
        print(f"Direct connection error: {e}")
