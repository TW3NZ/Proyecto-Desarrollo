import 'package:flutter/material.dart';

import '../data/proyectos_store.dart';
import '../data/miembros_proyecto_store.dart';
import '../data/id_temporal_store.dart';
import '../data/usuarios_store.dart';
import '../models/equipo_modelo.dart';
import '../models/miembro_proyecto.dart';
import '../models/tarea_modelo.dart';
import '../models/proyecto_modelo.dart';
import '../theme.dart';
import '../widgets/common/cabecera_app.dart';
import '../widgets/common/primary_button.dart';

/// Segunda pantalla del flujo: detalles del proyecto, tareas y asignaciones.
/// Todos los datos se mantienen en memoria mientras la pantalla está abierta.
class DetallesTeamScreen extends StatefulWidget {
  const DetallesTeamScreen({super.key, required this.equipo, this.usuarioId});

  final Equipo equipo;
  final int? usuarioId;

  @override
  State<DetallesTeamScreen> createState() => _DetallesTeamScreenState();
}

class _DetallesTeamScreenState extends State<DetallesTeamScreen> {
  final _metaController = TextEditingController(
    text: 'Preparación de Examen de Cálculo Integrales',
  );
  final _nombreController = TextEditingController(text: 'Nuevo proyecto');
  final _tareaController = TextEditingController();
  CategoriaTarea _categoria = CategoriaTarea.educacion;
  DateTime _inicio = DateTime(2026, 11, 12);
  DateTime _fin = DateTime(2026, 11, 26);
  DateTime _inicioAsignacion = DateTime(2026, 11, 12);
  DateTime _finAsignacion = DateTime(2026, 11, 18);
  String? _tareaSeleccionada = 'Revisar capítulo 4 de Integrales';
  int? _integranteSeleccionado;
  String? _imagenSeleccionada;
  int _etapa = 0;

  late final List<MiembroEquipo> _miembros;
  late final List<MiembroProyecto> _miembrosProyecto;
  late final int _creadorId;
  late final int _proyectoId;
  final List<NuevaTarea> _tareas = [
    NuevaTarea(
      id: IdTemporalStore.generar(),
      usuarioId:
          UsuariosStore.usuarioActual?.id ?? UsuariosStore.idUsuarioPractica,
      titulo: 'Revisar capítulo 4 de Integrales',
      categorias: {CategoriaTarea.educacion},
      prioridad: PrioridadTarea.media,
      fecha: DateTime(2026, 11, 12),
    ),
    NuevaTarea(
      id: IdTemporalStore.generar(),
      usuarioId:
          UsuariosStore.usuarioActual?.id ?? UsuariosStore.idUsuarioPractica,
      titulo: 'Resolver guía de ejercicios #2',
      categorias: {CategoriaTarea.educacion},
      prioridad: PrioridadTarea.media,
      fecha: DateTime(2026, 11, 12),
    ),
  ];
  bool _equipoGuardado = false;

  @override
  void initState() {
    super.initState();
    _miembros = widget.equipo.miembros;
    _creadorId =
        widget.usuarioId ??
        UsuariosStore.usuarioActual?.id ??
        widget.equipo.creadorId;
    _proyectoId = IdTemporalStore.generar();
    _miembrosProyecto = [
      for (final miembro in _miembros)
        MiembroProyecto(
          id: IdTemporalStore.generar(),
          miembroId: miembro.id,
          proyectoId: _proyectoId,
          rol: miembro.usuarioId == _creadorId
              ? RolProyecto.creador
              : RolProyecto.integrante,
        ),
    ];
    _integranteSeleccionado = _miembros.first.usuarioId;
    if (_tareas.isNotEmpty) {
      final tarea = _tareas.first;
      _tareas[0] = NuevaTarea(
        id: tarea.id,
        proyectoId: null,
        usuarioId: _creadorId,
        titulo: tarea.titulo,
        categorias: tarea.categorias,
        prioridad: tarea.prioridad,
        fecha: _inicioAsignacion,
        fechaFinalizacion: _finAsignacion,
        responsableId: _creadorId,
      );
    }
  }

  String _etiquetaMiembro(int usuarioId) {
    final cuenta = UsuariosStore.buscarPorId(usuarioId);
    if (cuenta == null) return usuarioId.toString();
    final nombre = '${cuenta.name} ${cuenta.lastName}'.trim();
    return nombre.isEmpty ? cuenta.nickName : nombre;
  }

  MiembroProyecto get _creadorProyecto => _miembrosProyecto.firstWhere(
    (relacion) => relacion.rol == RolProyecto.creador,
  );

  bool get _puedeGestionarRoles =>
      PermisosProyecto.puedeGestionarRoles(_creadorProyecto.rol);

  void _cambiarRol(MiembroProyecto objetivo) {
    if (!PermisosProyecto.puedeCambiarRol(
      actor: _creadorProyecto.rol,
      objetivo: objetivo.rol,
    )) {
      _mensaje('Solo el creador del proyecto puede administrar sus roles');
      return;
    }
    final nuevoRol = objetivo.rol == RolProyecto.administrador
        ? RolProyecto.integrante
        : RolProyecto.administrador;
    setState(() {
      final indice = _miembrosProyecto.indexWhere(
        (relacion) => relacion.miembroId == objetivo.miembroId,
      );
      _miembrosProyecto[indice] = MiembroProyecto(
        id: objetivo.id,
        miembroId: objetivo.miembroId,
        proyectoId: objetivo.proyectoId,
        rol: nuevoRol,
      );
    });
  }

  static const _opcionesImagen = <(String, IconData, Color)>[
    ('Estudio', Icons.menu_book_rounded, Color(0xFF4F7DE8)),
    ('Equipo', Icons.groups_rounded, Color(0xFF21A6A1)),
    ('Creatividad', Icons.lightbulb_rounded, Color(0xFFF0A43A)),
    ('Ciencia', Icons.science_rounded, Color(0xFF8B69D5)),
  ];

  @override
  void dispose() {
    _metaController.dispose();
    _nombreController.dispose();
    _tareaController.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha({
    required bool inicio,
    bool asignacion = false,
  }) async {
    final actual = asignacion
        ? (inicio ? _inicioAsignacion : _finAsignacion)
        : (inicio ? _inicio : _fin);
    final fecha = await showDatePicker(
      context: context,
      initialDate: actual,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: inicio
          ? 'Selecciona la fecha de inicio'
          : 'Selecciona la fecha de fin',
    );
    if (fecha == null || !mounted) return;
    setState(() {
      if (asignacion) {
        if (inicio) {
          _inicioAsignacion = fecha;
          if (_finAsignacion.isBefore(fecha)) _finAsignacion = fecha;
        } else {
          _finAsignacion = fecha;
          if (_inicioAsignacion.isAfter(fecha)) _inicioAsignacion = fecha;
        }
      } else if (inicio) {
        _inicio = fecha;
        if (_fin.isBefore(fecha)) _fin = fecha;
      } else {
        _fin = fecha;
        if (_inicio.isAfter(fecha)) _inicio = fecha;
      }
    });
  }

  void _agregarTarea() {
    final nombre = _tareaController.text.trim();
    if (nombre.isEmpty) {
      _mensaje('Escribe el nombre de la tarea');
      return;
    }
    if (_tareas.any((tarea) => tarea.titulo == nombre)) {
      _mensaje('Esa tarea ya está en la lista');
      return;
    }
    setState(() {
      _tareas.add(
        NuevaTarea(
          id: IdTemporalStore.generar(),
          usuarioId: _creadorId,
          titulo: nombre,
          categorias: {_categoria},
          prioridad: PrioridadTarea.media,
          fecha: _inicio,
          fechaFinalizacion: _fin,
        ),
      );
      _tareaSeleccionada ??= nombre;
      _tareaController.clear();
    });
  }

  void _eliminarTarea(NuevaTarea tarea) {
    setState(() {
      _tareas.remove(tarea);
      if (_tareaSeleccionada == tarea.titulo) {
        _tareaSeleccionada = _tareas.isEmpty ? null : _tareas.first.titulo;
      }
    });
  }

  void _agregarAsignacion() {
    final titulo = _tareaSeleccionada;
    if (titulo == null || _tareas.isEmpty) {
      _mensaje('Agrega una tarea antes de asignarla');
      return;
    }
    final indice = _tareas.indexWhere((tarea) => tarea.titulo == titulo);
    if (indice < 0) return;
    final tarea = _tareas[indice];
    setState(() {
      _tareas[indice] = NuevaTarea(
        id: tarea.id,
        proyectoId: tarea.proyectoId,
        usuarioId: tarea.usuarioId,
        titulo: tarea.titulo,
        categorias: tarea.categorias,
        prioridad: tarea.prioridad,
        descripcion: tarea.descripcion,
        fecha: _inicioAsignacion,
        fechaFinalizacion: _finAsignacion,
        responsableId: _integranteSeleccionado ?? _miembros.first.usuarioId,
        completada: tarea.completada,
      );
    });
  }

  void _crearProyecto() {
    if (_creadorId != widget.equipo.creadorId) {
      _mensaje('Solo el creador del equipo puede crear proyectos');
      return;
    }
    if (_metaController.text.trim().isEmpty) {
      _mensaje('Escribe la meta del proyecto');
      return;
    }
    if (_fin.isBefore(_inicio)) {
      _mensaje('La fecha de finalización debe ser posterior al inicio');
      return;
    }
    if (_nombreController.text.trim().isEmpty) {
      _mensaje('Escribe el nombre del proyecto');
      return;
    }
    if (!_equipoGuardado) {
      final proyectoId = _proyectoId;
      ProyectosStore.agregar(
        Proyecto(
          id: proyectoId,
          equipoId: widget.equipo.id,
          nombre: _nombreController.text.trim(),
          meta: _metaController.text.trim(),
          categoria: _categoria,
          fechaInicio: _inicio,
          fechaFin: _fin,
          tareas: _tareas
              .map(
                (tarea) => NuevaTarea(
                  id: tarea.id,
                  proyectoId: proyectoId,
                  usuarioId: tarea.usuarioId,
                  titulo: tarea.titulo,
                  categorias: tarea.categorias,
                  prioridad: tarea.prioridad,
                  descripcion: tarea.descripcion,
                  fecha: tarea.fecha,
                  fechaFinalizacion: tarea.fechaFinalizacion,
                  responsableId: tarea.responsableId,
                  completada: tarea.completada,
                ),
              )
              .toList(),
          imagen: _imagenSeleccionada,
        ),
      );
      MiembrosProyectoStore.guardarProyecto(proyectoId, _miembrosProyecto);
      _equipoGuardado = true;
    }
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.check_circle_rounded,
          color: Color(0xFF22A06B),
          size: 42,
        ),
        title: const Text('¡Proyecto creado!'),
        content: Text(
          '${_nombreController.text.trim()}\n${_metaController.text.trim()}\n\n'
          'Categoría: ${_categoria.etiqueta}\n'
          'Tareas: ${_tareas.length} · Asignadas: ${_tareas.where((tarea) => tarea.responsableId != null).length}',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.maybePop(this.context);
            },
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );
  }

  void _mensaje(String texto) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(texto), behavior: SnackBarBehavior.floating),
    );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          CabeceraApp(
            titulo: 'Crear Proyecto',
            alVolver: () => Navigator.maybePop(context),
          ),
          _Progreso(
            etapa: _etapa,
            alSeleccionar: (etapa) => setState(() => _etapa = etapa),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
              children: [
                _Seccion(
                  icono: Icons.folder_rounded,
                  titulo: 'Nombre del proyecto',
                  subtitulo: 'Identifica este proyecto dentro del equipo',
                  contenido: TextField(
                    controller: _nombreController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: _decoracion('Nombre del proyecto'),
                  ),
                ),
                _separador,
                _Seccion(
                  icono: Icons.emoji_events_rounded,
                  titulo: 'Crear meta',
                  subtitulo: '¿Cuál es tu objetivo?',
                  contenido: TextField(
                    controller: _metaController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: _decoracion(
                      'Ej. Estudiar para el parcial de Cálculo',
                    ),
                  ),
                ),
                _separador,
                _Seccion(
                  icono: Icons.grid_view_rounded,
                  titulo: 'Categoría',
                  subtitulo: 'Selecciona una categoría',
                  contenido: DropdownButtonFormField<CategoriaTarea>(
                    initialValue: _categoria,
                    decoration: _decoracion('Categoría'),
                    items: CategoriaTarea.values
                        .map(
                          (categoria) => DropdownMenuItem(
                            value: categoria,
                            child: Text(categoria.etiqueta),
                          ),
                        )
                        .toList(),
                    onChanged: (valor) {
                      if (valor != null) setState(() => _categoria = valor);
                    },
                  ),
                ),
                _separador,
                _Seccion(
                  icono: Icons.calendar_month_rounded,
                  titulo: 'Fecha de duración',
                  subtitulo: '¿Cuánto tiempo tendrá tu proyecto?',
                  contenido: Row(
                    children: [
                      Expanded(
                        child: _FechaTile(
                          etiqueta: 'Inicio',
                          fecha: _inicio,
                          onTap: () => _elegirFecha(inicio: true),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _FechaTile(
                          etiqueta: 'Fin',
                          fecha: _fin,
                          onTap: () => _elegirFecha(inicio: false),
                        ),
                      ),
                    ],
                  ),
                ),
                _separador,
                _Seccion(
                  icono: Icons.checklist_rounded,
                  titulo: 'Definir tareas',
                  subtitulo: 'Agrega las tareas principales del proyecto',
                  contenido: Column(
                    children: [
                      if (_tareas.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text(
                            'Aún no hay tareas',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        )
                      else
                        for (final tarea in _tareas)
                          _TareaTile(
                            tarea: tarea,
                            onDelete: () => _eliminarTarea(tarea),
                          ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _tareaController,
                              textCapitalization: TextCapitalization.sentences,
                              onSubmitted: (_) => _agregarTarea(),
                              decoration: _decoracion('Escribe la tarea...'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            tooltip: 'Agregar tarea',
                            onPressed: _agregarTarea,
                            icon: const Icon(Icons.add_rounded),
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _separador,
                _Seccion(
                  icono: Icons.groups_rounded,
                  titulo: 'Integrantes del equipo',
                  subtitulo: 'El creador administra los roles del proyecto',
                  contenido: Column(
                    children: [
                      for (final relacion in _miembrosProyecto)
                        _MiembroTile(
                          miembro: _miembros.firstWhere(
                            (miembro) => miembro.id == relacion.miembroId,
                          ),
                          rol: relacion.rol,
                          nombre: _etiquetaMiembro(
                            _miembros
                                .firstWhere(
                                  (miembro) => miembro.id == relacion.miembroId,
                                )
                                .usuarioId,
                          ),
                          puedeGestionarRoles: _puedeGestionarRoles,
                          alCambiarRol: () => _cambiarRol(relacion),
                        ),
                    ],
                  ),
                ),
                _separador,
                _Seccion(
                  icono: Icons.assignment_ind_rounded,
                  titulo: 'Asignar tareas a integrantes',
                  subtitulo: 'Selecciona una tarea y asígnala a un integrante',
                  contenido: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _etiqueta('Seleccionar tarea'),
                      DropdownButtonFormField<String>(
                        initialValue:
                            _tareas.any(
                              (tarea) => tarea.titulo == _tareaSeleccionada,
                            )
                            ? _tareaSeleccionada
                            : null,
                        isExpanded: true,
                        decoration: _decoracion('Elige una tarea'),
                        items: [
                          for (final tarea in _tareas)
                            DropdownMenuItem(
                              value: tarea.titulo,
                              child: Text(
                                tarea.titulo,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: _tareas.isEmpty
                            ? null
                            : (valor) {
                                if (valor != null) {
                                  setState(() => _tareaSeleccionada = valor);
                                }
                              },
                      ),
                      const SizedBox(height: 12),
                      _etiqueta('Integrante asignado'),
                      DropdownButtonFormField<int>(
                        initialValue: _integranteSeleccionado,
                        decoration: _decoracion('Elige un integrante'),
                        items: [
                          for (final integrante in _miembros)
                            DropdownMenuItem(
                              value: integrante.usuarioId,
                              child: Text('ID: ${integrante.usuarioId}'),
                            ),
                        ],
                        onChanged: (valor) {
                          if (valor != null) {
                            setState(() => _integranteSeleccionado = valor);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _FechaTile(
                              etiqueta: 'Inicio',
                              fecha: _inicioAsignacion,
                              onTap: () =>
                                  _elegirFecha(inicio: true, asignacion: true),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _FechaTile(
                              etiqueta: 'Fin',
                              fecha: _finAsignacion,
                              onTap: () =>
                                  _elegirFecha(inicio: false, asignacion: true),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _agregarAsignacion,
                        icon: const Icon(Icons.person_add_alt_1_rounded),
                        label: const Text('Asignar tarea'),
                      ),
                      if (_tareas.any(
                        (tarea) => tarea.responsableId != null,
                      )) ...[
                        const SizedBox(height: 8),
                        for (var i = 0; i < _tareas.length; i++)
                          if (_tareas[i].responsableId != null)
                            _AsignacionTile(
                              tarea: _tareas[i],
                              nombreMiembro: _etiquetaMiembro(
                                _tareas[i].responsableId!,
                              ),
                              onDelete: () => setState(() {
                                final tarea = _tareas[i];
                                _tareas[i] = NuevaTarea(
                                  id: tarea.id,
                                  proyectoId: tarea.proyectoId,
                                  usuarioId: tarea.usuarioId,
                                  titulo: tarea.titulo,
                                  categorias: tarea.categorias,
                                  prioridad: tarea.prioridad,
                                  descripcion: tarea.descripcion,
                                  fecha: tarea.fecha,
                                  fechaFinalizacion: tarea.fechaFinalizacion,
                                  completada: tarea.completada,
                                );
                              }),
                            ),
                      ],
                    ],
                  ),
                ),
                _separador,
                _Seccion(
                  icono: Icons.image_rounded,
                  titulo: 'Agregar imagen',
                  subtitulo: 'Selecciona una imagen para tu proyecto',
                  contenido: Column(
                    children: [
                      if (_imagenSeleccionada == null)
                        const Text(
                          'Elige una portada para identificar tu proyecto',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        )
                      else
                        _VistaPreviaImagen(
                          opcion: _opcionesImagen.firstWhere(
                            (opcion) => opcion.$1 == _imagenSeleccionada,
                          ),
                        ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final opcion in _opcionesImagen)
                            ChoiceChip(
                              avatar: Icon(
                                opcion.$2,
                                size: 18,
                                color: opcion.$3,
                              ),
                              label: Text(opcion.$1),
                              selected: _imagenSeleccionada == opcion.$1,
                              onSelected: (_) => setState(
                                () => _imagenSeleccionada = opcion.$1,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  text: 'Crear Proyecto  →',
                  onPressed: _crearProyecto,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const _separador = SizedBox(height: 14);

InputDecoration _decoracion(String hint) => InputDecoration(
  hintText: hint,
  filled: true,
  fillColor: Colors.white,
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: AppColors.divider),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: AppColors.divider),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
  ),
);

Widget _etiqueta(String texto) => Padding(
  padding: const EdgeInsets.only(bottom: 6),
  child: Text(
    texto,
    style: const TextStyle(
      color: AppColors.textDark,
      fontSize: 12,
      fontWeight: FontWeight.w700,
    ),
  ),
);

class _Progreso extends StatelessWidget {
  const _Progreso({required this.etapa, required this.alSeleccionar});
  final int etapa;
  final ValueChanged<int> alSeleccionar;
  static const _nombres = ['Detalles', 'Tareas', 'Imagen', 'Resumen'];
  static const _iconos = [
    Icons.edit_rounded,
    Icons.checklist_rounded,
    Icons.image_outlined,
    Icons.check_rounded,
  ];

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 3),
    child: Row(
      children: [
        for (var i = 0; i < _nombres.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 2,
                color: i <= etapa ? AppColors.primary : const Color(0xFFD4DDF2),
              ),
            ),
          GestureDetector(
            onTap: () => alSeleccionar(i),
            child: SizedBox(
              width: 58,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 17,
                    backgroundColor: i <= etapa
                        ? AppColors.primary
                        : const Color(0xFFE6ECFA),
                    foregroundColor: i <= etapa
                        ? Colors.white
                        : AppColors.textMuted,
                    child: Icon(_iconos[i], size: 17),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _nombres[i],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: i == etapa
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: i <= etapa
                          ? AppColors.primaryDark
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

class _Seccion extends StatelessWidget {
  const _Seccion({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.contenido,
  });
  final IconData icono;
  final String titulo;
  final String subtitulo;
  final Widget contenido;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(25),
      border: Border.all(color: const Color(0xFFE6EEFF)),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.07),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF1FF),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icono, color: AppColors.primary, size: 23),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitulo,
                    style: const TextStyle(
                      color: AppColors.textHint,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        contenido,
      ],
    ),
  );
}

class _FechaTile extends StatelessWidget {
  const _FechaTile({
    required this.etiqueta,
    required this.fecha,
    required this.onTap,
  });
  final String etiqueta;
  final DateTime fecha;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(15),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FE),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_today_rounded,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  etiqueta.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}',
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
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

class _TareaTile extends StatelessWidget {
  const _TareaTile({required this.tarea, required this.onDelete});
  final NuevaTarea tarea;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 7),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: const Color(0xFFF6F8FD),
      borderRadius: BorderRadius.circular(13),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.radio_button_checked_rounded,
          size: 18,
          color: AppColors.primary,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            tarea.titulo,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        IconButton(
          onPressed: onDelete,
          visualDensity: VisualDensity.compact,
          tooltip: 'Eliminar tarea',
          icon: const Icon(
            Icons.close_rounded,
            size: 19,
            color: AppColors.textHint,
          ),
        ),
      ],
    ),
  );
}

class _MiembroTile extends StatelessWidget {
  const _MiembroTile({
    required this.miembro,
    required this.rol,
    required this.nombre,
    required this.puedeGestionarRoles,
    required this.alCambiarRol,
  });

  final MiembroEquipo miembro;
  final RolProyecto rol;
  final String nombre;
  final bool puedeGestionarRoles;
  final VoidCallback alCambiarRol;

  String get _nombreRol => switch (rol) {
    RolProyecto.creador => 'Creador',
    RolProyecto.administrador => 'Administrador',
    RolProyecto.integrante => 'Integrante',
  };

  Color get _colorRol => switch (rol) {
    RolProyecto.creador => const Color(0xFF8B5CF6),
    RolProyecto.administrador => AppColors.primary,
    RolProyecto.integrante => AppColors.textMuted,
  };

  @override
  Widget build(BuildContext context) {
    final esCreador = rol == RolProyecto.creador;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FE),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE8EEFA)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: _colorRol.withValues(alpha: 0.12),
            child: Icon(
              esCreador
                  ? Icons.workspace_premium_rounded
                  : Icons.person_rounded,
              color: _colorRol,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'ID: ${miembro.usuarioId}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: _colorRol.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _nombreRol,
              style: TextStyle(
                color: _colorRol,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (puedeGestionarRoles && !esCreador)
            PopupMenuButton<RolProyecto>(
              tooltip: 'Administrar rol',
              onSelected: (_) => alCambiarRol(),
              itemBuilder: (_) => [
                PopupMenuItem<RolProyecto>(
                  value: rol == RolProyecto.administrador
                      ? RolProyecto.integrante
                      : RolProyecto.administrador,
                  child: Text(
                    rol == RolProyecto.administrador
                        ? 'Quitar administrador'
                        : 'Hacer administrador',
                  ),
                ),
              ],
              icon: const Icon(
                Icons.more_vert_rounded,
                color: AppColors.textMuted,
              ),
            ),
        ],
      ),
    );
  }
}

class _AsignacionTile extends StatelessWidget {
  const _AsignacionTile({
    required this.tarea,
    required this.nombreMiembro,
    required this.onDelete,
  });
  final NuevaTarea tarea;
  final String nombreMiembro;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 7),
    padding: const EdgeInsets.fromLTRB(11, 9, 4, 9),
    decoration: BoxDecoration(
      color: const Color(0xFFF5F8FF),
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: const Color(0xFFE6EEFF)),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.assignment_turned_in_rounded,
          color: AppColors.primary,
          size: 19,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tarea.titulo,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                '$nombreMiembro · ${tarea.fecha.day}/${tarea.fecha.month} – ${tarea.fechaFinalizacion?.day ?? tarea.fecha.day}/${tarea.fechaFinalizacion?.month ?? tarea.fecha.month}',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onDelete,
          tooltip: 'Quitar asignación',
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.close_rounded, size: 18),
        ),
      ],
    ),
  );
}

class _VistaPreviaImagen extends StatelessWidget {
  const _VistaPreviaImagen({required this.opcion});
  final (String, IconData, Color) opcion;
  @override
  Widget build(BuildContext context) => Container(
    height: 125,
    width: double.infinity,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      gradient: LinearGradient(
        colors: [opcion.$3.withValues(alpha: 0.85), opcion.$3],
      ),
    ),
    child: Stack(
      children: [
        Positioned(
          right: -8,
          bottom: -20,
          child: Icon(
            opcion.$2,
            size: 150,
            color: Colors.white.withValues(alpha: 0.17),
          ),
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(opcion.$2, color: Colors.white, size: 40),
              const SizedBox(height: 5),
              Text(
                opcion.$1,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
