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

from app.models.product import get_dashboard_stats, get_low_stock_products

@auth_bp.route("/dashboard")
@login_required
def dashboard():
    stats = get_dashboard_stats()
    low_stock_products = get_low_stock_products()
    return render_template("dashboard.html", user=current_user, stats=stats, low_stock_products=low_stock_products)

@auth_bp.route("/")
def index():
    if current_user.is_authenticated:
        return redirect(url_for("auth.dashboard"))
    return redirect(url_for("auth.login"))
