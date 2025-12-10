from flask import Blueprint, render_template, request, redirect, url_for, flash, session
from flask_login import login_user, logout_user, login_required, current_user
from config.db import get_db
from app.models.user import User
import psycopg2

auth_bp = Blueprint('auth', __name__)

@auth_bp.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        username = request.form.get("username", "").strip()
        password = request.form.get("password", "")

        try:
            conn = get_db(user=username, password=password)
            conn.close()
            
            session["db_user"] = username
            
            user = User.get(username)
            login_user(user)
            
            flash(f"Bienvenido, {user.username}", "success")
            
            # Redirección basada en rol
            if user.rol == 'vendedor':
                return redirect(url_for('ventas.nueva_venta'))
            elif user.rol == 'almacenista':
                return redirect(url_for('products.productos'))
            
            return redirect(url_for("auth.dashboard"))
            
        except psycopg2.OperationalError:
            flash("Usuario o contraseña incorrectos (DB Auth Failed)", "danger")
        except Exception as e:
             flash(f"Error de conexión: {e}", "danger")

    return render_template("login.html")

@auth_bp.route("/logout")
@login_required
def logout():
    logout_user()
    session.pop("db_user", None)
    flash("Sesión cerrada", "info")
    return redirect(url_for("auth.login"))

from app.models.product import get_dashboard_stats, get_low_stock_products, get_top_categories
from app.models.venta import get_weekly_sales, get_daily_stats
import datetime

@auth_bp.route("/dashboard")
@login_required
def dashboard():
    # Redireccionar si no tiene permisos para ver el dashboard
    if current_user.rol == 'vendedor':
        return redirect(url_for('ventas.nueva_venta'))
    elif current_user.rol == 'almacenista':
        return redirect(url_for('products.productos'))
        
    stats = get_dashboard_stats()
    low_stock = get_low_stock_products()
    weekly_sales_raw = get_weekly_sales()
    top_categories_raw = get_top_categories()
    daily_stats = get_daily_stats()
    
   # Traducir los días de la semana de inglés a español
    dia_map = {
        'Sun': 'Dom', 'Mon': 'Lun', 'Tue': 'Mar', 'Wed': 'Mié',
        'Thu': 'Jue', 'Fri': 'Vie', 'Sat': 'Sáb'
    }
    weekly_sales = []
    for item in weekly_sales_raw:
        dia_en = item['dia_nombre']
        weekly_sales.append({
            'dia_nombre': dia_map.get(dia_en, dia_en),
            'total': float(item['total']) if item['total'] else 0.0
        })
        
    top_categories = []
    for item in top_categories_raw:
        top_categories.append({
            'categoria': item['categoria'],
            'total_vendido': int(item['total_vendido']) if item['total_vendido'] else 0
        })
    
    
    # Fecha en español
    current_date = datetime.datetime.now()
    meses_es = {
        1: "Enero", 2: "Febrero", 3: "Marzo", 4: "Abril",
        5: "Mayo", 6: "Junio", 7: "Julio", 8: "Agosto",
        9: "Septiembre", 10: "Octubre", 11: "Noviembre", 12: "Diciembre"
    }
    now = f"{current_date.day:02d} de {meses_es[current_date.month]} de {current_date.year}"
    
    return render_template("dashboard.html", 
                           user=current_user, 
                           stats=stats, 
                           low_stock_products=low_stock,
                           weekly_sales=weekly_sales,
                           top_categories=top_categories,
                           daily_stats=daily_stats,
                           now=now)

@auth_bp.route("/")
def index():
    if current_user.is_authenticated:
        return redirect(url_for("auth.dashboard"))
    return redirect(url_for("auth.login"))
