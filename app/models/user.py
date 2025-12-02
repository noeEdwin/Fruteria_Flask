from flask_login import UserMixin
from config.db import get_cursor

class User(UserMixin):
    def __init__(self, username, nombre_completo=None):
        self.id = username 
        self.username = username
        self.nombre_completo = nombre_completo or username

    @staticmethod
    def get(username):
        nombre = None
        try:
            with get_cursor() as cur:
                cur.execute("SELECT nombre FROM empleado WHERE username = %s", (username,))
                row = cur.fetchone()
                if row:
                    nombre = row['nombre']
        except Exception:
            pass 
        return User(username, nombre)
