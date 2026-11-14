"""Atomic score updates. Caller must hold the Usuario row lock and transaction."""
import json
from decimal import Decimal
from backend.core.puntuacion import CAMPOS, hoy_bogota, limitar, puntos


def inicializar(cursor, usuario_id):
    cursor.execute('''INSERT INTO Estadistica
        (idUsu, inteligencia, finanzas, salud, disciplina) VALUES (%s,100,100,100,100)
        ON DUPLICATE KEY UPDATE idUsu=idUsu''', (usuario_id,))


def valores(cursor, usuario_id):
    cursor.execute('SELECT inteligencia, finanzas, salud, disciplina FROM Estadistica WHERE idUsu=%s FOR UPDATE', (usuario_id,))
    return {key: Decimal(str(value)) for key, value in cursor.fetchone().items()}


def categorias(cursor, tarea_id):
    cursor.execute('SELECT idCategoria FROM TareaCategoria WHERE idTarea=%s', (tarea_id,))
    return [row['idCategoria'] for row in cursor.fetchall()]


def aplicar(cursor, usuario_id, tarea, tipo, pendientes, fecha):
    cursor.execute('SELECT idTarea FROM EventoPuntuacion WHERE idTarea=%s AND tipo=%s AND idUsu=%s', (tarea['idTarea'], tipo, usuario_id))
    if cursor.fetchone() is not None:
        return  # Neither repeated reads nor retries can apply the event twice.
    delta = puntos(tarea['prioridad'], pendientes, categorias(cursor, tarea['idTarea']), vencida=tipo == 'vencimiento')
    antes = valores(cursor, usuario_id)
    despues = {key: limitar(value + delta.get(key, Decimal(0))) for key, value in antes.items()}
    aplicado = {key: str(despues[key] - antes[key]) for key in antes}
    cursor.execute('''INSERT INTO EventoPuntuacion
        (idTarea, tipo, idUsu, fecha, pendientes, delta, versionRegla)
        VALUES (%s,%s,%s,%s,%s,%s,2)''',
        (tarea['idTarea'], tipo, usuario_id, fecha, pendientes, json.dumps(aplicado)))
    cursor.execute('''UPDATE Estadistica SET inteligencia=%s,finanzas=%s,salud=%s,disciplina=%s
                      WHERE idUsu=%s''', (*[despues[key] for key in CAMPOS.values()], usuario_id))


def sincronizar(cursor, usuario_id, hoy=None):
    hoy = hoy or hoy_bogota()
    inicializar(cursor, usuario_id)
    # A DATE deadline remains valid for its entire calendar day in Colombia.
    cursor.execute('''SELECT t.idTarea, t.prioridad FROM Tarea t
        WHERE t.completada=FALSE AND (
          (t.idUsu=%s AND t.idProyecto IS NULL) OR
          (t.idProyecto IS NOT NULL AND EXISTS (
            SELECT 1 FROM ParticipanteTarea pt
            JOIN MiembroProyecto mp ON mp.idMiembroProyecto=pt.idMiembroProyecto
            JOIN MiembroEquipo me ON me.idMiembro=mp.idMiembro
            WHERE pt.idTarea=t.idTarea AND me.idUsu=%s AND pt.completada=FALSE)))
          AND t.fechaFinalizacion < %s
          AND NOT EXISTS (SELECT 1 FROM EventoPuntuacion e
                         WHERE e.idTarea=t.idTarea AND e.idUsu=%s AND e.tipo='vencimiento')
        ORDER BY t.fechaFinalizacion,t.idTarea''', (usuario_id, usuario_id, hoy, usuario_id))
    vencidas = cursor.fetchall()
    for tarea in vencidas:
        aplicar(cursor, usuario_id, tarea, 'vencimiento', 1, hoy)
    return valores(cursor, usuario_id)


def recompensar(cursor, usuario_id, tarea):
    # Called BEFORE marking the task complete, so N includes this task.
    if tarea['completada'] or tarea['idProyecto'] is not None:
        return
    cursor.execute('''SELECT COUNT(*) AS total FROM Tarea
                      WHERE idUsu=%s AND completada=FALSE AND idProyecto IS NULL''', (usuario_id,))
    pendientes = cursor.fetchone()['total']
    aplicar(cursor, usuario_id, tarea, 'completada', pendientes, hoy_bogota())
