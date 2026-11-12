"""Read-only schema explorer. Identifiers must come from server metadata."""
from contextlib import contextmanager

from fastapi import HTTPException
from pymysql import MySQLError

from backend.database.db import get_connection


def sensitive(name):
    name = name.lower()
    return any(part in name for part in ("password", "passwd", "secret", "token", "api_key", "credential"))


def identifier(name):
    return '`' + name.replace('`', '``') + '`'


@contextmanager
def reader():
    connection = None
    try:
        connection = get_connection()
        with connection.cursor() as cursor:
            cursor.execute('START TRANSACTION READ ONLY')
            yield cursor
    except (MySQLError, RuntimeError, ValueError, OSError):
        raise HTTPException(503, 'No se pudo consultar Aiven. Revisa la conexión del backend.') from None
    finally:
        if connection is not None:
            try:
                connection.rollback()
            finally:
                connection.close()


def schema(cursor):
    cursor.execute("SELECT TABLE_NAME AS name FROM information_schema.TABLES "
                   "WHERE TABLE_SCHEMA=DATABASE() AND TABLE_TYPE='BASE TABLE' ORDER BY TABLE_NAME")
    tables = {row['name']: {'name': row['name'], 'columns': [], 'relations': []} for row in cursor.fetchall()}
    cursor.execute("SELECT TABLE_NAME AS tab, COLUMN_NAME AS name, COLUMN_TYPE AS type, "
                   "IS_NULLABLE AS nullable, COLUMN_KEY AS key_type FROM information_schema.COLUMNS "
                   "WHERE TABLE_SCHEMA=DATABASE() ORDER BY TABLE_NAME, ORDINAL_POSITION")
    for column in cursor.fetchall():
        table = tables.get(column.pop('tab'))
        if table is not None:
            column['hidden'] = sensitive(column['name'])
            table['columns'].append(column)
    cursor.execute("SELECT TABLE_NAME AS source_table, COLUMN_NAME AS source_column, "
                   "REFERENCED_TABLE_NAME AS target_table, REFERENCED_COLUMN_NAME AS target_column, "
                   "CONSTRAINT_NAME AS constraint_name FROM information_schema.KEY_COLUMN_USAGE "
                   "WHERE TABLE_SCHEMA=DATABASE() AND REFERENCED_TABLE_SCHEMA=DATABASE() "
                   "AND REFERENCED_TABLE_NAME IS NOT NULL ORDER BY TABLE_NAME, CONSTRAINT_NAME, ORDINAL_POSITION")
    groups = {}
    for row in cursor.fetchall():
        if row['source_table'] not in tables or row['target_table'] not in tables:
            continue
        key = (row['source_table'], row['constraint_name'])
        relation = groups.setdefault(key, dict(source=row['source_table'], target=row['target_table'], columns=[]))
        relation['columns'].append({'source': row['source_column'], 'target': row['target_column']})
    for relation in groups.values():
        tables[relation['source']]['relations'].append(relation)
    return list(tables.values())


def rows(cursor, table_name, query, filters, page, size, sort, direction):
    tables = schema(cursor)
    table = next((item for item in tables if item['name'] == table_name), None)
    if table is None:
        raise HTTPException(404, 'Tabla no encontrada.')
    columns = table['columns']
    visible = [c['name'] for c in columns if not c['hidden']]
    if sort and sort not in visible:
        raise HTTPException(422, 'Columna de ordenación no válida.')
    if any(key not in visible for key in filters):
        raise HTTPException(422, 'Columna de filtro no válida.')
    clauses, params = [], []
    if query and visible:
        clauses.append('(' + ' OR '.join(f'LOCATE(%s, CAST({identifier(c)} AS CHAR)) > 0' for c in visible) + ')')
        params.extend([query] * len(visible))
    for key, value in filters.items():
        if value is None:
            clauses.append(f'{identifier(key)} IS NULL')
        else:
            clauses.append(f'{identifier(key)} = %s')
            params.append(value)
    where = ' WHERE ' + ' AND '.join(clauses) if clauses else ''
    name = identifier(table_name)
    cursor.execute(f'SELECT COUNT(*) AS total FROM {name}{where}', params)
    total = cursor.fetchone()['total']
    page = min(page, max(1, (total + size - 1) // size))
    order = ([sort] if sort else []) + [c['name'] for c in columns if c['key_type'] == 'PRI' and c['name'] != sort and not c['hidden']]
    if not order:
        order = visible[:1]
    ordering = ' ORDER BY ' + ', '.join(identifier(c) + (' DESC' if direction == 'desc' else ' ASC') for c in order) if order else ''
    # Password hashes never leave the database, including search and sorting.
    select = ', '.join(('NULL AS ' if c['hidden'] else '') + identifier(c['name']) for c in columns)
    cursor.execute(f'SELECT {select} FROM {name}{where}{ordering} LIMIT %s OFFSET %s',
                   [*params, size, (page - 1) * size])
    return dict(rows=cursor.fetchall(), total=total, page=page, size=size)
