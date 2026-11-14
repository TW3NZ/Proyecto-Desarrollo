"""Unified routes tested without writing to Aiven or calling OpenAI."""
from unittest.mock import MagicMock

import jwt
import pytest
from fastapi.testclient import TestClient

from backend import app as api


@pytest.fixture
def connection(monkeypatch):
    connection = MagicMock()
    monkeypatch.setattr(api, "get_connection", lambda: connection)
    monkeypatch.setattr(api, "generar_id_unico", lambda: 12345678)
    monkeypatch.setenv("SECRET_KEY", "test-secret-" * 5)
    monkeypatch.setenv("ALGORITHM", "HS256")
    monkeypatch.setenv("ACCESS_TOKEN_EXPIRE_MINUTES", "120")
    return connection


def registration():
    return dict(name="Ana", lastName="Test", nickName="ana",
                email="ana@example.com", password="test-password",
                createDate="2026-11-11", genero="Mujer", foto=None)


def test_registration_hashes_password_and_commits(connection):
    response = TestClient(api.app).post("/usuarios", json=registration())
    assert response.status_code == 201
    cursor = connection.cursor.return_value.__enter__.return_value
    sql, params = cursor.execute.call_args_list[0].args
    assert "INSERT INTO Usuario" in sql
    assert params[0] == 12345678
    assert params[5] != "test-password"
    assert api.password_hash.verify("test-password", params[5])
    assert "100,100,100,100" in cursor.execute.call_args.args[0]
    assert cursor.execute.call_args.args[1] == (12345678,)
    connection.commit.assert_called_once()
    connection.rollback.assert_not_called()
    connection.close.assert_called_once()


def test_registration_rolls_back_on_write_error(connection):
    connection.cursor.return_value.__enter__.return_value.execute.side_effect = RuntimeError("write failure")
    response = TestClient(api.app, raise_server_exceptions=False).post("/usuarios", json=registration())
    assert response.status_code == 500
    connection.commit.assert_not_called()
    connection.rollback.assert_called_once()
    connection.close.assert_called_once()


def test_login_returns_signed_token_without_hash(connection):
    connection.cursor.return_value.__enter__.return_value.fetchone.return_value = {
        "idUsu": 12345678, "nickName": "ana",
        "passwordUsu": api.password_hash.hash("test-password"),
    }
    response = TestClient(api.app).post("/auth/login/user", json={
        "identificador": "ana", "password": "test-password"})
    assert response.status_code == 200
    body = response.json()
    assert "passwordUsu" not in body["usuario"]
    claims = jwt.decode(body["access_token"], "test-secret-" * 5, algorithms=["HS256"])
    assert claims["sub"] == "12345678"
    assert "exp" in claims
    connection.close.assert_called_once()


@pytest.mark.parametrize("exists", [False, True])
def test_bad_login_is_rejected(connection, exists):
    connection.cursor.return_value.__enter__.return_value.fetchone.return_value = (
        {"passwordUsu": api.password_hash.hash("correct-password")} if exists else None)
    response = TestClient(api.app).post("/auth/login/user", json={
        "identificador": "ana", "password": "wrong-password"})
    assert response.status_code == 401
    connection.close.assert_called_once()


def test_routes_share_one_app():
    client = TestClient(api.app)
    assert client.get("/docs").status_code == 200
    routes = client.get("/openapi.json").json()["paths"]
    assert {"/usuarios", "/auth/login/user", "/avatar/suggest"} <= routes.keys()
