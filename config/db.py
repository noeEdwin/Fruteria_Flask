# psycopg2 librerias para conectar a la base de datos, python con postgresql
import psycopg2
import psycopg2.extras
# Usamos g para abrir una sola conexión por visita del usuario, hacer todo lo que se tenga que hacer, y cerrarla al final.
# Usamos session para guardar la conexión en la sesión del usuario.
from flask import g, session
from config.config import DB_CONFIG
import re
from contextlib import contextmanager

def get_db(user=None, password=None):
    # Basicamente busca si no hay una conexión abierta, si no la hay, la abre.
    if "db" not in g:
        # Primer login, mandamos las credenciales del usuario e intenta conectar a la base de datos
        if user and password:
            config = DB_CONFIG.copy()
            config["user"] = user
            config["password"] = password
            g.db = psycopg2.connect(**config)
        
        # Escenario 2: Usuario Autenticado 
        # Ya no usamos la contraseña de la sesión, conectamos como postgres (DB_CONFIG)
        # y luego asumimos el rol del usuario.
        else:
            g.db = psycopg2.connect(**DB_CONFIG)
            
            # Si hay un usuario en sesión, cambiamos el rol a ese usuario
            if "db_user" in session:
                target_user = session["db_user"]
                
                # Validación estricta: Solo letras, números y guion bajo para evitar SQL Injection
                if not re.match(r'^[a-zA-Z0-9_]+$', target_user):
                    raise ValueError("FATAL: Intento de inyección de SQL o usuario inválido detectado.")

                with g.db.cursor() as cur:
                    cur.execute(f'SET ROLE "{target_user}"')

        # Configurar el esquema
        with g.db.cursor() as cur:
            cur.execute("SET search_path TO fruteria_db")
    return g.db

# Cierra la conexión a la base de datos
def close_db(e=None):
    db = g.pop("db", None)
    if db is not None:
        db.close()

# Función que maneja la conexión a la base de datos
# Si todo salio bien, hace un commit, si no, hace un rollback 
@contextmanager
def get_cursor(dict_cursor=True):
    conn = get_db()
    cursor = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) if dict_cursor else conn.cursor()
    try:
        yield cursor
        conn.commit()  
    except Exception:
        conn.rollback()
        raise
    finally:
        cursor.close()