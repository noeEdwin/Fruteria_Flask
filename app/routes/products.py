from flask import Blueprint, render_template, request, redirect, url_for, flash
from flask_login import login_required
from app.models.product import get_all_products, add_product, update_product, delete_product, get_product_by_code, check_product_in_use, get_dashboard_stats, get_low_stock_products
import os
from flask import Blueprint, render_template, request, redirect, url_for, flash, current_app

products_bp = Blueprint('products', __name__)

@products_bp.context_processor
def utility_processor():
    def get_product_image(codigo):
        """Busca la imagen del producto con varias extensiones."""
        base_path = os.path.join(current_app.root_path, 'static', 'img', 'productos')
        extensions = ['.jpg', '.jpeg', '.png', '.webp']
        
        for ext in extensions:
            filename = f"{codigo}{ext}"
            if os.path.exists(os.path.join(base_path, filename)):
                return url_for('static', filename=f'img/productos/{filename}')
        
        # Imagen por defecto si no existe ninguna
        return None
    return dict(get_product_image=get_product_image)

@products_bp.route("/")
@products_bp.route("/home")
@login_required
def home():
    stats = get_dashboard_stats()
    low_stock_products = get_low_stock_products()
    return render_template("dashboard.html", stats=stats, low_stock_products=low_stock_products)

@products_bp.route("/productos")
@login_required
def productos():
    productos = get_all_products()
    return render_template("productos.html", productos=productos)

@products_bp.route("/producto/<int:codigo>/dashboard")
@login_required
def product_dashboard(codigo):
    product = get_product_by_code(codigo)
    if not product:
        flash("Producto no encontrado", "danger")
        return redirect(url_for("products.productos"))
    
    usage = check_product_in_use(codigo)
    return render_template("product_dashboard.html", product=product, usage=usage)

@products_bp.route("/productos/add", methods=["POST"])
@login_required
def add_producto_route():
    if request.method == "POST":
        data = {
            'descripcion': request.form["descripcion"],
            'categoria': request.form["categoria"],
            'unidad_medida': request.form["unidad_medida"],
            'existencia': request.form["existencia"],
            'precio_c': request.form["precio_c"],
            'precio_v': request.form["precio_v"]
        }
        try:
            new_code = add_product(data)
            flash(f"Producto con código # {new_code} agregado correctamente", "success")
        except Exception as e:
            flash(f"Error al agregar producto: {e}", "danger")
    return redirect(url_for("products.productos"))

@products_bp.route("/productos/edit/<int:codigo>", methods=["POST"])
@login_required
def edit_producto_route(codigo):
    if request.method == "POST":
        data = {
            'descripcion': request.form["descripcion"],
            'categoria': request.form["categoria"],
            'unidad_medida': request.form["unidad_medida"],
            'existencia': request.form["existencia"],
            'precio_c': request.form["precio_c"],
            'precio_v': request.form["precio_v"]
        }
        try:
            update_product(codigo, data)
            flash("Producto actualizado correctamente", "success")
        except Exception as e:
            flash(f"Error al actualizar producto: {e}", "danger")
    return redirect(url_for("products.productos"))

@products_bp.route("/productos/delete/<int:codigo>")
@login_required
def delete_producto_route(codigo):
    try:
        delete_product(codigo)
        flash("Producto eliminado correctamente", "success")
    except ValueError as e:
        # Error de negocio (producto en uso)
        flash(str(e), "warning")
    except Exception as e:
        # Otros errores inesperados
        flash(f"Error inesperado al eliminar producto: {e}", "danger")
    return redirect(url_for("products.productos"))
        