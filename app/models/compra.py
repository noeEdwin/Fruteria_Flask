from config.db import get_cursor

def create_purchase(id_proveedor, id_empleado, no_lote, items):
    """
    Crea una compra y sus detalles en una transacción.
    """
    with get_cursor() as cur:
        # 1. Generar Folio (Max + 1)
        cur.execute("SELECT COALESCE(MAX(folio_c), 0) + 1 as next_folio FROM compra")
        folio_c = cur.fetchone()['next_folio']
        
        # 2. Insertar Compra
        cur.execute("""
            INSERT INTO compra (folio_c, no_lote, fecha, id_p, id_e)
            VALUES (%s, %s, CURRENT_DATE, %s, %s)
        """, (folio_c, no_lote, id_proveedor, id_empleado))
        
        # 3. Insertar Detalles
        for item in items:
            cur.execute("""
                INSERT INTO detalle_compra (folio_c, codigo, cantidad)
                VALUES (%s, %s, %s)
            """, (folio_c, item['codigo'], item['cantidad']))
                        
        return folio_c

def get_purchases_report():
    """
    Obtiene reporte de compras uniendo Compra, Proveedor y Empleado.
    """
    with get_cursor() as cur:
        sql = """
        SELECT c.folio_c, c.fecha, c.no_lote,
               p.nombre as proveedor,
               get_empleado_nombre(c.id_e) as empleado
        FROM compra c
        JOIN proveedor p ON c.id_p = p.id_p
        ORDER BY c.folio_c DESC
        """
        cur.execute(sql)
        return cur.fetchall()

def get_purchase_details(folio_c):
    """
    Obtiene los detalles de una compra específica.
    """
    with get_cursor() as cur:
        # Obtener info de la compra
        cur.execute("""
            SELECT c.folio_c, c.fecha, c.no_lote,
                   p.nombre as proveedor,
                   e.nombre as empleado
            FROM compra c
            JOIN proveedor p ON c.id_p = p.id_p
            JOIN empleado e ON c.id_e = e.id_e
            WHERE c.folio_c = %s
        """, (folio_c,))
        compra = cur.fetchone()
        
        if not compra:
            return None
            
        # Obtener detalles
        cur.execute("""
            SELECT dc.codigo, dc.cantidad, pr.descripcion, pr.unidad_medida
            FROM detalle_compra dc
            JOIN producto pr ON dc.codigo = pr.codigo
            WHERE dc.folio_c = %s
        """, (folio_c,))
        detalles = cur.fetchall()
        
        return {
            'compra': compra,
            'detalles': detalles
        }
