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
        return self.rol in ['admin', 'administrador']

    @property
    def es_supervisor(self):
        return self.rol in ['admin', 'administrador', 'supervisor']

    @property
    def es_almacenista(self):
        return self.rol in ['admin', 'administrador', 'supervisor', 'almacenista']

    @property
    def es_vendedor(self):
        return self.rol in ['admin', 'administrador', 'supervisor', 'vendedor']

    @staticmethod
    def get(username):
        nombre = None
        id_e = None
        rol = 'vendedor'
        try:
            # Usamos una conexión privilegiada (postgres) para leer la info del usuario
            # ya que el usuario en sesión podría no tener permisos para leer la tabla empleado
            import psycopg2
            from config.config import DB_CONFIG
            
            conn = psycopg2.connect(**DB_CONFIG)
            with conn.cursor() as cur:
                cur.execute("SET search_path TO fruteria_db")
                cur.execute("SELECT id_e, nombre, rol FROM empleado WHERE username = %s", (username,))
                row = cur.fetchone()
                if row:
                    id_e = row[0]
                    nombre = row[1]
                    rol = row[2] if row[2] else 'vendedor'
            conn.close()
        except Exception as e:
            print(f"Error loading user {username}: {e}")
            pass 
        
        user = User(username, nombre, rol)
        user.id_e = id_e
        return user

