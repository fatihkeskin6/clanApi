import os
import psycopg
from psycopg.rows import dict_row

DATABASE_URL = os.getenv("DATABASE_URL")

if not DATABASE_URL:
    raise RuntimeError("DATABASE_URL env var is required (postgresql://user:pass@host:5432/dbname)")

def get_conn():
    # Simple connection per request (fine for small apps / assignments)
    return psycopg.connect(DATABASE_URL, row_factory=dict_row)
