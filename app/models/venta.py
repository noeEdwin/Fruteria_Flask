from config.db import get_cursor

def create_sale(id_cliente, id_empleado, items):
    """
    Crea una venta y sus detalles en una transacción.
    items: lista de diccionarios [{'codigo': 123, 'cantidad': 2}]
    """
    with get_cursor() as cur:
        # 1. Generar Folio (Max + 1)
        cur.execute("SELECT COALESCE(MAX(folio_v), 0) + 1 as next_folio FROM venta")
        folio_v = cur.fetchone()['next_folio']
        
        # 2. Insertar Venta
        cur.execute("""
            INSERT INTO venta (folio_v, fecha, id_c, id_e)
            VALUES (%s, CURRENT_DATE, %s, %s)
        """, (folio_v, id_cliente, id_empleado))
        
        # 3. Insertar Detalles
        for item in items:
            cur.execute("""
                INSERT INTO detalle_venta (codigo, folio_v, observaciones, cantidad)
                VALUES (%s, %s, '', %s)
            """, (item['codigo'], folio_v, item['cantidad']))
            
        return folio_v

def get_sales_report():
    """
    Obtiene reporte de ventas uniendo Venta, Cliente y Empleado.
    Cumple con el requisito de 'Consulta de 3 tablas reunidas'.
    """
    with get_cursor() as cur:
        sql = """
        SELECT v.folio_v, v.fecha, 
               COALESCE(pm.razon_social, pf.nombre) as cliente,
               e.nombre as empleado,
               fn_calcular_total_venta(v.folio_v) as total
        FROM venta v
        JOIN cliente c ON v.id_c = c.id_c
        LEFT JOIN p_moral pm ON c.id_c = pm.id_c
        LEFT JOIN p_fisica pf ON c.id_c = pf.id_c
        JOIN empleado e ON v.id_e = e.id_e
        ORDER BY v.folio_v DESC
        """
        cur.execute(sql)
        return cur.fetchall()
