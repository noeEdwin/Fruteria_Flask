from config.db import get_cursor

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