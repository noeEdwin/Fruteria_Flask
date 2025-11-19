# db.py
import psycopg2
import psycopg2.extras
from flask import g
from config.config import DB_CONFIG

def get_db():
    if "db" not in g:
        g.db = psycopg2.connect(**DB_CONFIG)
    return g.db

def get_cursor(dict_cursor=True):
    conn = get_db()
    if dict_cursor:
        return conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    return conn.cursor()

def close_db(e=None):
    db = g.pop("db", None)
    if db is not None:
        db.close()
