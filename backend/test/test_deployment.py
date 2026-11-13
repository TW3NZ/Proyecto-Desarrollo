"""Deployment boundaries: cheap health check and disabled public admin."""
from unittest.mock import Mock

import pytest
from fastapi.testclient import TestClient

from backend.app import app
from backend.database import admin


def test_health_does_not_need_external_services(monkeypatch):
    for name in ('OPENAI_API_KEY', 'DB_HOST', 'DB_PASSWORD', 'SECRET_KEY'):
        monkeypatch.delenv(name, raising=False)
    with TestClient(app) as client:
        response = client.get('/health')
    assert response.status_code == 200
    assert response.json() == {'status': 'ok'}


@pytest.mark.parametrize('route', [
    '/admin', '/admin/', '/admin/admin.js', '/admin/assets/admin.css',
    '/admin/api/schema', '/admin/api/tables/Usuario',
])
def test_disabled_admin_rejects_even_loopback(route, monkeypatch):
    monkeypatch.setenv('ADMIN_ENABLED', 'false')
    connection = Mock()
    monkeypatch.setattr(admin, 'get_connection', connection)
    with TestClient(app, base_url='http://localhost', client=('127.0.0.1', 1234)) as client:
        response = client.get(route)
    assert response.status_code == 404
    connection.assert_not_called()
