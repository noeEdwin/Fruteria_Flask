from flask import Blueprint, render_template, request, jsonify
from flask_login import login_required, current_user
from app.models.cliente import get_all_clients
from app.models.product import get_all_products
from app.models.venta import create_sale, get_sales_report

ventas_bp = Blueprint('ventas', __name__)

@ventas_bp.route("/ventas/nueva")
@login_required
def nueva_venta():
    clientes = get_all_clients()
    productos = get_all_products()
    return render_template("ventas/nueva_venta.html", clientes=clientes, productos=productos)

@ventas_bp.route("/ventas/crear", methods=["POST"])
@login_required
def crear_venta():
    data = request.get_json()
    id_cliente = data.get('id_cliente')
    items = data.get('items') 
    
    if not id_cliente or not items:
        return jsonify({'success': False, 'message': 'Datos incompletos'}), 400
        
    try:
        
        if not hasattr(current_user, 'id_e') or not current_user.id_e:
             return jsonify({'success': False, 'message': 'Error de sesión: Usuario no identificado'}), 403

        folio = create_sale(id_cliente, current_user.id_e, items)
        return jsonify({'success': True, 'message': f'Venta registrada con éxito. Folio: {folio}', 'folio': folio})
    except Exception as e:
        
        return jsonify({'success': False, 'message': str(e)}), 500

@ventas_bp.route("/ventas/reporte")
@login_required
def reporte_ventas():
    ventas = get_sales_report()
    return render_template("ventas/reporte_ventas.html", ventas=ventas)
