from config.db import get_cursor

def get_all_clients():
    with get_cursor() as cur:
        # Unimos con p_moral y p_fisica para tener el nombre completo o razon social
        sql = """
        SELECT c.id_c, c.rfc, c.telefono, c.domicilio,
               COALESCE(pm.razon_social, pf.nombre) as nombre_cliente,
               CASE WHEN pm.id_c IS NOT NULL THEN 'Moral' ELSE 'Fisica' END as tipo
        FROM cliente c
        LEFT JOIN p_moral pm ON c.id_c = pm.id_c
        LEFT JOIN p_fisica pf ON c.id_c = pf.id_c
        ORDER BY c.id_c
        """
        cur.execute(sql)
        return cur.fetchall()

def get_client_by_id(id_c):
    with get_cursor() as cur:
        sql = """
        SELECT c.id_c, c.rfc, c.telefono, c.domicilio,
               COALESCE(pm.razon_social, pf.nombre) as nombre_cliente,
               CASE WHEN pm.id_c IS NOT NULL THEN 'Moral' ELSE 'Fisica' END as tipo
        FROM cliente c
        LEFT JOIN p_moral pm ON c.id_c = pm.id_c
        LEFT JOIN p_fisica pf ON c.id_c = pf.id_c
        WHERE c.id_c = %s
        """
        cur.execute(sql, (id_c,))
        return cur.fetchone()

def get_next_client_id():
    with get_cursor() as cur:
        cur.execute("SELECT COALESCE(MAX(id_c), 2999) + 1 as next_id FROM cliente")
        return cur.fetchone()['next_id']

def add_client(data):
    with get_cursor() as cur:
        id_c = get_next_client_id()
        
        # 1. Insertar en tabla padre
        cur.execute("""
            INSERT INTO cliente (id_c, telefono, rfc, domicilio)
            VALUES (%s, %s, %s, %s)
        """, (id_c, data['telefono'], data['rfc'], data['domicilio']))
        
        # 2. Insertar en tabla hija
        if data['tipo'] == 'Fisica':
            cur.execute("INSERT INTO p_fisica (id_c, nombre) VALUES (%s, %s)", (id_c, data['nombre']))
        else:
            cur.execute("INSERT INTO p_moral (id_c, razon_social) VALUES (%s, %s)", (id_c, data['nombre']))
            
        return id_c

def update_client(id_c, data):
    with get_cursor() as cur:
        # 1. Actualizar tabla padre
        cur.execute("""
            UPDATE cliente SET telefono=%s, rfc=%s, domicilio=%s WHERE id_c=%s
        """, (data['telefono'], data['rfc'], data['domicilio'], id_c))
        
        # 2. Actualizar tabla hija
        if data['tipo'] == 'Fisica':
            cur.execute("UPDATE p_fisica SET nombre=%s WHERE id_c=%s", (data['nombre'], id_c))
        else:
            cur.execute("UPDATE p_moral SET razon_social=%s WHERE id_c=%s", (data['nombre'], id_c))

def delete_client(id_c):
    with get_cursor() as cur:
        # Eliminar primero de las tablas hijas por FK
        cur.execute("DELETE FROM p_fisica WHERE id_c = %s", (id_c,))
        cur.execute("DELETE FROM p_moral WHERE id_c = %s", (id_c,))
        # Eliminar de tabla padre
        cur.execute("DELETE FROM cliente WHERE id_c = %s", (id_c,))
