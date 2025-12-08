from config.db import get_cursor

class Empleado:
    def __init__(self, id_e, nombre, turno, salario, username, rol, last_login=None, is_active=True):
        self.id_e = id_e
        self.nombre = nombre
        self.turno = turno
        self.salario = salario
        self.username = username
        self.rol = rol
        self.last_login = last_login
        self.is_active = is_active

    @staticmethod
    def get_all():
        with get_cursor() as cur:
            cur.execute("""
                SELECT id_e, nombre, turno, salario, username, rol, last_login, is_active 
                FROM empleado 
                ORDER BY id_e
            """)
            rows = cur.fetchall()
            return [Empleado(**row) for row in rows]

    @staticmethod
    def get_by_id(id_e):
        with get_cursor() as cur:
            cur.execute("""
                SELECT id_e, nombre, turno, salario, username, rol, last_login, is_active 
                FROM empleado 
                WHERE id_e = %s
            """, (id_e,))
            row = cur.fetchone()
            if row:
                return Empleado(**row)
            return None

    @staticmethod
    def create(data):
        with get_cursor() as cur:
            # 1. Crear usuario en Postgres
            # Necesitamos permisos de superuser (postgres)
            cur.execute("RESET ROLE")
            
            username = data['username']
            password = data['password']
            rol = data['rol']


            # Crear usuario con contraseña
            cur.execute(f'CREATE USER "{username}" WITH PASSWORD \'{password}\'')
            
            # Asignar rol (grupo)
            cur.execute(f'GRANT "{rol}" TO "{username}"')
            
            # 2. Insertar en la tabla empleado
            cur.execute("""
                INSERT INTO empleado (id_e, nombre, turno, salario, username, rol, is_active)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
            """, (
                data['id_e'],
                data['nombre'],
                data['turno'],
                data['salario'],
                data['username'],
                data['rol'],
                True
            ))

    @staticmethod
    def update(id_e, data):
        with get_cursor() as cur:
            # 1. Obtener datos actuales para comparar
            cur.execute("SELECT username, rol FROM empleado WHERE id_e = %s", (id_e,))
            current = cur.fetchone()
            
            if not current:
                raise ValueError("Empleado no encontrado")

            old_username = current['username']
            old_rol = current['rol']
            new_username = data['username']
            new_rol = data['rol']

            # 2. Si hay cambios en username o rol, necesitamos permisos de superuser
            if old_username != new_username or old_rol != new_rol:
                # Volver al rol postgres original para ejecutar comandos DCL
                cur.execute("RESET ROLE")

                # 3. Actualizar Username si cambió
                if old_username != new_username:
                    # RENAME ROLE
                    cur.execute(f'ALTER ROLE "{old_username}" RENAME TO "{new_username}"')

                # 4. Actualizar Rol si cambió
                if old_rol != new_rol:
                    # REVOKE viejo, GRANT nuevo
                    # Usamos el username (posiblemente nuevo)
                    target_user = new_username
                    cur.execute(f'REVOKE "{old_rol}" FROM "{target_user}"')
                    cur.execute(f'GRANT "{new_rol}" TO "{target_user}"')

            # 5. Actualizar la tabla
            cur.execute("""
                UPDATE empleado 
                SET nombre = %s, turno = %s, salario = %s, username = %s, rol = %s
                WHERE id_e = %s
            """, (
                data['nombre'],
                data['turno'],
                data['salario'],
                data['username'],
                data['rol'],
                id_e
            ))

    @staticmethod
    def delete(id_e):
        with get_cursor() as cur:
            # 1. Obtener username para borrar el rol de postgres
            cur.execute("SELECT username FROM empleado WHERE id_e = %s", (id_e,))
            row = cur.fetchone()
            
            if row:
                username = row['username']
                
                # 2. Borrar usuario de Postgres
                # Necesitamos permisos de superuser
                cur.execute("RESET ROLE")
                
                # DROP ROLE IF EXISTS (mas seguro)
                cur.execute(f'DROP ROLE IF EXISTS "{username}"')

            # 3. Borrar de la tabla
            cur.execute("DELETE FROM empleado WHERE id_e = %s", (id_e,))
