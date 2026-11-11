import secrets
from dataBase.db import get_connection


# Generador de ID aleatorio de 8 dígitos
def generar_id():
    return secrets.randbelow(90000000) + 10000000


# Comprueba si el ID ya existe en MySQL
def existe_id(id_usuario: int) -> bool:
    conexion = get_connection()

    try:
        with conexion.cursor() as cursor:
            sql = """
                SELECT idUsu
                FROM Usuario
                WHERE idUsu = %s
            """

            cursor.execute(sql, (id_usuario,))
            resultado = cursor.fetchone()

            return resultado is not None

    finally:
        conexion.close()


# Genera un ID que no esté registrado
def generar_id_unico():
    while True:
        id_generado = generar_id()

        if not existe_id(id_generado):
            return id_generado

