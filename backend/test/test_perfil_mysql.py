"""Opt-in integration test: all fixture data is rolled back, including on failure."""
import os
import secrets
from datetime import timedelta
from backend.core.puntuacion import hoy_bogota
import pytest
from backend.database.db import get_connection
from backend.database import perfil, puntuacion
from backend.models.perfil import AvatarConfig
from backend.utils.settings import load_settings


@pytest.mark.skipif(os.environ.get('RUN_MYSQL_TESTS') != '1', reason='Requires migrated MySQL and explicit opt-in')
def test_real_mysql_roundtrip_isolation_and_idempotent_scores():
    load_settings()
    connection = get_connection()
    try:
        with connection.cursor() as cursor:
            # Negative IDs only inside this rolled-back test transaction.
            user = -secrets.randbelow(1_000_000_000) - 1
            other = user - 1
            for uid in (user, other):
                cursor.execute('''INSERT INTO Usuario
                    (idUsu,email,nameUsu,lastName,nickName,passwordUsu,createDate,genero)
                    VALUES (%s,%s,'Test','Rollback',%s,'unused',CURRENT_DATE,'Hombre')''',
                    (uid, f'{uid}@rollback.invalid', f'rollback-{uid}'))
            perfil.lock_usuario(cursor, user)
            config = AvatarConfig(hairstyle='recogido', eyeColor='#123456', bodyHeight=0.8)
            perfil.guardar_config(cursor, user, 'avatar', config)
            assert perfil.leer_config(cursor, user, 'avatar') == config
            assert perfil.leer_config(cursor, other, 'avatar') == AvatarConfig()
            cursor.execute('''INSERT INTO Tarea (idTarea,idUsu,titulo,prioridad,fecha,completada)
                              VALUES (%s,%s,'Rollback','Baja',CURRENT_DATE,FALSE)''', (user,user))
            for category in (1, 2, 3):
                cursor.execute('INSERT INTO TareaCategoria (idTarea,idCategoria) VALUES (%s,%s)', (user,category))
            assert perfil.estadisticas(cursor, user)['inteligencia'] == 100
            cursor.execute('UPDATE Estadistica SET inteligencia=0,finanzas=0,salud=0 WHERE idUsu=%s', (user,))
            task = {'idTarea': user, 'prioridad': 'Baja', 'idProyecto': None, 'completada': False}
            puntuacion.recompensar(cursor, user, task)
            cursor.execute('UPDATE Tarea SET completada=TRUE WHERE idTarea=%s', (user,))
            # Repeated requests and reads do not replay rewards.
            task['completada'] = True
            puntuacion.recompensar(cursor, user, task)
            for _ in range(2):
                result = perfil.estadisticas(cursor, user)
                assert result['inteligencia'] == 8
                assert result['disciplina'] == 100
            assert perfil.estadisticas(cursor, other)['inteligencia'] == 100

            # Only yesterday's deadline is expired; today and NULL are exempt.
            for index, deadline in enumerate((hoy_bogota()-timedelta(days=1), hoy_bogota(), None), 2):
                tid = user-index
                cursor.execute("""INSERT INTO Tarea (idTarea,idUsu,titulo,prioridad,fecha,fechaFinalizacion,completada)
                    VALUES (%s,%s,'Rollback','Media',CURRENT_DATE,%s,FALSE)""", (tid,other,deadline))
                cursor.execute('INSERT INTO TareaCategoria (idTarea,idCategoria) VALUES (%s,1)', (tid,))
            perfil.lock_usuario(cursor, other)
            assert perfil.estadisticas(cursor, other)['inteligencia'] == 90
            assert perfil.estadisticas(cursor, other)['inteligencia'] == 90
            cursor.execute('SELECT COUNT(*) AS n FROM EventoPuntuacion WHERE idUsu=%s', (other,))
            assert cursor.fetchone()['n'] == 1
            overdue = {'idTarea': user-2, 'prioridad': 'Media', 'idProyecto': None, 'completada': False}
            puntuacion.recompensar(cursor, other, overdue)  # 30 / 3 = 10
            cursor.execute('UPDATE Tarea SET completada=TRUE WHERE idTarea=%s', (user-2,))
            assert perfil.estadisticas(cursor, other)['inteligencia'] == 100
            cursor.execute("SELECT pendientes FROM EventoPuntuacion WHERE idTarea=%s AND tipo='completada'", (user-2,))
            assert cursor.fetchone()['pendientes'] == 3
    finally:
        connection.rollback()
        connection.close()
