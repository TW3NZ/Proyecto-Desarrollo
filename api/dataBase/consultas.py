
from dataBase.db import get_connection

# FUNCIÓN PARA VERIFICAR SI EXISTE UN ID
def existe_id(id_usuario: int) -> bool:
    conexion = get_connection()

    try:
        with conexion.cursor() as cursor:
            sql = "SELECT idUsu FROM Usuario WHERE idUsu = %s"
            cursor.execute(sql, (id_usuario,))
            resultado = cursor.fetchone()

        return resultado is not None

    finally:
        conexion.close()