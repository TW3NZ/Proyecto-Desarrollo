import pymysql

from dataBase.db import get_connection


def probar_conexion():
    conexion = None

    try:
        conexion = get_connection()
        print("Conexión exitosa a MySQL.")
    except pymysql.MySQLError as error:
        print(f"No se pudo conectar a MySQL: {error}")
    finally:
        if conexion is not None:
            conexion.close()
            print("Conexión cerrada.")


if __name__ == "__main__":
    probar_conexion()
