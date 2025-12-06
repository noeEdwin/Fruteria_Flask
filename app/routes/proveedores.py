from flask import Blueprint, render_template, request, redirect, url_for, flash, jsonify
from flask_login import login_required
from app.models.proveedor import get_all_providers, add_provider, update_provider, delete_provider, get_provider_by_id

proveedores_bp = Blueprint('proveedores', __name__)

@proveedores_bp.route("/proveedores")
@login_required
def index():
    proveedores = get_all_providers()
    return render_template("proveedores.html", proveedores=proveedores)

@proveedores_bp.route("/proveedores/add", methods=["POST"])
@login_required
def add():
    try:
        data = {
            'nombre': request.form['nombre'],
            'ciudad': request.form['ciudad'],
            'contacto': request.form['contacto'],
            'tel_contacto': request.form['tel_contacto']
        }
        add_provider(data)
        flash("Proveedor registrado correctamente", "success")
    except Exception as e:
        flash(f"Error al registrar proveedor: {e}", "danger")
    return redirect(url_for('proveedores.index'))

@proveedores_bp.route("/proveedores/edit/<int:id_p>", methods=["POST"])
@login_required
def edit(id_p):
    try:
        data = {
            'nombre': request.form['nombre'],
            'ciudad': request.form['ciudad'],
            'contacto': request.form['contacto'],
            'tel_contacto': request.form['tel_contacto']
        }
        update_provider(id_p, data)
        flash("Proveedor actualizado correctamente", "success")
    except Exception as e:
        flash(f"Error al actualizar proveedor: {e}", "danger")
    return redirect(url_for('proveedores.index'))

@proveedores_bp.route("/proveedores/delete/<int:id_p>")
@login_required
def delete(id_p):
    try:
        delete_provider(id_p)
        flash("Proveedor eliminado correctamente", "success")
    except ValueError as e:
        flash(str(e), "warning")
    except Exception as e:
        flash(f"Error al eliminar proveedor: {e}", "danger")
    return redirect(url_for('proveedores.index'))

@proveedores_bp.route("/proveedores/get/<int:id_p>")
@login_required
def get_json(id_p):
    provider = get_provider_by_id(id_p)
    if provider:
        return jsonify(provider)
    return jsonify({'error': 'Proveedor no encontrado'}), 404
