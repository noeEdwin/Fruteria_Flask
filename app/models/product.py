from config.db import get_cursor

def get_all_products():
    with get_cursor() as cur:
        cur.execute("SELECT * FROM producto ORDER BY codigo")
        return cur.fetchall()

def add_product(data):
    with get_cursor() as cur:
        cur.execute(
            """INSERT INTO producto (codigo, descripcion, categoria, unidad_medida, existencia, precio_c, precio_v)
               VALUES (%s, %s, %s, %s, %s, %s, %s)""",
            (data['codigo'], data['descripcion'], data['categoria'], data['unidad_medida'], 
             data['existencia'], data['precio_c'], data['precio_v']),
        )

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
    with get_cursor() as cur:
        cur.execute("DELETE FROM producto WHERE codigo = %s", (codigo,))
