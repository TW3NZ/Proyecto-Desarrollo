"""Queries only; callers own the transaction and authenticated user ID."""
import json
from fastapi import HTTPException
from backend.models.perfil import AvatarConfig, PreferenciasEstadisticas


def lock_usuario(cursor, usuario_id):
    # Serialize all score mutations for an account, including concurrent tasks.
    cursor.execute('SELECT idUsu FROM Usuario WHERE idUsu = %s FOR UPDATE', (usuario_id,))
    if cursor.fetchone() is None:
        raise HTTPException(401, 'La cuenta ya no existe.')


def leer_config(cursor, usuario_id, campo):
    assert campo in ('avatar', 'preferencias')
    cursor.execute(f'SELECT {campo} FROM PerfilUsuario WHERE idUsu = %s', (usuario_id,))
    row = cursor.fetchone()
    model = AvatarConfig if campo == 'avatar' else PreferenciasEstadisticas
    return model.model_validate(json.loads(row[campo])) if row and row[campo] else model()


def guardar_config(cursor, usuario_id, campo, value):
    assert campo in ('avatar', 'preferencias')
    cursor.execute(
        f'INSERT INTO PerfilUsuario (idUsu, {campo}) VALUES (%s, %s) '
        f'ON DUPLICATE KEY UPDATE {campo} = %s',
        (usuario_id, value.model_dump_json(), value.model_dump_json()),
    )


def actualizar_estadisticas(cursor, usuario_id):
    # Personal task history is the source of points. Recalculation is idempotent
    # and recovers tasks completed before server-side statistics were introduced.
    cursor.execute('''
        SELECT tc.idCategoria,
               LEAST(100, SUM(CASE t.prioridad WHEN 'Baja' THEN 5
                    WHEN 'Media' THEN 10 WHEN 'Alta' THEN 15 ELSE 0 END / n.total)) AS puntos
        FROM Tarea t JOIN TareaCategoria tc ON tc.idTarea = t.idTarea
        JOIN (SELECT idTarea, COUNT(*) AS total FROM TareaCategoria GROUP BY idTarea) n
          ON n.idTarea = t.idTarea
        WHERE t.idUsu = %s AND t.completada = TRUE AND t.idProyecto IS NULL
        GROUP BY tc.idCategoria
    ''', (usuario_id,))
    scores = {row['idCategoria']: float(row['puntos']) for row in cursor.fetchall()}
    values = [round(scores.get(i, 0), 4) for i in (1, 2, 3, 4)]
    cursor.execute('''
        INSERT INTO Estadistica (idUsu, inteligencia, finanzas, salud, disciplina)
        VALUES (%s, %s, %s, %s, %s)
        ON DUPLICATE KEY UPDATE inteligencia=%s, finanzas=%s, salud=%s, disciplina=%s
    ''', (usuario_id, *values, *values))
    return dict(zip(('inteligencia', 'finanzas', 'salud', 'disciplina'), values))


def estadisticas(cursor, usuario_id):
    values = actualizar_estadisticas(cursor, usuario_id)
    return {'usuarioId': usuario_id, **values,
            **leer_config(cursor, usuario_id, 'preferencias').model_dump()}
