"""Aiven connection check or interactive SQL session using backend/.env."""
import argparse
import os
from pathlib import Path
import re
import shutil
import ssl
import subprocess
import tempfile

from dotenv import dotenv_values


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--interactive", action="store_true", help="Abrir una sesión SQL interactiva.")
    options = parser.parse_args()
    values = dotenv_values(Path(__file__).resolve().parents[1] / ".env", encoding="utf-8-sig")
    required = ("DB_HOST", "DB_PORT", "DB_USER", "DB_PASSWORD", "DB_NAME", "DB_SSL_CA")
    if any(not values.get(key) for key in required):
        print("CONFIG_ERROR: completa las variables DB_* en backend/.env.")
        return 1
    client = shutil.which("mysql")
    if not client:
        candidate = Path("C:/Program Files/MySQL/MySQL Server 8.0/bin/mysql.exe")
        client = str(candidate) if candidate.is_file() else None
    if not client:
        print("CLIENT_ERROR: instala el cliente mysql y agrégalo al PATH.")
        return 1
    try:
        pem = values["DB_SSL_CA"]
        ssl.create_default_context(cadata=pem)
        port = int(values["DB_PORT"])
        timeout = int(values.get("DB_CONNECT_TIMEOUT") or "10")
        if not 1 <= port <= 65535 or not 1 <= timeout <= 120:
            raise ValueError()
    except (ValueError, ssl.SSLError):
        print("CONFIG_ERROR: revisa el PEM completo, puerto y timeout (1–120 segundos).")
        return 1
    # mysql requires a CA file. The authoritative PEM remains inline in .env;
    # this temporary copy is automatically removed after the command exits.
    with tempfile.TemporaryDirectory(prefix="aiven-check-") as directory:
        ca = Path(directory) / "ca.pem"
        ca.write_text(pem, encoding="utf-8")
        env = os.environ.copy()
        env["MYSQL_PWD"] = values["DB_PASSWORD"]
        args = [client, "--no-defaults", "--protocol=TCP",
                "--host=" + values["DB_HOST"], "--port=" + str(port),
                "--user=" + values["DB_USER"], "--database=" + values["DB_NAME"],
                "--ssl-mode=VERIFY_IDENTITY", "--ssl-ca=" + str(ca),
                "--connect-timeout=" + str(timeout), "--batch",
                "--execute=SELECT 1 AS connection_ok; SHOW SESSION STATUS LIKE 'Ssl_cipher'; "
                "SELECT COUNT(*) AS table_count FROM information_schema.tables "
                "WHERE table_schema = DATABASE() AND table_type = 'BASE TABLE';"]
        try:
            if options.interactive:
                # Remove the batch/execute options; keep the terminal attached.
                return subprocess.run(args[:-2], env=env, check=False).returncode
            result = subprocess.run(args, env=env, capture_output=True, text=True,
                                    timeout=timeout + 15, check=False)
        except (OSError, subprocess.TimeoutExpired):
            print("CONNECTION_ERROR: no se pudo ejecutar el cliente o se agotó el tiempo.")
            return 1
        if result.returncode:
            code = re.search(r"ERROR (\d+)", result.stderr)
            number = code.group(1) if code else "unknown"
            messages = {"1045": "Credenciales rechazadas.", "1049": "La base indicada no existe.",
                        "2005": "No se pudo resolver el host.", "2003": "No se pudo alcanzar el servidor.",
                        "2026": "Falló la validación TLS del certificado o del host."}
            print(f"CONNECTION_ERROR {number}: {messages.get(number, 'La conexión falló; revisa la configuración.')} ")
            return 1
        print("Conexión correcta; certificado y nombre del servidor verificados.")
        print(result.stdout.strip())
        return 0


if __name__ == "__main__":
    raise SystemExit(main())
