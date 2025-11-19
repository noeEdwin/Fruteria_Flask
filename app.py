from flask import Flask, render_template, request, redirect, url_for, flash
from flask_login import (
    LoginManager, UserMixin, login_user,
    logout_user, login_required, current_user
)
from werkzeug.security import generate_password_hash, check_password_hash

from config.db import get_cursor, get_db, close_db

app = Flask(__name__)
app.secret_key = "replace-with-a-secure-random-key"  # IMPORTANT: change in production

# ------------- Flask-Login -------------
login_manager = LoginManager(app)
login_manager.login_view = "login"  # si no está logueado, lo manda a /login


# --------- Clase User para Flask-Login (sin ORM) ----------
class User(UserMixin):
    def __init__(self, id, username, nombre_completo=None):
        self.id = str(id)  # Flask-Login espera string
        self.username = username
        self.nombre_completo = nombre_completo

    @staticmethod
    def get_by_id(user_id):
        # user_id comes as string from Flask-Login; DB primary key is id_e
        with get_cursor() as cur:
            cur.execute(
                "SELECT id_e AS id, username, nombre AS nombre_completo FROM empleado WHERE id_e = %s",
                (int(user_id),)
            )
            row = cur.fetchone()
        if row:
            return User(row["id"], row["username"], row.get("nombre_completo"))
        return None

    @staticmethod
    def get_by_username(username):
        # Match the DDL: empleado table has id_e, username, password (we store the hash in `password`)
        with get_cursor() as cur:
            cur.execute(
                "SELECT id_e AS id, username, password AS password_hash, nombre AS nombre_completo "
                "FROM empleado WHERE username = %s",
                (username,)
            )
            row = cur.fetchone()
        return row


@login_manager.user_loader
def load_user(user_id):
    return User.get_by_id(user_id)


# ---------- Cerrar DB al final de cada request ----------
@app.teardown_appcontext
def teardown_db(exception):
    close_db(exception)


# ---------- Ruta de prueba para crear un usuario demo ----------
@app.route("/crear_usuario_demo")
def crear_usuario_demo():
    """Crea un usuario admin/admin123 solo para pruebas."""
    password_plano = "admin123"
    hash_pw = generate_password_hash(password_plano)

    conn = get_db()
    # Insert into 'empleado' according to your DDL. Use username UNIQUE to avoid duplicates.
    with get_cursor(dict_cursor=False) as cur:
        cur.execute(
            "INSERT INTO empleado (id_e, nombre, turno, salario, username, password) "
            "VALUES (%s, %s, %s, %s, %s, %s) ON CONFLICT (username) DO NOTHING",
            (1, "Administrador", "Mañana", 0.00, "admin", hash_pw),
        )
        conn.commit()

    return "Usuario 'admin' creado con password 'admin123' (borra esta ruta en producción)"


# ------------------- LOGIN -------------------
@app.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        username = request.form.get("username", "").strip()
        password = request.form.get("password", "")

        user_row = User.get_by_username(username)

        if user_row and check_password_hash(user_row["password_hash"], password):
            user = User(user_row["id"], user_row["username"], user_row.get("nombre_completo"))
            login_user(user)
            flash(f"Bienvenido, {user.username}", "success")
            return redirect(url_for("dashboard"))
        else:
            flash("Usuario o contraseña incorrectos", "danger")

    return render_template("login.html")


# ------------------- LOGOUT -------------------
@app.route("/logout")
@login_required
def logout():
    logout_user()
    flash("Sesión cerrada", "info")
    return redirect(url_for("login"))


# ------------------- DASHBOARD PROTEGIDO -------------------
@app.route("/dashboard")
@login_required
def dashboard():
    return render_template("dashboard.html", user=current_user)


# (Opcional) redirigir raíz al login o dashboard
@app.route("/")
def index():
    if current_user.is_authenticated:
        return redirect(url_for("dashboard"))
    return redirect(url_for("login"))


if __name__ == "__main__":
    app.run(debug=True)
