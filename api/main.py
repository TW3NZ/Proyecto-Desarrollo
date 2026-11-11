
from fastapi import FastAPI, HTTPException
from models.usuario import LoginUser, createUser
from dataBase.db import get_connection
from core.seguridad import crear_token, password_hash
from utils.generadores import generar_id_unico


app = FastAPI(title="My Daily Routine API")


# FUNCIÓN DE LOGIN
@app.post("/auth/login/user")
def login(loginUser: LoginUser):
    conexion = get_connection()

    try:
        with conexion.cursor() as cursor:
            sql = """
                SELECT idUsu, nameUsu, lastName, nickName, email,
                       createDate, genero, foto, passwordUsu
                FROM Usuario
                WHERE nickName = %s OR email = %s
            """

            cursor.execute(
                sql,
                (loginUser.identificador, loginUser.identificador)
            )

            resultado = cursor.fetchone()

        if not resultado or not password_hash.verify(
            loginUser.password, resultado["passwordUsu"]
        ):
            raise HTTPException(
                status_code=401,
                detail="Usuario o contraseña incorrectos."
            )

        # Se quita el hash antes de devolver los datos
        usuario_publico = {
            k: v for k, v in resultado.items()
            if k != "passwordUsu"
        }

        return {
            "access_token": crear_token(usuario_publico),
            "token_type": "bearer",
            "usuario": usuario_publico
        }

    finally:
        conexion.close()


# FUNCIÓN PARA CREAR USUARIO
@app.post("/usuarios", status_code=201)
def create_user(usuario: createUser):
    conexion = get_connection()

    try:
        with conexion.cursor() as cursor:
            sql = """
                INSERT INTO Usuario
                (idUsu, email, nameUsu, lastName, nickName,
                 passwordUsu, createDate, genero, foto)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
            """

            valores = (
                generar_id_unico(),
                usuario.email,
                usuario.name,
                usuario.lastName,
                usuario.nickName,
                password_hash.hash(usuario.password),
                usuario.createDate,
                usuario.genero,
                usuario.foto
            )

            cursor.execute(sql, valores)

        conexion.commit()

        return {
            "mensaje": "Usuario registrado correctamente"
        }

    except Exception:
        conexion.rollback()
        raise

    finally:
        conexion.close()
