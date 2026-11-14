"""Team persistence and authorization. HTTP entry points remain in app.py."""
import secrets
from fastapi import HTTPException
from pymysql.err import IntegrityError
from backend.core.puntuacion import hoy_bogota

ALFABETO = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'


def nuevo_codigo():
    return ''.join(secrets.choice(ALFABETO) for _ in range(8))


def nuevo_id():
    return secrets.randbelow(900000000) + 100000000


def exigir_miembro(cursor, equipo_id, usuario_id, lider=False):
    # Serialize membership and task operations inside a team.
    cursor.execute('SELECT * FROM Equipo WHERE idEquipo=%s FOR UPDATE', (equipo_id,))
    equipo = cursor.fetchone()
    if not equipo:
        raise HTTPException(404, 'Equipo no encontrado.')
    cursor.execute('SELECT idMiembro FROM MiembroEquipo WHERE idEquipo=%s AND idUsu=%s', (equipo_id, usuario_id))
    if cursor.fetchone() is None:
        raise HTTPException(403, 'No perteneces a este equipo.')
    if lider and equipo['idCreador'] != usuario_id:
        raise HTTPException(403, 'Solo el lider puede asignar tareas y crear proyectos.')
    return equipo


def crear_proyecto(cursor, equipo_id, usuario_id, data):
    exigir_miembro(cursor, equipo_id, usuario_id, lider=True)
    project_id = nuevo_id()
    cursor.execute('''INSERT INTO Proyecto (idProyecto,idEquipo,idCategoria,nombre,meta,fechaInicio)
                      VALUES (%s,%s,%s,%s,%s,%s)''',
                   (project_id,equipo_id,data.categoria,data.nombre,data.meta,hoy_bogota()))
    return {'idProyecto': project_id}


def crear(cursor, usuario_id, data):
    equipo_id = nuevo_id()
    initials = ''.join(word[0] for word in data.nombre.split()[:2]).upper()[:2]
    cursor.execute('INSERT INTO Equipo (idEquipo,nameEquipo,siglasEquipo,idCreador) VALUES (%s,%s,%s,%s)',
                   (equipo_id,data.nombre,initials,usuario_id))
    cursor.execute('INSERT INTO MiembroEquipo (idEquipo,idUsu) VALUES (%s,%s)', (equipo_id,usuario_id))
    for _ in range(10):
        codigo = nuevo_codigo()
        try:
            cursor.execute('INSERT INTO EquipoInvitacion (idEquipo,codigo) VALUES (%s,%s)', (equipo_id,codigo))
            break
        except IntegrityError as error:
            if error.args[0] != 1062:
                raise
    else:
        raise HTTPException(503, 'No se pudo generar el codigo. Intentalo de nuevo.')
    from backend.models.equipos import CrearProyecto
    crear_proyecto(cursor,equipo_id,usuario_id,CrearProyecto(nombre='General'))
    return {'idEquipo': equipo_id, 'codigo': codigo}


def unirse(cursor, usuario_id, codigo):
    cursor.execute('SELECT idEquipo FROM EquipoInvitacion WHERE codigo=%s', (codigo,))
    row = cursor.fetchone()
    if row is None:
        raise HTTPException(404, 'Codigo de invitacion no valido.')
    equipo_id = row['idEquipo']
    cursor.execute('SELECT idEquipo FROM Equipo WHERE idEquipo=%s FOR UPDATE', (equipo_id,))
    cursor.execute('''INSERT INTO MiembroEquipo (idEquipo,idUsu) VALUES (%s,%s)
                      ON DUPLICATE KEY UPDATE idUsu=idUsu''', (equipo_id, usuario_id))
    return {'idEquipo': equipo_id}


def listar(cursor, usuario_id):
    cursor.execute('''SELECT e.idEquipo,e.nameEquipo AS nombre,e.siglasEquipo AS siglas,e.idCreador
        FROM Equipo e JOIN MiembroEquipo m ON m.idEquipo=e.idEquipo WHERE m.idUsu=%s ORDER BY e.nameEquipo''', (usuario_id,))
    return cursor.fetchall()


def detalle(cursor, equipo_id, usuario_id):
    equipo = exigir_miembro(cursor,equipo_id,usuario_id)
    cursor.execute('''SELECT u.idUsu,u.nickName,u.nameUsu,u.lastName FROM Usuario u
                      JOIN MiembroEquipo m ON m.idUsu=u.idUsu WHERE m.idEquipo=%s ORDER BY u.nickName''', (equipo_id,))
    miembros = cursor.fetchall()
    cursor.execute('SELECT idProyecto,nombre,meta FROM Proyecto WHERE idEquipo=%s ORDER BY fechaInicio,idProyecto', (equipo_id,))
    proyectos = cursor.fetchall()
    codigo = None
    if equipo['idCreador'] == usuario_id:
        cursor.execute('SELECT codigo FROM EquipoInvitacion WHERE idEquipo=%s', (equipo_id,))
        invite = cursor.fetchone()
        codigo = invite['codigo'] if invite else None
    cursor.execute('''SELECT t.idTarea,t.idProyecto,t.titulo,t.descripcion,t.prioridad,t.fechaFinalizacion,t.completada
        FROM Tarea t JOIN Proyecto p ON p.idProyecto=t.idProyecto WHERE p.idEquipo=%s ORDER BY t.idTarea DESC''', (equipo_id,))
    tareas = cursor.fetchall()
    for tarea in tareas:
        cursor.execute('''SELECT me.idUsu,u.nickName,pt.completada FROM ParticipanteTarea pt
            JOIN MiembroProyecto mp ON mp.idMiembroProyecto=pt.idMiembroProyecto
            JOIN MiembroEquipo me ON me.idMiembro=mp.idMiembro JOIN Usuario u ON u.idUsu=me.idUsu
            WHERE pt.idTarea=%s ORDER BY me.idUsu''', (tarea['idTarea'],))
        tarea['participantes'] = cursor.fetchall()
        cursor.execute('SELECT idCategoria FROM TareaCategoria WHERE idTarea=%s', (tarea['idTarea'],))
        tarea['categorias'] = [row['idCategoria'] for row in cursor.fetchall()]
    if equipo['idCreador'] != usuario_id:
        cursor.execute('''SELECT mp.idProyecto FROM MiembroProyecto mp
            JOIN MiembroEquipo me ON me.idMiembro=mp.idMiembro WHERE me.idEquipo=%s AND me.idUsu=%s''', (equipo_id,usuario_id))
        permitidos = {row['idProyecto'] for row in cursor.fetchall()}
        proyectos = [p for p in proyectos if p['idProyecto'] in permitidos]
        tareas = [t for t in tareas if t['idProyecto'] in permitidos]
    return {'idEquipo':equipo_id,'nombre':equipo['nameEquipo'],'idCreador':equipo['idCreador'],
            'codigo':codigo,'miembros':miembros,'proyectos':proyectos,'tareas':tareas}


def asignar(cursor, equipo_id, proyecto_id, usuario_id, data):
    exigir_miembro(cursor,equipo_id,usuario_id,lider=True)
    cursor.execute('SELECT idProyecto FROM Proyecto WHERE idProyecto=%s AND idEquipo=%s', (proyecto_id,equipo_id))
    if not cursor.fetchone():
        raise HTTPException(404, 'Proyecto no encontrado en este equipo.')
    miembros = []
    for uid in sorted(data.participantes):
        cursor.execute('SELECT idMiembro FROM MiembroEquipo WHERE idEquipo=%s AND idUsu=%s', (equipo_id,uid))
        member = cursor.fetchone()
        if not member:
            raise HTTPException(422, 'Todos los asignados deben pertenecer al equipo.')
        cursor.execute('''INSERT INTO MiembroProyecto (idProyecto,idMiembro,idEquipo,rol) VALUES (%s,%s,%s,'Miembro')
                          ON DUPLICATE KEY UPDATE idMiembro=idMiembro''', (proyecto_id,member['idMiembro'],equipo_id))
        cursor.execute('SELECT idMiembroProyecto FROM MiembroProyecto WHERE idProyecto=%s AND idMiembro=%s', (proyecto_id,member['idMiembro']))
        miembros.append(cursor.fetchone()['idMiembroProyecto'])
    tid = nuevo_id()
    cursor.execute('''INSERT INTO Tarea (idTarea,idUsu,idProyecto,titulo,descripcion,prioridad,fecha,fechaFinalizacion)
                      VALUES (%s,%s,%s,%s,%s,%s,%s,%s)''',
                   (tid,usuario_id,proyecto_id,data.titulo,data.descripcion,data.prioridad,hoy_bogota(),data.fechaLimite))
    for category in data.categorias:
        cursor.execute('INSERT INTO TareaCategoria (idTarea,idCategoria) VALUES (%s,%s)', (tid,category))
    for member in miembros:
        cursor.execute('INSERT INTO ParticipanteTarea (idTarea,idProyecto,idMiembroProyecto) VALUES (%s,%s,%s)', (tid,proyecto_id,member))
    return {'idTarea':tid}


def completar_parte(cursor, equipo_id, tarea_id, usuario_id):
    from backend.database import perfil, puntuacion
    exigir_miembro(cursor,equipo_id,usuario_id)
    cursor.execute('''SELECT t.idTarea,t.idProyecto,t.prioridad,t.completada FROM Tarea t
        JOIN Proyecto p ON p.idProyecto=t.idProyecto WHERE t.idTarea=%s AND p.idEquipo=%s''', (tarea_id,equipo_id))
    tarea = cursor.fetchone()
    if not tarea:
        raise HTTPException(404, 'Tarea no encontrada.')
    cursor.execute('''SELECT pt.idMiembroProyecto,pt.completada,me.idUsu FROM ParticipanteTarea pt
        JOIN MiembroProyecto mp ON mp.idMiembroProyecto=pt.idMiembroProyecto
        JOIN MiembroEquipo me ON me.idMiembro=mp.idMiembro WHERE pt.idTarea=%s ORDER BY me.idUsu''', (tarea_id,))
    asignados = cursor.fetchall()
    propio = next((p for p in asignados if p['idUsu'] == usuario_id), None)
    if propio is None:
        raise HTTPException(403, 'Solo puedes completar tu parte de una tarea asignada.')
    # Global ascending user lock order prevents cross-team reward deadlocks.
    for participante in asignados:
        perfil.lock_usuario(cursor, participante['idUsu'])
    # Apply overdue penalties before marking a late contribution as finished.
    for participante in asignados:
        puntuacion.sincronizar(cursor, participante['idUsu'])
    if not tarea['completada']:
        cursor.execute('''UPDATE ParticipanteTarea SET completada=TRUE,completadaEn=UTC_TIMESTAMP()
            WHERE idTarea=%s AND idMiembroProyecto=%s AND completada=FALSE''', (tarea_id,propio['idMiembroProyecto']))
        terminada = all(p['completada'] or p['idUsu'] == usuario_id for p in asignados)
        if terminada:
            cursor.execute('SELECT COUNT(*) AS total FROM Tarea WHERE idProyecto=%s AND completada=FALSE', (tarea['idProyecto'],))
            pendientes = cursor.fetchone()['total']
            for participante in asignados:
                uid = participante['idUsu']
                puntuacion.aplicar(cursor,uid,tarea,'completada',pendientes,hoy_bogota())
            cursor.execute('UPDATE Tarea SET completada=TRUE WHERE idTarea=%s', (tarea_id,))
            tarea['completada'] = True
    return {'completada': bool(tarea['completada']), 'miParteCompletada': True,
            'estadisticas': perfil.estadisticas(cursor,usuario_id)}
