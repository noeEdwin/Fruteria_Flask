from config.db import get_cursor, get_db
import psycopg2

sql = """
INSERT INTO producto (codigo, descripcion, categoria, unidad_medida, existencia, precio_c, precio_v) VALUES 
(5000, 'manzana roja','fruta','kilogramo', 15, 40.50, 65),
(5001, 'manzana verde','fruta','kilogramo', 8, 50, 60),
(5002, 'manzana amarilla','fruta','kilogramo', 10, 35, 50),
(5003, 'pera roja','fruta','kilogramo', 7, 50, 65),
(5004, 'pera de anjou','fruta','kilogramo', 5, 45, 56),
(5005, 'papaya','fruta','kilogramo', 20, 25, 30),
(5006, 'melón','fruta','pieza', 18, 25, 40),
(5007, 'naranja','fruta','kilogramo', 30, 20, 35),
(5008, 'plátano tabasco','fruta','kilogramo', 20, 20, 28),
(5009, 'platano macho','fruta','kilogramo', 30, 18, 28),
(5010, 'piña','fruta','pieza', 13, 32, 45),
(5011, 'calabacita italiana','verdura','kilogramo', 12, 10, 20),
(5012, 'chile serrano','verdura','kilogramo', 5, 15, 20),
(5013, 'chile jalapeño','verdura','kilogramo', 3, 22, 34),
(5014, 'papa','verdura','kilogramo', 20, 19, 27),
(5015, 'espinaca','verdura','ramito', 12, 4, 8),
(5016, 'lechuga romanita','verdura','pieza', 15, 5, 12),
(5017, 'ejote','verdura','kilogramo', 3, 17, 23),
(5018, 'jicama','fruta','kilogramo', 20, 28, 35),
(5019, 'sandia','fruta','kilogramo', 18, 10, 18),
(5020, 'chile poblano','verdura','kilogramo', 5, 35, 50),
(5022, 'limon','fruta','kilogramo', 10, 18, 22),
(5023, 'cebolla','verdura','kilogramo', 5, 18, 23),
(5024, 'tomate rojo','verdura','kilogramo', 30, 15, 23)
ON CONFLICT (codigo) DO NOTHING;
"""

try:
    with get_cursor() as cur:
        cur.execute(sql)
        print("Productos insertados correctamente.")
except Exception as e:
    print(f"Error al insertar productos: {e}")
