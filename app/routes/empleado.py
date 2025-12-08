from flask import Blueprint, render_template, request, redirect, url_for, flash
from flask_login import login_required, current_user
from app.models.empleado import Empleado

empleado_bp = Blueprint('empleado', __name__)

@empleado_bp.route('/empleados')
@login_required
def list_empleados():
    empleados = Empleado.get_all()
    return render_template('empleados.html', empleados=empleados)

@empleado_bp.route('/empleados/add', methods=['POST'])
@login_required
def add_empleado():
    try:
        data = {
            'id_e': request.form['id_e'],
            'nombre': request.form['nombre'],
            'turno': request.form['turno'],
            'salario': request.form['salario'],
            'username': request.form['username'],
            'password': request.form['password'],
            'rol': request.form['rol']
        }
        Empleado.create(data)
        flash('Empleado agregado exitosamente', 'success')
    except Exception as e:
        flash(f'Error al agregar empleado: {str(e)}', 'danger')
    return redirect(url_for('empleado.list_empleados'))

@empleado_bp.route('/empleados/update/<int:id_e>', methods=['POST'])
@login_required
def update_empleado(id_e):
    try:
        data = {
            'nombre': request.form['nombre'],
            'turno': request.form['turno'],
            'salario': request.form['salario'],
            'username': request.form['username'],
            'rol': request.form['rol']
        }
        Empleado.update(id_e, data)
        flash('Empleado actualizado exitosamente', 'success')
    except Exception as e:
        flash(f'Error al actualizar empleado: {str(e)}', 'danger')
    return redirect(url_for('empleado.list_empleados'))

@empleado_bp.route('/empleados/delete/<int:id_e>', methods=['GET', 'POST'])
@login_required
def delete_empleado(id_e):
    try:
        Empleado.delete(id_e)
        flash('Empleado eliminado exitosamente', 'success')
    except Exception as e:
        flash(f'Error al eliminar empleado: {str(e)}', 'danger')
    return redirect(url_for('empleado.list_empleados'))
