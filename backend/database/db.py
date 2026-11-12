"""MySQL connections using the unified environment and inline CA."""
import os
import ssl
import pymysql


def get_connection():
    required = ('DB_HOST', 'DB_USER', 'DB_PASSWORD', 'DB_NAME', 'DB_SSL_CA')
    if any(not os.environ.get(key) for key in required):
        raise RuntimeError('Completa las variables DB_* en backend/.env.')
    context = ssl.create_default_context(cadata=os.environ['DB_SSL_CA'])
    return pymysql.connect(
        host=os.environ['DB_HOST'], port=int(os.environ.get('DB_PORT', '3306')),
        user=os.environ['DB_USER'], password=os.environ['DB_PASSWORD'],
        database=os.environ['DB_NAME'], ssl=context,
        connect_timeout=int(os.environ.get('DB_CONNECT_TIMEOUT', '10')),
        read_timeout=30, write_timeout=30, charset='utf8mb4',
        cursorclass=pymysql.cursors.DictCursor, autocommit=False,
    )
