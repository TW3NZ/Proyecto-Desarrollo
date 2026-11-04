import 'package:flutter/material.dart';

import '../data/team_trabajo_store.dart';
import '../models/actividad_team.dart';
import '../models/equipo_modelo.dart';
import '../theme.dart';
import '../widgets/common/cabecera_app.dart';

/// Dashboard de trabajo y supervisión de un equipo.
class DentroTeamScreen extends StatefulWidget {
  const DentroTeamScreen({super.key, required this.equipo, this.usuarioId});

  final Equipo equipo;

  /// Permite que la navegación de una sesión real indique el miembro actual.
  /// Por defecto se abre como creador para los Teams recién creados.
  final String? usuarioId;

  @override
  State<DentroTeamScreen> createState() => _DentroTeamScreenState();
}

class _DentroTeamScreenState extends State<DentroTeamScreen> {
  final _store = TeamTrabajoStore.instancia;
  String? _miembroFiltrado;

  Equipo get equipo => widget.equipo;
  List<TareaTeam> get tareas => _store.tareas(equipo);
  List<MiembroEquipo> get miembros => equipo.miembros.isNotEmpty
      ? equipo.miembros
      : equipo.integrantes
            .map(
              (id) => MiembroEquipo(
                id: id,
                nombre: id,
                rol: id == equipo.creadorId
                    ? RolEquipo.creador
                    : RolEquipo.integrante,
              ),
            )
            .toList();
  MiembroEquipo get usuario {
    final id = widget.usuarioId ?? equipo.creadorId;
    return miembros.firstWhere(
      (m) => m.id == id,
      orElse: () =>
          MiembroEquipo(id: id, nombre: id, rol: RolEquipo.integrante),
    );
  }

  bool get esAdmin => PermisosEquipo.puedeGestionarProyecto(usuario);
  List<ActividadTeam> get actividades => _store.actividades(equipo).where((a) {
    if (!esAdmin && a.integranteId != usuario.id) return false;
    if (_miembroFiltrado != null && a.integranteId != _miembroFiltrado) {
      return false;
    }
    return true;
  }).toList();

  @override
  void initState() {
    super.initState();
    _store.addListener(_actualizar);
  }

  @override
  void dispose() {
    _store.removeListener(_actualizar);
    super.dispose();
  }

  void _actualizar() {
    if (mounted) setState(() {});
  }

  String _nombreMiembro(String id) =>
      miembros.where((m) => m.id == id).map((m) => m.nombre).firstOrNull ?? id;

  String _fecha(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _editarTarea([TareaTeam? existente]) async {
    final titulo = TextEditingController(text: existente?.titulo ?? '');
    final descripcion = TextEditingController(
      text: existente?.descripcion ?? '',
    );
    String responsable =
        existente?.responsableId ?? (miembros.isEmpty ? '' : miembros.first.id);
    DateTime inicio = existente?.fechaInicio ?? DateTime.now();
    DateTime entrega =
        existente?.fechaEntrega ?? inicio.add(const Duration(days: 7));
    final activasActuales = tareas
        .where((t) => !t.archivada && t.id != existente?.id)
        .length;
    double peso =
        existente?.peso ??
        (activasActuales == 0 ? 100 : 100 / (activasActuales + 1));
    final resultado = await showDialog<TareaTeam>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, dialogSet) => AlertDialog(
            title: Text(existente == null ? 'Agregar tarea' : 'Editar tarea'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titulo,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la tarea',
                    ),
                  ),
                  TextField(
                    controller: descripcion,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Descripción'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: responsable.isEmpty ? null : responsable,
                    decoration: const InputDecoration(
                      labelText: 'Integrante responsable',
                    ),
                    items: [
                      for (final m in miembros)
                        DropdownMenuItem(value: m.id, child: Text(m.nombre)),
                    ],
                    onChanged: (v) {
                      if (v != null) dialogSet(() => responsable = v);
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _fechaBoton('Inicio', inicio, () async {
                          final v = await _fechaPicker(inicio);
                          if (v != null) {
                            dialogSet(() {
                              inicio = v;
                              if (entrega.isBefore(v)) entrega = v;
                            });
                          }
                        }),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _fechaBoton('Entrega', entrega, () async {
                          final v = await _fechaPicker(entrega);
                          if (v != null) {
                            dialogSet(() {
                              entrega = v;
                              if (inicio.isAfter(v)) inicio = v;
                            });
                          }
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Peso'),
                      Expanded(
                        child: Slider(
                          value: peso.clamp(0, 100).toDouble(),
                          min: 0,
                          max: 100,
                          divisions: 20,
                          label: '${peso.round()}%',
                          onChanged: (v) => dialogSet(() => peso = v),
                        ),
                      ),
                      Text('${peso.round()}%'),
                    ],
                  ),
                  const Text(
                    'Los pesos se redistribuyen proporcionalmente para sumar 100%.',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  if (titulo.text.trim().isEmpty || responsable.isEmpty) return;
                  Navigator.pop(
                    dialogContext,
                    TareaTeam(
                      id:
                          existente?.id ??
                          '${equipo.id}-${DateTime.now().microsecondsSinceEpoch}',
                      titulo: titulo.text.trim(),
                      descripcion: descripcion.text.trim(),
                      responsableId: responsable,
                      fechaInicio: inicio,
                      fechaEntrega: entrega,
                      peso: peso,
                      progreso: existente?.progreso ?? 0,
                    ),
                  );
                },
                child: const Text('Guardar'),
              ),
            ],
          ),
        );
      },
    );
    titulo.dispose();
    descripcion.dispose();
    if (resultado != null) _store.guardarTarea(equipo, resultado);
  }

  Future<DateTime?> _fechaPicker(DateTime fecha) => showDatePicker(
    context: context,
    initialDate: fecha,
    firstDate: DateTime(2020),
    lastDate: DateTime(2100),
  );

  Widget _fechaBoton(String titulo, DateTime fecha, VoidCallback onTap) =>
      OutlinedButton(
        onPressed: onTap,
        child: Text('$titulo\n${_fecha(fecha)}', textAlign: TextAlign.center),
      );

  Future<void> _detalleTarea(TareaTeam tarea) async {
    final editable = esAdmin || tarea.responsableId == usuario.id;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DetalleTareaSheet(
        equipo: equipo,
        tarea: tarea,
        editable: editable,
        miembroActualId: usuario.id,
        nombreResponsable: _nombreMiembro(tarea.responsableId),
        fecha: _fecha,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activas = tareas.where((t) => !t.archivada).toList();
    final completos = activas.where((t) => t.progreso == 100).length;
    final enCurso = activas
        .where((t) => t.progreso > 0 && t.progreso < 100)
        .length;
    final pendientes = activas.length - completos - enCurso;
    final progreso = _store.progreso(equipo);
    return Scaffold(
      body: Column(
        children: [
          CabeceraApp(
            titulo: equipo.nombre,
            alVolver: () => Navigator.maybePop(context),
            accionDerecha: CircleAvatar(
              backgroundColor: Colors.white24,
              child: Text(
                usuario.nombre.isEmpty ? '?' : usuario.nombre[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
              children: [
                _hero(),
                const SizedBox(height: 16),
                _seccionTitulo(
                  esAdmin ? 'Resumen del equipo' : 'Progreso del proyecto',
                  icon: Icons.insights_rounded,
                ),
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Avance ponderado',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '${progreso.round()}%',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 23,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: LinearProgressIndicator(
                          value: progreso / 100,
                          minHeight: 11,
                          backgroundColor: const Color(0xFFE8EEFB),
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _miniStat('$completos', 'Completadas'),
                          _miniStat('$enCurso', 'En progreso'),
                          _miniStat('$pendientes', 'Pendientes'),
                        ],
                      ),
                      const Divider(height: 22),
                      Text(
                        '${_fecha(equipo.fechaInicio)}  →  ${_fecha(equipo.fechaFin)}',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                if (esAdmin) ...[
                  _seccionTitulo(
                    'Integrantes',
                    icon: Icons.groups_rounded,
                    extra: '${miembros.length}',
                  ),
                  ...miembros.map(_tarjetaMiembro),
                  const SizedBox(height: 8),
                ] else ...[
                  _seccionTitulo(
                    'Mis tareas',
                    icon: Icons.checklist_rounded,
                    extra:
                        '${activas.where((t) => t.responsableId == usuario.id).length}',
                  ),
                  ...activas
                      .where((t) => t.responsableId == usuario.id)
                      .map(_tarjetaTarea),
                ],
                if (esAdmin) ...[
                  _seccionTitulo(
                    'Tareas del proyecto',
                    icon: Icons.assignment_rounded,
                    extra: '${activas.length}',
                    action: IconButton(
                      onPressed: _editarTarea,
                      icon: const Icon(
                        Icons.add_circle,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  if (activas.isEmpty)
                    _vacio(
                      'Aún no hay tareas. Agrega la primera para comenzar.',
                    ),
                  ...activas.map(_tarjetaTarea),
                ],
                const SizedBox(height: 10),
                _seccionTitulo(
                  esAdmin ? 'Historial del equipo' : 'Mi historial',
                  icon: Icons.history_rounded,
                  action: esAdmin
                      ? PopupMenuButton<String>(
                          icon: const Icon(Icons.filter_list_rounded),
                          onSelected: (v) => setState(() {
                            _miembroFiltrado = v == 'todos' ? null : v;
                          }),
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'todos',
                              child: Text('Todos los integrantes'),
                            ),
                            ...miembros.map(
                              (m) => PopupMenuItem(
                                value: m.id,
                                child: Text(m.nombre),
                              ),
                            ),
                          ],
                        )
                      : null,
                ),
                if (actividades.isEmpty)
                  _vacio('Las publicaciones de avance aparecerán aquí.'),
                ...actividades.map(_tarjetaActividad),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _hero() => _card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          equipo.nombreProyecto.isEmpty ? equipo.nombre : equipo.nombreProyecto,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryDark,
          ),
        ),
        if (equipo.meta.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            equipo.meta,
            style: const TextStyle(color: AppColors.textMuted, height: 1.35),
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            _pill(
              equipo.categoria.isEmpty ? 'Proyecto' : equipo.categoria,
              Icons.category_outlined,
            ),
            _pill(
              '${miembros.length} integrantes',
              Icons.people_outline_rounded,
            ),
            _pill(
              '${_fecha(equipo.fechaInicio)} – ${_fecha(equipo.fechaFin)}',
              Icons.calendar_month_outlined,
            ),
          ],
        ),
      ],
    ),
  );

  Widget _tarjetaMiembro(MiembroEquipo miembro) {
    final asignadas = tareas
        .where((t) => !t.archivada && t.responsableId == miembro.id)
        .toList();
    final ultimo = _store
        .actividades(equipo)
        .where((a) => a.integranteId == miembro.id)
        .firstOrNull;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 19,
                  backgroundColor: const Color(0xFFEAF0FF),
                  child: Text(
                    miembro.nombre.isEmpty
                        ? '?'
                        : miembro.nombre[0].toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        miembro.nombre,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        _rol(miembro.rol),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${asignadas.length} tareas',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            if (asignadas.isNotEmpty) ...[
              const Divider(height: 20),
              ...asignadas.map(
                (t) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () => _detalleTarea(t),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            t.titulo,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${t.progreso}%  ·  ${_estado(t)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            if (ultimo != null)
              Text(
                'Última actividad: ${ultimo.descripcion}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => setState(() {
                  _miembroFiltrado = miembro.id;
                }),
                child: const Text('Ver historial'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tarjetaTarea(TareaTeam t) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: InkWell(
      onTap: () => _detalleTarea(t),
      borderRadius: BorderRadius.circular(20),
      child: _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    t.titulo,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (esAdmin)
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'edit') _editarTarea(t);
                      if (v == 'delete') _confirmarArchivar(t);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text('Editar / reasignar'),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Eliminar tarea'),
                      ),
                    ],
                  )
                else
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textMuted,
                  ),
              ],
            ),
            if (t.descripcion.isNotEmpty)
              Text(
                t.descripcion,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            const SizedBox(height: 9),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: t.progreso / 100,
                      minHeight: 7,
                      color: AppColors.primary,
                      backgroundColor: const Color(0xFFE8EEFB),
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Text('${t.progreso}%'),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 5,
              children: [
                Text(
                  _estado(t),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Responsable: ${_nombreMiembro(t.responsableId)}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
                Text(
                  'Peso ${t.peso.round()}%',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
                Text(
                  '${_fecha(t.fechaInicio)}–${_fecha(t.fechaEntrega)}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _confirmarArchivar(TareaTeam tarea) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Eliminar tarea'),
        content: Text(
          'La tarea “${tarea.titulo}” se archivará. Su historial seguirá disponible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Archivar'),
          ),
        ],
      ),
    );
    if (confirmar == true) _store.eliminarTarea(equipo, tarea);
  }

  Widget _tarjetaActividad(ActividadTeam a) {
    final tarea = tareas.where((t) => t.id == a.tareaId).firstOrNull;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _nombreMiembro(a.integranteId),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  '${a.fecha.day.toString().padLeft(2, '0')} ${_mes(a.fecha.month)} · ${a.porcentaje}%',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              tarea?.titulo ?? 'Tarea archivada',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 8),
            Text(a.descripcion, style: const TextStyle(height: 1.35)),
          ],
        ),
      ),
    );
  }

  String _mes(int m) => const [
    '',
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ][m];
  String _rol(RolEquipo r) => switch (r) {
    RolEquipo.creador => 'Creador',
    RolEquipo.administrador => 'Administrador',
    RolEquipo.integrante => 'Integrante',
  };
  String _estado(TareaTeam t) => t.progreso == 100
      ? 'Completada'
      : t.progreso == 0
      ? 'Pendiente'
      : 'En progreso';
  Widget _miniStat(String n, String t) => Column(
    children: [
      Text(
        n,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
      Text(t, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
    ],
  );
  Widget _seccionTitulo(
    String titulo, {
    required IconData icon,
    String? extra,
    Widget? action,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10, top: 4),
    child: Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            titulo,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
        ),
        if (extra != null)
          Text(extra, style: const TextStyle(color: AppColors.textMuted)),
        ?action,
      ],
    ),
  );
  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: .07),
          blurRadius: 16,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: child,
  );
  Widget _pill(String text, IconData icon) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFFF0F4FF),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.primary),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 10, color: AppColors.primaryDark),
        ),
      ],
    ),
  );
  Widget _vacio(String texto) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Text(
      texto,
      textAlign: TextAlign.center,
      style: const TextStyle(color: AppColors.textMuted),
    ),
  );
}

class _DetalleTareaSheet extends StatefulWidget {
  const _DetalleTareaSheet({
    required this.equipo,
    required this.tarea,
    required this.editable,
    required this.miembroActualId,
    required this.nombreResponsable,
    required this.fecha,
  });
  final Equipo equipo;
  final TareaTeam tarea;
  final bool editable;
  final String miembroActualId;
  final String nombreResponsable;
  final String Function(DateTime) fecha;
  @override
  State<_DetalleTareaSheet> createState() => _DetalleTareaSheetState();
}

class _DetalleTareaSheetState extends State<_DetalleTareaSheet> {
  final _descripcion = TextEditingController();
  @override
  void dispose() {
    _descripcion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = TeamTrabajoStore.instancia;
    final historial = store
        .actividades(widget.equipo)
        .where((a) => a.tareaId == widget.tarea.id)
        .toList();
    return SafeArea(
      child: Container(
        height: MediaQuery.sizeOf(context).height * .88,
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.tarea.titulo,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text('${widget.tarea.progreso}%'),
              ],
            ),
            if (widget.tarea.descripcion.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  widget.tarea.descripcion,
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              '${widget.nombreResponsable} · ${widget.fecha(widget.tarea.fechaInicio)} a ${widget.fecha(widget.tarea.fechaEntrega)} · Peso ${widget.tarea.peso.round()}%',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            if (widget.editable) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _abrirProgreso(context),
                      icon: const Icon(Icons.trending_up_rounded),
                      label: const Text('Actualizar progreso'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _publicar(context),
                      icon: const Icon(Icons.post_add_rounded),
                      label: const Text('Registrar avance'),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 18),
            Text(
              'Historial de actividad',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 9),
            Expanded(
              child: historial.isEmpty
                  ? const Center(
                      child: Text(
                        'Todavía no hay publicaciones.',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    )
                  : ListView(
                      children: [
                        for (final a in historial)
                          Card(
                            color: Colors.white,
                            elevation: 0,
                            child: ListTile(
                              dense: true,
                              title: Text(
                                '${a.fecha.day.toString().padLeft(2, '0')}/${a.fecha.month.toString().padLeft(2, '0')} · ${a.porcentaje}%',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(a.descripcion),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _abrirProgreso(BuildContext context) async {
    int value = widget.tarea.progreso;
    final nuevo = await showDialog<int>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          title: const Text('Actualizar progreso'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$value%',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              Slider(
                value: value.toDouble(),
                min: widget.tarea.progreso.toDouble(),
                max: 100,
                divisions: 100 - widget.tarea.progreso == 0
                    ? null
                    : 100 - widget.tarea.progreso,
                onChanged: (v) => set(() => value = v.round()),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, value),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    if (nuevo != null) {
      TeamTrabajoStore.instancia.actualizarProgreso(
        widget.equipo,
        widget.tarea,
        nuevo,
      );
      if (mounted) setState(() {});
    }
  }

  Future<void> _publicar(BuildContext context) async {
    final texto = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Registrar avance'),
        content: TextField(
          controller: _descripcion,
          autofocus: true,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: '¿Qué realizaste en esta tarea?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (_descripcion.text.trim().isNotEmpty) {
                Navigator.pop(c, _descripcion.text.trim());
              }
            },
            child: const Text('Publicar avance'),
          ),
        ],
      ),
    );
    if (texto != null) {
      TeamTrabajoStore.instancia.publicar(
        widget.equipo,
        widget.tarea,
        widget.miembroActualId,
        texto,
      );
      _descripcion.clear();
      if (mounted) setState(() {});
    }
  }
}
