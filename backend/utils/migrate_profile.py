"""Apply the versioned, additive profile migration; never run the full schema."""
import argparse
from pathlib import Path
from backend.utils.settings import load_settings
from backend.database.db import get_connection


def main():
    parser = argparse.ArgumentParser(description='Migracion de perfil y precision de estadisticas.')
    parser.add_argument('--apply', action='store_true', help='Aplicar a la base del entorno actual.')
    parser.add_argument('--migration', choices=['001', '002', '003'], default='001')
    args = parser.parse_args()
    path = Path(__file__).resolve().parents[2] / 'database/migrations/001_perfil_usuario.sql'
    if args.migration == '002':
        path = path.with_name('002_puntuacion_dinamica.sql')
    if args.migration == '003':
        path = path.with_name('003_equipos.sql')
    sql = path.read_text(encoding='utf-8')
    if not args.apply:
        print(sql)
        return
    load_settings()
    connection = get_connection()
    try:
        with connection.cursor() as cursor:
            statements = '\n'.join(line for line in sql.splitlines() if not line.lstrip().startswith('--'))
            for statement in statements.split(';'):
                if statement.strip():
                    cursor.execute(statement)
        connection.commit()
        print(f'Migracion {args.migration} aplicada. Tareas y usuarios conservados.')
    finally:
        connection.close()


if __name__ == '__main__':
    main()
