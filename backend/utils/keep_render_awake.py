"""External, local heartbeat for development; run with python -m."""
import argparse
import json
import time
from datetime import datetime
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen


HEALTH_URL = 'https://my-daily-rutine.onrender.com/health'
INTERVAL = 40


def ping() -> bool:
    request = Request(HEALTH_URL, headers={'User-Agent': 'MyDailyRutine-Heartbeat/1.0'})
    stamp = datetime.now().astimezone().isoformat(timespec='seconds')
    try:
        with urlopen(request, timeout=30) as response:
            body = json.loads(response.read(4096))
            if response.status != 200 or body != {'status': 'ok'}:
                print(f'{stamp} Respuesta inesperada de /health.', flush=True)
                return False
        print(f'{stamp} OK /health', flush=True)
        return True
    except HTTPError as error:
        print(f'{stamp} HTTP {error.code}; comprueba el despliegue de /health.', flush=True)
    except (URLError, OSError, ValueError):
        print(f'{stamp} Sin respuesta valida; puede estar arrancando o sin conexion.', flush=True)
    return False


def main() -> int:
    parser = argparse.ArgumentParser(description='Consulta Render cada 40 segundos desde este equipo.')
    parser.add_argument('--once', action='store_true', help='Una sola comprobacion y salir.')
    args = parser.parse_args()
    if args.once:
        return 0 if ping() else 1
    print(f'Consultando {HEALTH_URL} cada {INTERVAL}s. Detener: Ctrl+C.', flush=True)
    try:
        while True:
            started = time.monotonic()
            ping()
            # No overlapping requests or catch-up bursts after suspension.
            time.sleep(max(1, INTERVAL - (time.monotonic() - started)))
    except KeyboardInterrupt:
        print('\nMonitor detenido.', flush=True)
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
