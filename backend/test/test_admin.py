from contextlib import contextmanager
from unittest.mock import MagicMock

import pytest
from fastapi import HTTPException
from fastapi.testclient import TestClient

from backend.app import app
from backend.database import admin


@pytest.fixture
def client(monkeypatch):
    monkeypatch.setenv('ADMIN_USER', 'admin')
    monkeypatch.setenv('ADMIN_PASSWORD', 'test-admin-password-' * 3)
    return TestClient(app)


AUTH = ('admin', 'test-admin-password-' * 3)


def test_loopback_does_not_require_credentials(monkeypatch):
    monkeypatch.delenv('ADMIN_USER', raising=False)
    monkeypatch.delenv('ADMIN_PASSWORD', raising=False)
    monkeypatch.setattr(admin, 'schema', lambda cursor: [])
    @contextmanager
    def reader():
        yield None
    monkeypatch.setattr(admin, 'reader', reader)
    local = TestClient(app, base_url='http://127.0.0.1:8000', client=('127.0.0.1', 12345))
    assert local.get('/admin/').status_code == 200
    response = local.get('/admin/api/schema', headers={'Origin': 'http://127.0.0.1:5500'})
    assert response.status_code == 200
    assert response.json() == {'tables': []}
    assert local.get('/admin/api/schema', headers={'Origin': 'https://untrusted.example'}).status_code == 401
    assert local.get('/admin/api/schema', headers={'Host': 'untrusted.example'}).status_code == 401
    assert local.get('/admin/api/schema', headers={'X-Forwarded-For': '127.0.0.1'}).status_code == 401
    remote = TestClient(app, base_url='http://127.0.0.1:8000', client=('192.168.1.20', 12345))
    assert remote.get('/admin/api/schema').status_code == 401


def test_live_server_preflight_and_authentication(client, monkeypatch):
    connect = MagicMock()
    monkeypatch.setattr(admin, 'get_connection', connect)
    origin = 'http://127.0.0.1:5500'
    headers = {'Origin': origin, 'Access-Control-Request-Method': 'GET',
               'Access-Control-Request-Headers': 'authorization'}
    response = client.options('/admin/api/schema', headers=headers)
    assert response.status_code == 200
    assert response.headers['access-control-allow-origin'] == origin
    assert 'authorization' in response.headers['access-control-allow-headers'].lower()
    response = client.get('/admin/api/schema', headers={'Origin': origin})
    assert response.status_code == 401
    assert response.headers['access-control-allow-origin'] == origin
    connect.assert_not_called()
    headers['Origin'] = 'https://untrusted.example'
    response = client.options('/admin/api/schema', headers=headers)
    assert response.status_code == 400
    assert 'access-control-allow-origin' not in response.headers


def test_admin_rejects_unauthorized_without_connecting(client, monkeypatch):
    connect = MagicMock()
    monkeypatch.setattr(admin, 'get_connection', connect)
    for route in ['/admin', '/admin/assets/admin.js', '/admin/api/schema', '/admin/api/tables/Usuario']:
        assert client.get(route).status_code == 401
        assert client.get(route, auth=('admin', 'wrong')).status_code == 401
    connect.assert_not_called()


def test_admin_page_headers_and_assets(client):
    page = client.get('/admin', auth=AUTH)
    assert page.status_code == 200
    assert 'Explora tu base de datos' in page.text
    assert page.headers['Cache-Control'] == 'no-store'
    assert "frame-ancestors 'none'" in page.headers['Content-Security-Policy']
    for asset in ('admin.css', 'admin.js'):
        assert client.get('/admin/assets/' + asset, auth=AUTH).status_code == 200
    css = client.get('/admin/admin.css', auth=AUTH)
    assert css.headers['content-type'].startswith('text/css')
    js = client.get('/admin/admin.js', auth=AUTH)
    assert js.headers['content-type'].startswith('text/javascript')
    assert client.get('/admin/brand.png', auth=AUTH).headers['content-type'] == 'image/png'
    assert client.get('/admin', auth=AUTH, follow_redirects=False).headers['location'] == '/admin/'
    assert client.get('/admin/assets/unknown', auth=AUTH).status_code == 422


def test_invalid_pagination_and_filters(client):
    for query in ['size=101', 'page=0', 'filters=[]', 'filters={"id":[]}', 'direction=DROP']:
        assert client.get('/admin/api/tables/Usuario?' + query, auth=AUTH).status_code == 422


@pytest.fixture
def table_schema(monkeypatch):
    tables = [{'name': 'Usuario', 'relations': [], 'columns': [
        {'name': 'idUsu', 'hidden': False, 'key_type': 'PRI'},
        {'name': 'nameUsu', 'hidden': False, 'key_type': ''},
        {'name': 'passwordUsu', 'hidden': True, 'key_type': ''},
    ]}]
    monkeypatch.setattr(admin, 'schema', lambda cursor: tables)
    return tables


def test_rows_parameterize_search_mask_secrets_and_page(table_schema):
    cursor = MagicMock()
    cursor.fetchone.return_value = {'total': 51}
    cursor.fetchall.return_value = []
    text = "' OR 1=1; --"
    result = admin.rows(cursor, 'Usuario', text, {'idUsu': 7}, 2, 25, 'nameUsu', 'desc')
    sql, params = cursor.execute.call_args.args
    assert text not in sql
    assert params == [text, text, 7, 25, 25]
    assert 'NULL AS `passwordUsu`' in sql
    assert 'CAST(`passwordUsu`' not in sql
    assert 'ORDER BY `nameUsu` DESC, `idUsu` DESC' in sql
    assert result['total'] == 51


@pytest.mark.parametrize('table,filters,sort', [
    ('Usuario; DROP TABLE Usuario', {}, ''),
    ('Usuario', {'passwordUsu': 'secret'}, ''),
    ('Usuario', {}, 'passwordUsu'),
    ('Usuario', {}, 'idUsu; DELETE'),
])
def test_unknown_identifiers_and_hidden_columns_rejected(table_schema, table, filters, sort):
    cursor = MagicMock()
    with pytest.raises(HTTPException):
        admin.rows(cursor, table, '', filters, 1, 25, sort, 'asc')
    cursor.execute.assert_not_called()


def test_reader_read_only_rollback_and_close_on_failure(monkeypatch):
    connection = MagicMock()
    monkeypatch.setattr(admin, 'get_connection', lambda: connection)
    with pytest.raises(HTTPException) as error:
        with admin.reader():
            raise RuntimeError('private-provider-detail')
    assert error.value.status_code == 503
    assert 'private-provider-detail' not in error.value.detail
    connection.cursor.return_value.__enter__.return_value.execute.assert_called_once_with('START TRANSACTION READ ONLY')
    connection.rollback.assert_called_once()
    connection.close.assert_called_once()


def test_composite_and_reverse_relation_metadata():
    cursor = MagicMock()
    cursor.fetchall.side_effect = [
        [{'name': 'Parent'}, {'name': 'Child'}],
        [{'tab': 'Child', 'name': 'passwordUsu', 'type': 'varchar(255)', 'nullable': 'NO', 'key_type': ''}],
        [dict(source_table='Child', target_table='Parent', source_column=a, target_column=b, constraint_name='fk')
         for a, b in [('p1', 'id1'), ('p2', 'id2')]],
    ]
    result = admin.schema(cursor)
    child = next(t for t in result if t['name'] == 'Child')
    assert child['columns'][0]['hidden'] is True
    assert len(child['relations']) == 1
    assert child['relations'][0]['columns'] == [{'source': 'p1', 'target': 'id1'}, {'source': 'p2', 'target': 'id2'}]


def test_authenticated_endpoint_runs_query(client, table_schema, monkeypatch):
    cursor = MagicMock()
    cursor.fetchone.return_value = {'total': 1}
    cursor.fetchall.return_value = [{'idUsu': 1, 'nameUsu': '<script>bad</script>', 'passwordUsu': None}]
    @contextmanager
    def reader():
        yield cursor
    monkeypatch.setattr(admin, 'reader', reader)
    response = client.get('/admin/api/tables/Usuario', auth=AUTH)
    assert response.status_code == 200
    assert response.json()['rows'][0]['passwordUsu'] is None
    assert client.post('/admin/api/tables/Usuario', auth=AUTH).status_code == 405
