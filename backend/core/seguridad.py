"""Password hashing and JWT issuance for the unified API."""
import os
from datetime import datetime, timedelta, timezone
import jwt
from fastapi import HTTPException
from pwdlib import PasswordHash

password_hash = PasswordHash.recommended()


def crear_token(usuario: dict) -> str:
    secret = os.environ.get('SECRET_KEY', '')
    algorithm = os.environ.get('ALGORITHM', 'HS256')
    if len(secret) < 32 or algorithm != 'HS256':
        raise HTTPException(503, 'Configura SECRET_KEY (32 caracteres o mas) y ALGORITHM=HS256.')
    datos = {
        'sub': str(usuario['idUsu']),
        'exp': datetime.now(timezone.utc) + timedelta(
            minutes=int(os.environ.get('ACCESS_TOKEN_EXPIRE_MINUTES', '120'))),
    }
    return jwt.encode(datos, secret, algorithm=algorithm)


def verificar_token(token: str) -> dict:
    """Valida firma, algoritmo, expiración y la presencia de `sub` y `exp`."""
    secret = os.environ.get('SECRET_KEY', '')
    algorithm = os.environ.get('ALGORITHM', 'HS256')
    if len(secret) < 32 or algorithm != 'HS256':
        raise HTTPException(503, 'Configura SECRET_KEY (32 caracteres o mas) y ALGORITHM=HS256.')
    try:
        datos = jwt.decode(token, secret, algorithms=[algorithm])
    except jwt.ExpiredSignatureError:
        raise HTTPException(401, 'Sesión expirada.') from None
    except jwt.InvalidTokenError:
        raise HTTPException(401, 'Token no válido.') from None
    if 'sub' not in datos or 'exp' not in datos:
        raise HTTPException(401, 'Token no válido.') from None
    return datos
