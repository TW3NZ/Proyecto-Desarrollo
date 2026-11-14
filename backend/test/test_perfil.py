import json
from unittest.mock import MagicMock
import pytest
from fastapi.testclient import TestClient
from backend import app as api
from backend.models.perfil import AvatarConfig


@pytest.fixture
def setup(monkeypatch):
    connection = MagicMock()
    cursor = connection.cursor.return_value.__enter__.return_value
    monkeypatch.setattr(api, 'get_connection', lambda: connection)
    monkeypatch.setattr(api, 'verificar_token', lambda token: {'sub': token})
    return TestClient(api.app), connection, cursor


@pytest.mark.parametrize('route', ['avatar', 'estadisticas'])
def test_profile_requires_auth(setup, route):
    client, connection, _ = setup
    assert client.get('/usuarios/me/' + route).status_code == 401
    connection.cursor.assert_not_called()


def test_avatar_round_trip_scoped_by_jwt(setup):
    client, connection, cursor = setup
    config = AvatarConfig(hairstyle='rizado', shirt='#AABBCC', bodyWidth=1.4).model_dump()
    cursor.fetchone.return_value = {'idUsu': 42}
    response = client.put('/usuarios/me/avatar', headers={'Authorization': 'Bearer 42'}, json=config)
    assert response.status_code == 200
    assert response.json() == config
    assert cursor.execute.call_args.args[1][0] == 42
    cursor.fetchone.side_effect = [{'idUsu': 42}, {'avatar': json.dumps(config)}]
    assert client.get('/usuarios/me/avatar', headers={'Authorization': 'Bearer 42'}).json() == config
    cursor.fetchone.side_effect = [{'idUsu': 99}, None]
    assert client.get('/usuarios/me/avatar', headers={'Authorization': 'Bearer 99'}).json() == AvatarConfig().model_dump()
    connection.close.assert_called()


@pytest.mark.parametrize('changes', [
    {'usuarioId': 99}, {'bodyWidth': 10}, {'hairstyle': 'unknown'},
    {'characterType': 'mujer', 'outfit': 'developerSkin'}, {'eyeColor': 'script'},
])
def test_rejects_owner_and_invalid_appearance(setup, changes):
    client, connection, _ = setup
    result = client.put('/usuarios/me/avatar', headers={'Authorization': 'Bearer 42'}, json=changes)
    assert result.status_code == 422
    connection.commit.assert_not_called()


def test_scores_are_server_owned_and_fractional(setup, monkeypatch):
    client, connection, cursor = setup
    cursor.fetchone.side_effect = [{'idUsu': 42}, None]
    monkeypatch.setattr(api.perfil, 'actualizar_estadisticas', lambda c, u: {'inteligencia': 1.6667, 'finanzas': 100, 'salud': 100, 'disciplina': 100})
    result = client.get('/usuarios/me/estadisticas', headers={'Authorization': 'Bearer 42'})
    assert result.status_code == 200
    assert result.json()['inteligencia'] == 1.6667
    assert result.json()['usuarioId'] == 42
    assert result.json()['finanzas'] == 100
    assert client.put('/usuarios/me/estadisticas/preferencias', headers={'Authorization': 'Bearer 42'},
                      json={'inteligencia': 100}).status_code == 422


def test_completion_rolls_back_when_score_write_fails(setup):
    client, connection, cursor = setup
    cursor.fetchone.side_effect = [{'idUsu': 42}, {'idTarea': 8, 'idProyecto': None}]
    def execute(sql, params):
        if 'INSERT INTO Estadistica' in sql:
            raise RuntimeError('write failed')
    cursor.execute.side_effect = execute
    with pytest.raises(RuntimeError):
        client.patch('/tareas/8/completar', headers={'Authorization': 'Bearer 42'})
    connection.commit.assert_not_called()
    connection.rollback.assert_called_once()
