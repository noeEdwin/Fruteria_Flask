from config.db import get_cursor

def get_all_providers():
    with get_cursor() as cur:
        cur.execute("SELECT * FROM proveedor ORDER BY id_p")
        return cur.fetchall()

def get_provider_by_id(id_p):
    with get_cursor() as cur:
        cur.execute("SELECT * FROM proveedor WHERE id_p = %s", (id_p,))
        return cur.fetchone()

def get_next_provider_id():
    with get_cursor() as cur:
        cur.execute("SELECT COALESCE(MAX(id_p), 1999) + 1 as next_id FROM proveedor")
        return cur.fetchone()['next_id']

def add_provider(data):
    with get_cursor() as cur:
        id_p = get_next_provider_id()
        cur.execute("""
            INSERT INTO proveedor (id_p, nombre, ciudad, contacto, tel_contacto)
            VALUES (%s, %s, %s, %s, %s)
        """, (id_p, data['nombre'], data['ciudad'], data['contacto'], data['tel_contacto']))
        return id_p

def update_provider(id_p, data):
    with get_cursor() as cur:
        cur.execute("""
            UPDATE proveedor 
            SET nombre=%s, ciudad=%s, contacto=%s, tel_contacto=%s 
            WHERE id_p=%s
        """, (data['nombre'], data['ciudad'], data['contacto'], data['tel_contacto'], id_p))

def delete_provider(id_p):
    """
    Elimina un proveedor solo si no está en uso.
    Lanza una excepción personalizada si está en uso.
    """
    usage = check_provider_in_use(id_p)
    if usage['in_use']:
        reasons = []
        if usage['compras'] > 0:
            reasons.append(f"{usage['compras']} compra(s)")
        if usage['productos'] > 0:
            reasons.append(f"{usage['productos']} producto(s) asociado(s)")
        
        message = f"No se puede eliminar el proveedor porque está asociado a: {', '.join(reasons)}"
        raise ValueError(message)

    with get_cursor() as cur:
        cur.execute("DELETE FROM proveedor WHERE id_p = %s", (id_p,))

def check_provider_in_use(id_p):
    """
    Verifica si un proveedor está siendo usado en compras o tiene productos asociados.
    """
    with get_cursor() as cur:
        # Verificar en compra
        cur.execute("SELECT COUNT(*) as count FROM compra WHERE id_p = %s", (id_p,))
        compras_count = cur.fetchone()['count']
        
        # Verificar en producto_proveedor
        cur.execute("SELECT COUNT(*) as count FROM producto_proveedor WHERE id_p = %s", (id_p,))
        productos_count = cur.fetchone()['count']
        
        is_in_use = (compras_count > 0) or (productos_count > 0)
        
        details = {
            'in_use': is_in_use,
            'compras': compras_count,
            'productos': productos_count
        }
        
        return details
