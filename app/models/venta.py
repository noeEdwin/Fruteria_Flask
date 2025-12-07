from config.db import get_cursor

def create_sale(id_cliente, id_empleado, items):
    """
    Crea una venta y sus detalles en una transacción.
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
    Consulta de 3 tablas reunidas.
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

def get_weekly_sales():
    """
    Obtiene las ventas de los últimos 7 días.
    Retorna una lista de diccionarios con 'fecha' y 'total'.
    """
    with get_cursor() as cur:
        # Generar serie de últimos 7 días para asegurar que aparezcan días con 0 ventas
        sql = """
        WITH last_7_days AS (
            SELECT generate_series(
                CURRENT_DATE - INTERVAL '6 days',
                CURRENT_DATE,
                '1 day'::interval
            )::date AS fecha
        )
        SELECT 
            TO_CHAR(d.fecha, 'Dy') as dia_nombre,
            d.fecha,
            COALESCE(SUM(p.precio_v * dv.cantidad), 0) as total
        FROM last_7_days d
        LEFT JOIN venta v ON v.fecha = d.fecha
        LEFT JOIN detalle_venta dv ON v.folio_v = dv.folio_v
        LEFT JOIN producto p ON dv.codigo = p.codigo
        GROUP BY d.fecha
        ORDER BY d.fecha
        """
        cur.execute(sql)
        return cur.fetchall()

def get_daily_stats():
    """
    Obtiene estadísticas de ventas del día actual:
    - Total vendido
    - Número de pedidos (ventas)
    - Ganancia estimada (Venta - Costo)
    """
    with get_cursor() as cur:
        sql = """
        SELECT 
            COUNT(DISTINCT v.folio_v) as pedidos,
            COALESCE(SUM(p.precio_v * dv.cantidad), 0) as ventas_hoy,
            COALESCE(SUM((p.precio_v - p.precio_c) * dv.cantidad), 0) as ganancia
        FROM venta v
        JOIN detalle_venta dv ON v.folio_v = dv.folio_v
        JOIN producto p ON dv.codigo = p.codigo
        WHERE v.fecha = CURRENT_DATE
        """
        cur.execute(sql)
        return cur.fetchone()
