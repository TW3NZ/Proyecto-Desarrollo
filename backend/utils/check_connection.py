"""Explicit live check: sends the bundled avatar illustration, never a personal photo.

Run: python -m backend.utils.check_connection
Uses backend/.env credentials exclusively, so inherited credentials cannot mask errors.
"""
import base64
import os
from pathlib import Path

from dotenv import dotenv_values


def main() -> int:
    root = Path(__file__).resolve().parents[2]
    values = dotenv_values(root / "backend/.env", encoding="utf-8-sig")
    names = ("OPENAI_API_KEY", "OPENAI_AVATAR_MODEL", "AVATAR_SERVICE_TOKEN")
    if not values.get("OPENAI_API_KEY") or len(values.get("AVATAR_SERVICE_TOKEN") or "") < 24:
        print("CONFIG_ERROR: backend/.env necesita OPENAI_API_KEY y AVATAR_SERVICE_TOKEN (24+ caracteres).")
        return 1
    for name in names:
        os.environ.pop(name, None)
        if values.get(name):
            os.environ[name] = values[name]

    from fastapi.testclient import TestClient
    from backend.app import app

    illustration = root / "my_daily_routine/lib/assets/avatar/avatar_human_v2.png"
    with TestClient(app) as client:
        response = client.post("/avatar/suggest", headers={
            "Authorization": f"Bearer {os.environ['AVATAR_SERVICE_TOKEN']}"
        }, json={"image_base64": base64.b64encode(illustration.read_bytes()).decode(),
                 "character_type": "hombre"})
    print("Backend HTTP:", response.status_code)
    if response.status_code == 200:
        print("Propuesta validada:", response.json())
        return 0
    # Only print the backend's fixed, sanitized message, never provider exceptions.
    print("Resultado:", response.json().get("detail", "Error de conexión"))
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
