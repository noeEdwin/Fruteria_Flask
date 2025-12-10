# config.py

import os

# Configuración de base de datos
# Prioridad: Variables de Entorno (Producción) > Valores por defecto (Local)
DB_CONFIG = {
    "dbname": os.getenv("DB_NAME", "fruteria_db"),
    "user": os.getenv("DB_USER", "postgres"),
    "password": os.getenv("DB_PASSWORD", "9474609"),
    "host": os.getenv("DB_HOST", "localhost"),
    "port": os.getenv("DB_PORT", "5432"),
    "options": "-c search_path=fruteria_db",
}

# En producción (Supabase/Render) se requiere SSL
if os.getenv("RENDER") or os.getenv("DB_HOST"):
     DB_CONFIG["sslmode"] = "require"
