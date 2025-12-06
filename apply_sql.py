import sys
import os
from app import create_app
from config.db import get_cursor

def apply_sql_file(filename):
    if not os.path.exists(filename):
        print(f"Error: File '{filename}' not found.")
        return

    print(f"Applying SQL from {filename}...")
    
    app = create_app()
    with app.app_context():
        with app.test_request_context():
            try:
                with open(filename, 'r') as f:
                    sql_content = f.read()
                    
                with get_cursor() as cur:
                    cur.execute(sql_content)
                    print("SQL script executed successfully.")
                    
            except Exception as e:
                print(f"Error executing SQL: {e}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python apply_sql.py <sql_file>")
    else:
        apply_sql_file(sys.argv[1])
