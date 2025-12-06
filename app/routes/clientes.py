from flask import Blueprint, render_template, request, redirect, url_for, flash, jsonify
from flask_login import login_required
from app.models.cliente import get_all_clients, add_client, update_client, delete_client, get_client_by_id

clientes_bp = Blueprint('clientes', __name__)

@clientes_bp.route("/clientes")
@login_required
def index():
    clientes = get_all_clients()
    return render_template("clientes.html", clientes=clientes)

@clientes_bp.route("/clientes/add", methods=["POST"])
@login_required
def add():
    try:
        data = {
            'nombre': request.form['nombre'],
            'rfc': request.form['rfc'],
            'telefono': request.form['telefono'],
            'domicilio': request.form['domicilio'],
            'tipo': request.form['tipo']
        }
        add_client(data)
        flash("Cliente registrado correctamente", "success")
    except Exception as e:
        flash(f"Error al registrar cliente: {e}", "danger")
    return redirect(url_for('clientes.index'))

@clientes_bp.route("/clientes/edit/<int:id_c>", methods=["POST"])
@login_required
def edit(id_c):
    try:
        data = {
            'nombre': request.form['nombre'],
            'rfc': request.form['rfc'],
            'telefono': request.form['telefono'],
            'domicilio': request.form['domicilio'],
            'tipo': request.form['tipo'] # Necesario para saber qué tabla actualizar
        }
        update_client(id_c, data)
        flash("Cliente actualizado correctamente", "success")
    except Exception as e:
        flash(f"Error al actualizar cliente: {e}", "danger")
    return redirect(url_for('clientes.index'))

@clientes_bp.route("/clientes/delete/<int:id_c>")
@login_required
def delete(id_c):
    try:
        delete_client(id_c)
        flash("Cliente eliminado correctamente", "success")
    except Exception as e:
        flash(f"Error al eliminar cliente (posiblemente tiene ventas asociadas): {e}", "danger")
    return redirect(url_for('clientes.index'))

@clientes_bp.route("/clientes/get/<int:id_c>")
@login_required
def get_json(id_c):
    client = get_client_by_id(id_c)
    if client:
        return jsonify(client)
    return jsonify({'error': 'Cliente no encontrado'}), 404
