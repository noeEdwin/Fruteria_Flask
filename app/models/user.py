from flask_login import UserMixin
from config.db import get_cursor

class User(UserMixin):
    def __init__(self, username, nombre_completo=None, rol='vendedor'):
        self.id = username 
        self.username = username
        self.nombre_completo = nombre_completo or username
        self.rol = rol
        self.id_e = None

    @property
    def es_admin(self):
        return self.rol == 'admin'

    @property
    def es_supervisor(self):
        return self.rol in ['admin', 'supervisor']

    @property
    def es_almacenista(self):
        return self.rol in ['admin', 'supervisor', 'almacenista']

    @property
    def es_vendedor(self):
        return self.rol in ['admin', 'supervisor', 'vendedor']

    @staticmethod
    def get(username):
        nombre = None
        id_e = None
        rol = 'vendedor'
        try:
            with get_cursor() as cur:
                cur.execute("SELECT id_e, nombre, rol FROM empleado WHERE username = %s", (username,))
                row = cur.fetchone()
                if row:
                    nombre = row['nombre']
                    id_e = row['id_e']
                    rol = row.get('rol', 'vendedor')
        except Exception:
            pass 
        
        user = User(username, nombre, rol)
        user.id_e = id_e
        return user

