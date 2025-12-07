from flask import Blueprint, render_template, request, jsonify
from flask_login import login_required, current_user
from app.models.proveedor import get_all_providers
from app.models.product import get_all_products
from app.models.compra import create_purchase, get_purchases_report, get_purchase_details

compras_bp = Blueprint('compras', __name__)

@compras_bp.route("/compras/nueva")
@login_required
def nueva_compra():
    proveedores = get_all_providers()
    productos = get_all_products()
    return render_template("compras/nueva_compra.html", proveedores=proveedores, productos=productos)

@compras_bp.route("/compras/crear", methods=["POST"])
@login_required
def crear_compra():
    data = request.get_json()
    id_proveedor = data.get('id_proveedor')
    no_lote = data.get('no_lote')
    items = data.get('items') 
    
    if not id_proveedor or not items or not no_lote:
        return jsonify({'success': False, 'message': 'Datos incompletos'}), 400
        
    try:
        if not hasattr(current_user, 'id_e') or not current_user.id_e:
             return jsonify({'success': False, 'message': 'Error de sesión: Usuario no identificado'}), 403

        folio = create_purchase(id_proveedor, current_user.id_e, no_lote, items)
        return jsonify({'success': True, 'message': f'Compra registrada con éxito. Folio: {folio}', 'folio': folio})
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500

@compras_bp.route("/compras/reporte")
@login_required
def reporte_compras():
    compras = get_purchases_report()
    return render_template("compras/reporte_compras.html", compras=compras)

@compras_bp.route("/compras/detalle/<int:folio_c>")
@login_required
def detalle_compra(folio_c):
    data = get_purchase_details(folio_c)
    if not data:
        return "Compra no encontrada", 404
    return render_template("compras/detalle_compra.html", compra=data['compra'], detalles=data['detalles'])
