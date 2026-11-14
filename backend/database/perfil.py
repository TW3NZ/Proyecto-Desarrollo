"""Queries only; callers own the transaction and authenticated user ID."""
import json
from fastapi import HTTPException
from backend.models.perfil import AvatarConfig, PreferenciasEstadisticas
from backend.database import puntuacion


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
    return {key: float(value) for key, value in puntuacion.sincronizar(cursor, usuario_id).items()}


def estadisticas(cursor, usuario_id):
    values = actualizar_estadisticas(cursor, usuario_id)
    return {'usuarioId': usuario_id, **values,
            **leer_config(cursor, usuario_id, 'preferencias').model_dump()}
