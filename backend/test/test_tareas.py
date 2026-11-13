"""Pruebas del endpoint PATCH /tareas/{idTarea}/completar sin tocar Aiven."""
from unittest.mock import MagicMock

import pytest
from fastapi import HTTPException
from fastapi.testclient import TestClient

from backend import app as api


@pytest.fixture
def connection(monkeypatch):
    connection = MagicMock()
    monkeypatch.setattr(api, "get_connection", lambda: connection)
    return connection


def autenticado(monkeypatch, sub="12345678", error=None):
    if error is not None:
        def _fail(token):
            raise error
        monkeypatch.setattr(api, "verificar_token", _fail)
    else:
        monkeypatch.setattr(
            api, "verificar_token",
            lambda token: {"sub": sub, "exp": 9999999999},
        )


def patch(client, id_tarea, con_token=True):
    headers = {"Authorization": "Bearer test-token"} if con_token else {}
    return client.patch(f"/tareas/{id_tarea}/completar", headers=headers)


def test_completar_con_token_valido_actualiza_y_commitea(connection, monkeypatch):
    autenticado(monkeypatch)
    cursor = connection.cursor.return_value.__enter__.return_value
    cursor.fetchone.side_effect = [{"idUsu": 12345678}, {"idTarea": 96047524}, None]

    response = patch(TestClient(api.app), 96047524)

    assert response.status_code == 200
    # Se ejecutan SELECT (verificación) y UPDATE.
    assert cursor.execute.call_count == 6
    update_sql, update_params = cursor.execute.call_args_list[2].args
    assert "UPDATE Tarea" in update_sql
    assert "idTarea" in update_sql and "idUsu" in update_sql
    assert update_params == (96047524, 12345678)
    connection.commit.assert_called_once()
    connection.close.assert_called_once()


def test_completar_sin_token_es_rechazado(connection, monkeypatch):
    autenticado(monkeypatch)
    response = patch(TestClient(api.app), 96047524, con_token=False)
    assert response.status_code == 401
    connection.commit.assert_not_called()


def test_completar_tarea_inexistente_o_ajena_devuelve_404(connection, monkeypatch):
    autenticado(monkeypatch)
    cursor = connection.cursor.return_value.__enter__.return_value
    cursor.fetchone.side_effect = [{"idUsu": 12345678}, None]  # tarea ajena

    response = patch(TestClient(api.app), 96047524)

    assert response.status_code == 404
    connection.commit.assert_not_called()


def test_completar_dos_veces_es_idempotente(connection, monkeypatch):
    autenticado(monkeypatch)
    cursor = connection.cursor.return_value.__enter__.return_value
    cursor.fetchone.side_effect = [{"idUsu": 12345678}, {"idTarea": 96047524}, None]
    cursor.fetchone.side_effect = [{"idUsu": 12345678}, {"idTarea": 96047524}, None] * 2
    cursor.fetchall.return_value = [{"idCategoria": 1, "puntos": 5}]
    client = TestClient(api.app)

    assert patch(client, 96047524).status_code == 200
    assert patch(client, 96047524).status_code == 200
    # Dos peticiones: dos UPDATE, sin errores ni efectos secundarios.
    assert connection.commit.call_count == 2
    writes = [c.args[1] for c in cursor.execute.call_args_list if 'INSERT INTO Estadistica' in c.args[0]]
    assert writes[0] == writes[1]  # recomputation never increments twice


def test_completar_con_token_expirado_es_rechazado(connection, monkeypatch):
    autenticado(monkeypatch, error=HTTPException(401, "Sesión expirada."))
    response = patch(TestClient(api.app), 96047524)
    assert response.status_code == 401
    connection.commit.assert_not_called()
