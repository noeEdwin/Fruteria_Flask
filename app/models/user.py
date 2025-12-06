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
        id_e = None
        try:
            with get_cursor() as cur:
                cur.execute("SELECT id_e, nombre FROM empleado WHERE username = %s", (username,))
                row = cur.fetchone()
                if row:
                    nombre = row['nombre']
                    id_e = row['id_e']
        except Exception:
            pass 
        user = User(username, nombre)
        user.id_e = id_e
        return user
