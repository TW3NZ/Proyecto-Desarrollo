"""Read-only check using the same Python connector as the API."""
from backend.database.db import get_connection
from backend.utils.settings import load_settings


def probar_conexion() -> int:
    load_settings()
    conexion = None
    try:
        conexion = get_connection()
        with conexion.cursor() as cursor:
            cursor.execute('SELECT 1 AS connection_ok')
            assert cursor.fetchone()['connection_ok'] == 1
            cursor.execute("SHOW SESSION STATUS LIKE 'Ssl_cipher'")
            assert cursor.fetchone()['Value']
        print('Conexion MySQL correcta con el conector de la API y TLS verificado.')
        return 0
    except Exception:
        print('No se pudo verificar MySQL. Revisa variables DB_*, certificado y red.')
        return 1
    finally:
        if conexion is not None:
            conexion.close()


if __name__ == '__main__':
    raise SystemExit(probar_conexion())
