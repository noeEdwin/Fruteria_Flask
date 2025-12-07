import sys
import os
import psycopg2
import psycopg2.extras
from decimal import Decimal

# Add project root to path
sys.path.append(os.getcwd())

from config.config import DB_CONFIG

def get_db_connection():
    conn = psycopg2.connect(**DB_CONFIG)
    with conn.cursor() as cur:
        cur.execute("SET search_path TO fruteria_db")
    return conn

def get_daily_stats(conn):
    with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
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

def create_sale(conn, id_cliente, id_empleado, items):
    with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
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
            
    conn.commit()
    return folio_v

def verify_dashboard_updates():
    print("--- Verifying Dashboard Data Updates ---")
    
    try:
        conn = get_db_connection()
    except Exception as e:
        print(f"Error connecting to DB: {e}")
        return

    try:
        # 1. Get initial stats
        print("\n1. Fetching initial stats...")
        initial_stats = get_daily_stats(conn)
        print(f"Initial Sales: ${initial_stats['ventas_hoy']}")
        print(f"Initial Orders: {initial_stats['pedidos']}")
        print(f"Initial Profit: ${initial_stats['ganancia']}")
        
        # 2. Simulate a sale
        print("\n2. Simulating a new sale...")
        
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            # Find a product
            cur.execute("SELECT codigo, precio_v, precio_c FROM producto LIMIT 1")
            prod = cur.fetchone()
            if not prod:
                print("Error: No products found to sell.")
                return
                
            product_code = prod['codigo']
            price_v = prod['precio_v']
            price_c = prod['precio_c']
            
            # Find a client
            cur.execute("SELECT id_c FROM cliente LIMIT 1")
            client = cur.fetchone()
            client_id = client['id_c'] if client else 1 
            
            # Find an employee
            cur.execute("SELECT id_e FROM empleado LIMIT 1")
            emp = cur.fetchone()
            emp_id = emp['id_e'] if emp else 1 

        qty = 2
        sale_amount = price_v * qty
        expected_profit = (price_v - price_c) * qty
        
        items = [{'codigo': product_code, 'cantidad': qty}]
        
        folio = create_sale(conn, client_id, emp_id, items)
        print(f"Sale created! Folio: {folio}")
        print(f"Sale Amount: ${sale_amount}")
        print(f"Expected Profit Increase: ${expected_profit}")

        # 3. Get updated stats
        print("\n3. Fetching updated stats...")
        updated_stats = get_daily_stats(conn)
        print(f"Updated Sales: ${updated_stats['ventas_hoy']}")
        print(f"Updated Orders: {updated_stats['pedidos']}")
        print(f"Updated Profit: ${updated_stats['ganancia']}")
        
        # 4. Verify increases
        print("\n4. Verifying changes...")
        
        sales_diff = updated_stats['ventas_hoy'] - initial_stats['ventas_hoy']
        orders_diff = updated_stats['pedidos'] - initial_stats['pedidos']
        profit_diff = updated_stats['ganancia'] - initial_stats['ganancia']
        
        print(f"Sales Difference: ${sales_diff} (Expected: ${sale_amount})")
        print(f"Orders Difference: {orders_diff} (Expected: 1)")
        print(f"Profit Difference: ${profit_diff} (Expected: ${expected_profit})")
        
        if sales_diff == sale_amount and orders_diff == 1 and profit_diff == expected_profit:
            print("\n✅ SUCCESS: Dashboard stats updated correctly!")
        else:
            print("\n❌ FAILURE: Stats did not update as expected.")
            
    finally:
        conn.close()

if __name__ == "__main__":
    verify_dashboard_updates()
