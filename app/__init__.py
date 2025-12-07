from flask import Flask
from flask_login import LoginManager
from config.db import close_db

login_manager = LoginManager()
login_manager.login_view = "auth.login"

def create_app():
    app = Flask(__name__)
    app.secret_key = 'fruteria_super_secreta'

    login_manager.init_app(app)

    from app.models.user import User
    @login_manager.user_loader
    def load_user(user_id):
        return User.get(user_id)

    @app.teardown_appcontext
    def teardown_db(exception):
        close_db(exception)

    from app.routes.auth import auth_bp
    from app.routes.products import products_bp
    
    app.register_blueprint(auth_bp)
    app.register_blueprint(products_bp)

    from app.routes.ventas import ventas_bp
    app.register_blueprint(ventas_bp)

    from app.routes.clientes import clientes_bp
    app.register_blueprint(clientes_bp)

    from app.routes.proveedores import proveedores_bp
    app.register_blueprint(proveedores_bp)

    from app.routes.compras import compras_bp
    app.register_blueprint(compras_bp)

    from app.routes.empleado import empleado_bp
    app.register_blueprint(empleado_bp)

    return app
