import 'package:flutter/material.dart';

import '../data/equipos_store.dart';
import '../models/equipo_modelo.dart';
import '../theme.dart';
import '../widgets/common/cabecera_app.dart';
import '../widgets/common/primary_button.dart';

/// Segunda pantalla del flujo: detalles del proyecto, tareas y asignaciones.
/// Todos los datos se mantienen en memoria mientras la pantalla está abierta.
class DetallesTeamScreen extends StatefulWidget {
  const DetallesTeamScreen({
    super.key,
    this.nombreProyecto = 'Proyecto Final de Software',
    this.integrantes = const ['12345 (Tú)', '98765'],
  });

  final String nombreProyecto;
  final List<String> integrantes;

  @override
  State<DetallesTeamScreen> createState() => _DetallesTeamScreenState();
}

class _DetallesTeamScreenState extends State<DetallesTeamScreen> {
  final _metaController = TextEditingController(
    text: 'Preparación de Examen de Cálculo Integrales',
  );
  final _tareaController = TextEditingController();
  String _categoria = 'Académico';
  DateTime _inicio = DateTime(2026, 11, 12);
  DateTime _fin = DateTime(2026, 11, 26);
  DateTime _inicioAsignacion = DateTime(2026, 11, 12);
  DateTime _finAsignacion = DateTime(2026, 11, 18);
  String? _tareaSeleccionada = 'Revisar capítulo 4 de Integrales';
  String? _integranteSeleccionado;
  String? _imagenSeleccionada;
  int _etapa = 0;

  final List<MiembroEquipo> _miembros = [];
  late final String _creadorId;
  final List<String> _tareas = [
    'Revisar capítulo 4 de Integrales',
    'Resolver guía de ejercicios #2',
  ];
  final List<_Asignacion> _asignaciones = [
    _Asignacion(
      tarea: 'Revisar capítulo 4 de Integrales',
      integrante: '12345 (Tú)',
      inicio: DateTime(2026, 11, 12),
      fin: DateTime(2026, 11, 18),
    ),
  ];
  bool _equipoGuardado = false;

  @override
  void initState() {
    super.initState();
    final integrantes = widget.integrantes.isEmpty
        ? const ['12345 (Tú)']
        : widget.integrantes;
    _creadorId = _idDesdeEtiqueta(integrantes.first);
    for (final etiqueta in integrantes) {
      final id = _idDesdeEtiqueta(etiqueta);
      if (_miembros.any((miembro) => miembro.id == id)) continue;
      _miembros.add(
        MiembroEquipo(
          id: id,
          nombre: etiqueta,
          rol: id == _creadorId ? RolEquipo.creador : RolEquipo.integrante,
        ),
      );
    }
    _integranteSeleccionado = _miembros.first.id;
  }

  String _idDesdeEtiqueta(String etiqueta) =>
      etiqueta.trim().split(RegExp(r'\s+')).first;

  MiembroEquipo get _creador =>
      _miembros.firstWhere((miembro) => miembro.id == _creadorId);

  bool get _puedeGestionarRoles => PermisosEquipo.puedeGestionarRoles(_creador);

  void _cambiarRol(MiembroEquipo objetivo) {
    if (!PermisosEquipo.puedeCambiarRol(actor: _creador, objetivo: objetivo)) {
      _mensaje('Solo el creador puede administrar los roles del equipo');
      return;
    }
    final nuevoRol = objetivo.rol == RolEquipo.administrador
        ? RolEquipo.integrante
        : RolEquipo.administrador;
    setState(() {
      final indice = _miembros.indexWhere(
        (miembro) => miembro.id == objetivo.id,
      );
      _miembros[indice] = MiembroEquipo(
        id: objetivo.id,
        nombre: objetivo.nombre,
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
    if (_tareas.contains(nombre)) {
      _mensaje('Esa tarea ya está en la lista');
      return;
    }
    setState(() {
      _tareas.add(nombre);
      _tareaSeleccionada ??= nombre;
      _tareaController.clear();
    });
  }

  void _eliminarTarea(String tarea) {
    setState(() {
      _tareas.remove(tarea);
      _asignaciones.removeWhere((asignacion) => asignacion.tarea == tarea);
      if (_tareaSeleccionada == tarea) {
        _tareaSeleccionada = _tareas.isEmpty ? null : _tareas.first;
      }
    });
  }

  void _agregarAsignacion() {
    final tarea = _tareaSeleccionada;
    if (tarea == null || _tareas.isEmpty) {
      _mensaje('Agrega una tarea antes de asignarla');
      return;
    }
    setState(
      () => _asignaciones.add(
        _Asignacion(
          tarea: tarea,
          integrante: _integranteSeleccionado ?? _miembros.first.id,
          inicio: _inicioAsignacion,
          fin: _finAsignacion,
        ),
      ),
    );
  }

  void _crearProyecto() {
    if (_metaController.text.trim().isEmpty) {
      _mensaje('Escribe la meta del proyecto');
      return;
    }
    if (_fin.isBefore(_inicio)) {
      _mensaje('La fecha de finalización debe ser posterior al inicio');
      return;
    }
    if (!_equipoGuardado) {
      final nombre = widget.nombreProyecto.trim();
      final siglas = nombre
          .split(RegExp(r'\s+'))
          .where((parte) => parte.isNotEmpty)
          .take(2)
          .map((parte) => parte[0].toUpperCase())
          .join();
      EquiposStore.agregar(
        Equipo(
          id: 'T${DateTime.now().microsecondsSinceEpoch}',
          proyectoId: EquiposStore.generarProyectoId(),
          nombre: 'Team de $nombre',
          siglas: siglas.isEmpty ? 'TM' : siglas,
          miembrosConectados: _miembros.length,
          nombreProyecto: nombre,
          meta: _metaController.text.trim(),
          categoria: _categoria,
          fechaInicio: _inicio,
          fechaFin: _fin,
          tareas: List.unmodifiable(_tareas),
          integrantes: List.unmodifiable(
            _miembros.map((miembro) => miembro.id),
          ),
          creadorId: _creadorId,
          miembros: List.unmodifiable(_miembros),
          asignaciones: List.unmodifiable(
            _asignaciones.map(
              (a) =>
                  '${a.tarea} — ${a.integrante} (${a.inicio.day}/${a.inicio.month}–${a.fin.day}/${a.fin.month})',
            ),
          ),
          imagen: _imagenSeleccionada,
        ),
      );
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
          '${_metaController.text.trim()}\n\n'
          'Categoría: $_categoria\n'
          'Tareas: ${_tareas.length} · Asignaciones: ${_asignaciones.length}',
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
                  contenido: DropdownButtonFormField<String>(
                    initialValue: _categoria,
                    decoration: _decoracion('Categoría'),
                    items: const [
                      DropdownMenuItem(
                        value: 'Académico',
                        child: Text('🎓  Académico'),
                      ),
                      DropdownMenuItem(
                        value: 'Trabajo',
                        child: Text('💼  Trabajo'),
                      ),
                      DropdownMenuItem(
                        value: 'Personal',
                        child: Text('👤  Personal'),
                      ),
                      DropdownMenuItem(
                        value: 'Investigación',
                        child: Text('🔬  Investigación'),
                      ),
                    ],
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
                  subtitulo: 'El creador administra los roles del equipo',
                  contenido: Column(
                    children: [
                      for (final miembro in _miembros)
                        _MiembroTile(
                          miembro: miembro,
                          puedeGestionarRoles: _puedeGestionarRoles,
                          alCambiarRol: () => _cambiarRol(miembro),
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
                        initialValue: _tareas.contains(_tareaSeleccionada)
                            ? _tareaSeleccionada
                            : null,
                        isExpanded: true,
                        decoration: _decoracion('Elige una tarea'),
                        items: [
                          for (final tarea in _tareas)
                            DropdownMenuItem(
                              value: tarea,
                              child: Text(
                                tarea,
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
                      DropdownButtonFormField<String>(
                        initialValue: _integranteSeleccionado,
                        decoration: _decoracion('Elige un integrante'),
                        items: [
                          for (final integrante in _miembros)
                            DropdownMenuItem(
                              value: integrante.id,
                              child: Text('ID: ${integrante.id}'),
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
                      if (_asignaciones.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        for (var i = 0; i < _asignaciones.length; i++)
                          _AsignacionTile(
                            asignacion: _asignaciones[i],
                            onDelete: () =>
                                setState(() => _asignaciones.removeAt(i)),
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
  final String tarea;
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
            tarea,
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

class _Asignacion {
  const _Asignacion({
    required this.tarea,
    required this.integrante,
    required this.inicio,
    required this.fin,
  });
  final String tarea;
  final String integrante;
  final DateTime inicio;
  final DateTime fin;
}

class _MiembroTile extends StatelessWidget {
  const _MiembroTile({
    required this.miembro,
    required this.puedeGestionarRoles,
    required this.alCambiarRol,
  });

  final MiembroEquipo miembro;
  final bool puedeGestionarRoles;
  final VoidCallback alCambiarRol;

  String get _nombreRol => switch (miembro.rol) {
    RolEquipo.creador => 'Creador',
    RolEquipo.administrador => 'Administrador',
    RolEquipo.integrante => 'Integrante',
  };

  Color get _colorRol => switch (miembro.rol) {
    RolEquipo.creador => const Color(0xFF8B5CF6),
    RolEquipo.administrador => AppColors.primary,
    RolEquipo.integrante => AppColors.textMuted,
  };

  @override
  Widget build(BuildContext context) {
    final esCreador = miembro.rol == RolEquipo.creador;
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
                  miembro.nombre,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'ID: ${miembro.id}',
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
            PopupMenuButton<RolEquipo>(
              tooltip: 'Administrar rol',
              onSelected: (_) => alCambiarRol(),
              itemBuilder: (_) => [
                PopupMenuItem<RolEquipo>(
                  value: miembro.rol == RolEquipo.administrador
                      ? RolEquipo.integrante
                      : RolEquipo.administrador,
                  child: Text(
                    miembro.rol == RolEquipo.administrador
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
  const _AsignacionTile({required this.asignacion, required this.onDelete});
  final _Asignacion asignacion;
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
                asignacion.tarea,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                '${asignacion.integrante} · ${asignacion.inicio.day}/${asignacion.inicio.month} – ${asignacion.fin.day}/${asignacion.fin.month}',
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
