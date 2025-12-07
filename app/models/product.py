from config.db import get_cursor


def get_product_by_code(codigo):
    with get_cursor() as cur:
        cur.execute("SELECT * FROM producto WHERE codigo = %s", (codigo,))
        return cur.fetchone()

def get_all_products():
    with get_cursor() as cur:
        cur.execute("SELECT * FROM producto ORDER BY codigo")
        return cur.fetchall()

def add_product(data):
    with get_cursor() as cur:
        next_code = get_next_product_code()
        max_retries = 5
        for attempt in range(max_retries):
            try:
                cur.execute(
                    """INSERT INTO producto (codigo, descripcion, categoria, unidad_medida, existencia, precio_c, precio_v)
                       VALUES (%s, %s, %s, %s, %s, %s, %s)""",
                    (next_code, data['descripcion'], data['categoria'], data['unidad_medida'], 
                     data['existencia'], data['precio_c'], data['precio_v']),
                )
                return next_code  
            except psycopg2.errors.UniqueViolation:
                next_code += 1
                if attempt == max_retries - 1:
                    raise Exception("No se pudo generar un código único después de varios intentos")

def update_product(codigo, data):
    with get_cursor() as cur:
        cur.execute(
            """UPDATE producto 
               SET descripcion=%s, categoria=%s, unidad_medida=%s, existencia=%s, precio_c=%s, precio_v=%s
               WHERE codigo=%s""",
            (data['descripcion'], data['categoria'], data['unidad_medida'], 
             data['existencia'], data['precio_c'], data['precio_v'], codigo),
        )

def delete_product(codigo):
    """
    Elimina un producto solo si no está en uso.
    Lanza una excepción personalizada si está en uso.
    """
    usage = check_product_in_use(codigo)
    if usage['in_use']:
        reasons = []
        if usage['ventas'] > 0:
            reasons.append(f"{usage['ventas']} venta(s)")
        if usage['compras'] > 0:
            reasons.append(f"{usage['compras']} compra(s)")
        if usage['proveedores'] > 0:
            reasons.append(f"{usage['proveedores']} proveedor(es)")
        
        message = f"No se puede eliminar el producto porque está asociado a: {', '.join(reasons)}"
        raise ValueError(message)
    
    # Si no está en uso, proceder con la eliminación
    with get_cursor() as cur:
        cur.execute("DELETE FROM producto WHERE codigo = %s", (codigo,))


def get_next_product_code():
     with get_cursor() as cur:
        cur.execute("SELECT MAX(codigo) as max_codigo FROM producto")
        result = cur.fetchone()
        if result['max_codigo'] is None:
            return 1000
        else:
            return result['max_codigo'] + 1
    
def check_product_in_use(codigo):
    """
    Verifica si un producto está siendo usado en ventas, compras o relaciones con proveedores.
    """
    with get_cursor() as cur:
        # Verificar en detalle_venta
        cur.execute("SELECT COUNT(*) as count FROM detalle_venta WHERE codigo = %s", (codigo,))
        ventas_count = cur.fetchone()['count']
        
        # Verificar en detalle_compra
        cur.execute("SELECT COUNT(*) as count FROM detalle_compra WHERE codigo = %s", (codigo,))
        compras_count = cur.fetchone()['count']
        
        # Verificar en producto_proveedor
        cur.execute("SELECT COUNT(*) as count FROM producto_proveedor WHERE codigo = %s", (codigo,))
        proveedores_count = cur.fetchone()['count']
        
        is_in_use = (ventas_count > 0) or (compras_count > 0) or (proveedores_count > 0)
        
        details = {
            'in_use': is_in_use,
            'ventas': ventas_count,
            'compras': compras_count,
            'proveedores': proveedores_count
        }
        
        return details

def get_dashboard_stats():
    with get_cursor() as cur:
        cur.execute("SELECT COUNT(*) as total FROM producto")
        total_products = cur.fetchone()['total']
        
        cur.execute("SELECT COUNT(*) as count FROM producto WHERE existencia < 10")
        low_stock_count = cur.fetchone()['count']
        
        cur.execute("SELECT SUM(existencia * precio_c) as total_value FROM producto")
        result = cur.fetchone()
        total_value = result['total_value'] if result['total_value'] else 0
        
        return {
            'total_products': total_products,
            'low_stock_count': low_stock_count,
            'total_value': total_value
        }

def get_low_stock_products(limit=5):
    with get_cursor() as cur:
        cur.execute("SELECT * FROM producto WHERE existencia < 10 ORDER BY existencia ASC LIMIT %s", (limit,))
        return cur.fetchall()

def get_top_categories(limit=5):
    """
    Obtiene las categorías más vendidas basándose en la cantidad de productos vendidos.
    """
    with get_cursor() as cur:
        sql = """
        SELECT p.categoria, SUM(dv.cantidad) as total_vendido
        FROM detalle_venta dv
        JOIN producto p ON dv.codigo = p.codigo
        GROUP BY p.categoria
        ORDER BY total_vendido DESC
        LIMIT %s
        """
        cur.execute(sql, (limit,))
        return cur.fetchall()