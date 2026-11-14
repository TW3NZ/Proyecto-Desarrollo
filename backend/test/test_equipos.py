from unittest.mock import MagicMock
import pytest
from fastapi.testclient import TestClient
from fastapi import HTTPException
from backend import app as api
from backend.database import equipos
from backend.models.equipos import UnirseEquipo, AsignarTarea


@pytest.fixture
def client(monkeypatch):
    connection = MagicMock()
    monkeypatch.setattr(api, 'get_connection', lambda: connection)
    monkeypatch.setattr(api, 'verificar_token', lambda token: {'sub':'42'})
    return TestClient(api.app), connection


@pytest.mark.parametrize('method,path,body', [
    ('get','/equipos',None), ('post','/equipos',{'nombre':'Team'}),
    ('post','/equipos/unirse',{'codigo':'ABCDEFGH'}), ('get','/equipos/1',None),
    ('post','/equipos/1/proyectos',{'nombre':'P'}),
    ('post','/equipos/1/proyectos/1/tareas',{'titulo':'T','categorias':[1],'participantes':[42]}),
    ('patch','/equipos/1/tareas/1/mi-parte',None),
])
def test_all_routes_require_jwt(client, method, path, body):
    http, connection = client
    assert http.request(method,path,json=body).status_code == 401
    connection.cursor.assert_not_called()


def test_actor_only_from_jwt_and_rollback(client, monkeypatch):
    http, connection = client
    create = MagicMock(return_value={'idEquipo':7})
    monkeypatch.setattr(equipos,'crear',create)
    headers={'Authorization':'Bearer example'}
    assert http.post('/equipos',headers=headers,json={'nombre':'Team','idUsu':999}).status_code == 422
    assert http.post('/equipos',headers=headers,json={'nombre':'Team'}).status_code == 201
    assert create.call_args.args[1] == 42
    connection.commit.assert_called_once()
    create.side_effect = RuntimeError('database failure')
    with pytest.raises(RuntimeError):
        http.post('/equipos',headers=headers,json={'nombre':'Team'})
    connection.rollback.assert_called_once()


def test_codes_and_empty_assignment_validation():
    assert UnirseEquipo(codigo=' abcd2345 ').codigo == 'ABCD2345'
    assert len(equipos.nuevo_codigo()) == 8
    with pytest.raises(ValueError):
        AsignarTarea(titulo='T',categorias=[1],participantes=[])


def test_nonleader_cannot_assign():
    cursor = MagicMock()
    cursor.fetchone.side_effect = [{'idCreador':1},{'idMiembro':2}]
    with pytest.raises(HTTPException) as error:
        equipos.exigir_miembro(cursor,1,2,lider=True)
    assert error.value.status_code == 403
