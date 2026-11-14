"""Integration against migrated MySQL; all fixture data is rolled back."""
import os
import secrets
from datetime import timedelta
import pytest
from fastapi import HTTPException
from pymysql.err import IntegrityError
from backend.database.db import get_connection
from backend.database import equipos, perfil, puntuacion
from backend.models.equipos import CrearEquipo, AsignarTarea
from backend.utils.settings import load_settings
from backend.core.puntuacion import hoy_bogota


@pytest.mark.skipif(os.environ.get('RUN_MYSQL_TESTS') != '1', reason='Requires migrated MySQL')
def test_teams_membership_completion_and_full_rewards():
    load_settings()
    connection = get_connection()
    try:
        with connection.cursor() as c:
            c.execute('SET TRANSACTION ISOLATION LEVEL READ COMMITTED')
            leader = -secrets.randbelow(900000000)-10
            member, outsider = leader-1,leader-2
            for uid in (leader,member,outsider):
                c.execute('''INSERT INTO Usuario
                  (idUsu,email,nameUsu,lastName,nickName,passwordUsu,createDate,genero)
                  VALUES (%s,%s,'Test','Rollback',%s,'unused',CURRENT_DATE,'Hombre')''',
                  (uid,f'{uid}@rollback.invalid',f'rollback-{uid}'))
                puntuacion.inicializar(c,uid)
                c.execute('UPDATE Estadistica SET inteligencia=0,finanzas=0 WHERE idUsu=%s',(uid,))
            team = equipos.crear(c,leader,CrearEquipo(nombre='Rollback team'))
            tid = team['idEquipo']
            assert equipos.unirse(c,member,team['codigo'])['idEquipo'] == tid
            equipos.unirse(c,member,team['codigo'])
            detail = equipos.detalle(c,tid,leader)
            assert len(detail['miembros']) == 2
            assert equipos.detalle(c,tid,member)['codigo'] is None
            project = detail['proyectos'][0]['idProyecto']
            for actor in (member,outsider):
                with pytest.raises(HTTPException) as e:
                    equipos.asignar(c,tid,project,actor,AsignarTarea(titulo='No',categorias=[1],participantes=[leader]))
                assert e.value.status_code == 403
            with pytest.raises(HTTPException) as e:
                equipos.asignar(c,tid,project,leader,AsignarTarea(titulo='No',categorias=[1],participantes=[outsider]))
            assert e.value.status_code == 422
            task = equipos.asignar(c,tid,project,leader,AsignarTarea(
                titulo='Shared',categorias=[1,2],participantes=[leader,member]))['idTarea']
            assert len(equipos.detalle(c,tid,member)['tareas']) == 1
            first = equipos.completar_parte(c,tid,task,leader)
            assert first['completada'] is False
            assert first['estadisticas']['inteligencia'] == 0
            assert equipos.completar_parte(c,tid,task,leader)['completada'] is False
            # A member of the team who is not assigned cannot mark another part.
            equipos.unirse(c,outsider,team['codigo'])
            with pytest.raises(HTTPException) as e:
                equipos.completar_parte(c,tid,task,outsider)
            assert e.value.status_code == 403
            c.execute('SAVEPOINT before_finish')
            assert equipos.completar_parte(c,tid,task,member)['completada'] is True
            c.execute('ROLLBACK TO SAVEPOINT before_finish')
            assert not equipos.detalle(c,tid,leader)['tareas'][0]['completada']
            assert perfil.estadisticas(c,leader)['inteligencia'] == 0
            assert equipos.completar_parte(c,tid,task,member)['completada'] is True
            for uid in (leader,member):
                for _ in range(2):
                    result = equipos.completar_parte(c,tid,task,uid)
                    assert result['estadisticas']['inteligencia'] == 15
                    assert result['estadisticas']['finanzas'] == 15
            assert perfil.estadisticas(c,outsider)['inteligencia'] == 0
            c.execute('SELECT COUNT(*) AS n FROM EventoPuntuacion WHERE idTarea=%s',(task,))
            assert c.fetchone()['n'] == 2
            # Deadline penalties affect only unfinished contributions, once.
            overdue = equipos.asignar(c,tid,project,leader,AsignarTarea(
                titulo='Deadline',categorias=[1],participantes=[leader,member],
                fechaLimite=hoy_bogota()))['idTarea']
            equipos.completar_parte(c,tid,overdue,leader)
            c.execute('UPDATE Tarea SET fechaFinalizacion=%s WHERE idTarea=%s',
                (hoy_bogota()-timedelta(days=1),overdue))
            assert perfil.estadisticas(c,leader)['inteligencia'] == 15
            assert perfil.estadisticas(c,member)['inteligencia'] == 5
            assert perfil.estadisticas(c,member)['inteligencia'] == 5
            assert equipos.completar_parte(c,tid,overdue,member)['estadisticas']['inteligencia'] == 35
            assert perfil.estadisticas(c,leader)['inteligencia'] == 45
            # Composite SQL keys reject membership from a different team.
            other = equipos.crear(c,outsider,CrearEquipo(nombre='Other rollback'))['idEquipo']
            c.execute('SELECT idMiembro FROM MiembroEquipo WHERE idEquipo=%s AND idUsu=%s',(other,outsider))
            foreign_member = c.fetchone()['idMiembro']
            with pytest.raises(IntegrityError):
                c.execute("INSERT INTO MiembroProyecto (idProyecto,idEquipo,idMiembro,rol) VALUES (%s,%s,%s,'Miembro')",
                    (project,tid,foreign_member))
            foreign_project = equipos.detalle(c,other,outsider)['proyectos'][0]['idProyecto']
            other_task = equipos.asignar(c,other,foreign_project,outsider,AsignarTarea(
                titulo='Other',categorias=[1],participantes=[outsider]))['idTarea']
            c.execute('SELECT idMiembroProyecto FROM ParticipanteTarea WHERE idTarea=%s',(other_task,))
            foreign_part = c.fetchone()['idMiembroProyecto']
            with pytest.raises(IntegrityError):
                c.execute('INSERT INTO ParticipanteTarea (idTarea,idProyecto,idMiembroProyecto) VALUES (%s,%s,%s)',
                    (task,project,foreign_part))
    finally:
        connection.rollback()
        connection.close()
