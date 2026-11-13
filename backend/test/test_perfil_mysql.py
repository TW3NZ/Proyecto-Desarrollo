"""Opt-in integration test: all fixture data is rolled back, including on failure."""
import os
import secrets
import pytest
from backend.database.db import get_connection
from backend.database import perfil
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
            assert perfil.estadisticas(cursor, user)['inteligencia'] == 0
            for _ in range(2):
                cursor.execute('UPDATE Tarea SET completada=TRUE WHERE idTarea=%s', (user,))
                result = perfil.estadisticas(cursor, user)
                assert result['inteligencia'] == pytest.approx(1.6667)
                assert result['disciplina'] == 0
            cursor.execute('SELECT inteligencia FROM Estadistica WHERE idUsu=%s', (user,))
            assert float(cursor.fetchone()['inteligencia']) == pytest.approx(1.6667)
            assert perfil.estadisticas(cursor, other)['inteligencia'] == 0
    finally:
        connection.rollback()
        connection.close()
