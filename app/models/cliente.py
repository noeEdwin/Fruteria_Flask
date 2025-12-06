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
