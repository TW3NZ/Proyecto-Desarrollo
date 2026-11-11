import os
from datetime import datetime, timedelta, timezone
from pathlib import Path

import jwt
from dotenv import load_dotenv
from pwdlib import PasswordHash

# Carga api/.env sin depender del directorio desde donde se ejecute.
load_dotenv(Path(__file__).resolve().parents[1] / ".env")

SECRET_KEY = os.getenv("SECRET_KEY")
ALGORITHM = os.getenv("ALGORITHM", "HS256")
TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "120"))

if not SECRET_KEY:
    raise RuntimeError("Falta SECRET_KEY en el archivo .env")

password_hash = PasswordHash.recommended() 


def crear_token(usuario: dict) -> str:
    datos = {
        "sub": str(usuario["idUsu"]),
        "exp": datetime.now(timezone.utc) + timedelta(minutes=TOKEN_EXPIRE_MINUTES),
    }
    return jwt.encode(datos, SECRET_KEY, algorithm=ALGORITHM)
