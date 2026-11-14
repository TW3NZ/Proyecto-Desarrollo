import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/usuarios_store.dart';
import '../data/estadisticas_store.dart';
import '../services/equipos_api_service.dart';
import '../theme.dart';
import '../widgets/common/cabecera_app.dart';
import '../widgets/equipos/tarjeta_accion_team.dart';
import '../widgets/equipos/formulario_tarea_equipo.dart';

/// Remote teams are scoped to the captured session; practice keeps its own flow.
class EquiposRemotosScreen extends StatefulWidget {
  const EquiposRemotosScreen({super.key, this.equipoId, this.api});
  final int? equipoId;
  final EquiposApiService? api;
  @override
  State<EquiposRemotosScreen> createState() => _EquiposRemotosScreenState();
}

class _EquiposRemotosScreenState extends State<EquiposRemotosScreen> {
  late final _api = widget.api ?? EquiposApiService();
  late final _epoch = UsuariosStore.sessionVersion.value;
  late final _uid = UsuariosStore.usuarioActual!.id;
  late final _token = UsuariosStore.token!;
  dynamic _data;
  bool _loading = true, _busy = false;
  String? _error;
  bool get _active => mounted && _epoch == UsuariosStore.sessionVersion.value;
  String get _path => widget.equipoId == null ? '' : '/${widget.equipoId}';
  @override
  void initState() {
    super.initState();
    // Capture before the first asynchronous response, not on first use later.
    _epoch;
    _uid;
    _token;
    UsuariosStore.sessionVersion.addListener(_sessionChanged);
    _load();
  }

  void _sessionChanged() {
    if (mounted) {
      setState(() {
        _data = null;
        _loading = false;
        _error = 'La sesión cambió. Abre Equipos desde tu cuenta actual.';
      });
    }
  }

  @override
  void dispose() {
    UsuariosStore.sessionVersion.removeListener(_sessionChanged);
    _api.close();
    super.dispose();
  }

  Future<void> _load() async {
    if (!_active) return;
    try {
      final data = await _api.request(_path, _token);
      if (_active) {
        setState(() {
          _data = data;
          _error = null;
        });
        if (widget.equipoId != null) await EstadisticasStore.instancia.load();
      }
    } catch (e) {
      if (_active) setState(() => _error = _message(e));
    } finally {
      if (_active) setState(() => _loading = false);
    }
  }

  String _message(Object e) => e is StateError
      ? e.message.toString()
      : 'No se pudo conectar. Reintenta.';

  Future<void> _mutate(
    String path,
    Map<String, dynamic>? data, {
    bool patch = false,
  }) async {
    if (_busy || !_active) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await _api.request(
        path,
        _token,
        method: patch ? 'PATCH' : 'POST',
        data: data,
      );
      if (!_active) return;
      if (result['estadisticas'] != null) {
        EstadisticasStore.instancia.aplicar(
          Map<String, dynamic>.from(result['estadisticas']),
        );
      }
      await _load();
      if (_active && widget.equipoId == null && result['idEquipo'] != null) {
        await _open(result['idEquipo'] as int);
      }
    } catch (e) {
      if (_active) setState(() => _error = _message(e));
    } finally {
      if (_active) setState(() => _busy = false);
    }
  }

  Future<void> _open(int id) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => EquiposRemotosScreen(equipoId: id),
      ),
    );
    if (_active) await _load();
  }

  Future<void> _nameAction(
    String title,
    String path, {
    bool code = false,
  }) async {
    final value = await showDialog<String>(
      context: context,
      builder: (_) => _NombreDialog(
        title: title,
        code: code,
        maxLength: path.endsWith('proyectos') ? 100 : 50,
      ),
    );
    if (_active && value != null) {
      await _mutate(path, {code ? 'codigo' : 'nombre': value});
    }
  }

  Future<void> _assign(int project) async {
    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) =>
          FormularioTareaEquipo(miembros: _data['miembros'] as List),
    );
    if (_active && data != null) {
      await _mutate('$_path/proyectos/$project/tareas', data);
    }
  }

  Future<void> _complete(int task) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Terminaste tu parte?'),
        content: const Text(
          'No podrás desmarcarla. Cuando todos terminen, cada asignado recibirá los puntos completos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí, terminé'),
          ),
        ],
      ),
    );
    if (_active && ok == true) {
      await _mutate('$_path/tareas/$task/mi-parte', null, patch: true);
    }
  }

  Widget _panel(Widget child) => Card(
    margin: const EdgeInsets.only(bottom: 14),
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(22),
      side: const BorderSide(color: AppColors.fieldBorder),
    ),
    child: Padding(padding: const EdgeInsets.all(18), child: child),
  );

  List<Widget> _list() => [
    const Icon(Icons.groups_rounded, size: 58, color: AppColors.primary),
    const Text(
      'Espacio colaborativo',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: AppColors.primaryDark,
      ),
    ),
    const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Text(
        'Comparte objetivos. Cada persona aporta y el equipo avanza.',
        textAlign: TextAlign.center,
      ),
    ),
    TarjetaAccionTeam(
      icono: Icons.groups_rounded,
      titulo: 'Crear equipo',
      descripcion: 'Crea tu grupo y comparte el código de invitación.',
      iconoAccion: Icons.add,
      alTocar: () => _nameAction('Crear equipo', ''),
    ),
    const SizedBox(height: 12),
    TarjetaAccionTeam(
      icono: Icons.login,
      titulo: 'Unirse a un equipo',
      descripcion: 'Ingresa el código de 8 letras y números.',
      iconoAccion: Icons.key,
      alTocar: () => _nameAction('Código de invitación', '/unirse', code: true),
    ),
    const SizedBox(height: 24),
    if ((_data as List).isEmpty)
      const Text('Aún no tienes equipos. Crea uno o únete con un código.'),
    ...(_data as List).map(
      (e) => _panel(
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(child: Text(e['siglas'] as String)),
          title: Text(e['nombre'] as String),
          subtitle: Text(
            e['idCreador'] == _uid ? 'Líder del equipo' : 'Miembro',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _open(e['idEquipo'] as int),
        ),
      ),
    ),
  ];

  List<Widget> _detail() {
    final leader = _data['idCreador'] == _uid;
    final projects = _data['proyectos'] as List;
    return [
      Text(
        _data['nombre'] as String,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: AppColors.primaryDark,
        ),
      ),
      const SizedBox(height: 16),
      if (_data['codigo'] != null)
        _panel(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Invita a tu equipo'),
              Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      _data['codigo'] as String,
                      style: const TextStyle(
                        fontSize: 28,
                        letterSpacing: 3,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Copiar código',
                    icon: const Icon(Icons.copy),
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: _data['codigo'] as String),
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Código copiado')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      _panel(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Miembros',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Wrap(
              spacing: 6,
              children: (_data['miembros'] as List)
                  .map(
                    (m) => Chip(
                      avatar: Icon(
                        m['idUsu'] == _data['idCreador']
                            ? Icons.star_rounded
                            : Icons.person,
                        size: 18,
                      ),
                      label: Text('@${m['nickName']}'),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
      if (leader)
        FilledButton.icon(
          onPressed: () => _nameAction('Nuevo proyecto', '$_path/proyectos'),
          icon: const Icon(Icons.add),
          label: const Text('Crear proyecto'),
        ),
      if (projects.isEmpty)
        const Text('El líder todavía no te ha asignado tareas en un proyecto.'),
      for (final project in projects) ...[
        const SizedBox(height: 18),
        Text(
          project['nombre'] as String,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDark,
          ),
        ),
        if (leader)
          TextButton.icon(
            onPressed: () => _assign(project['idProyecto'] as int),
            icon: const Icon(Icons.add_task),
            label: const Text('Asignar tarea'),
          ),
        if (!(_data['tareas'] as List).any(
          (t) => t['idProyecto'] == project['idProyecto'],
        ))
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Este proyecto todavía no tiene tareas.'),
          ),
        ...(_data['tareas'] as List)
            .where((t) => t['idProyecto'] == project['idProyecto'])
            .map(_task),
      ],
    ];
  }

  Widget _task(dynamic t) {
    final people = t['participantes'] as List;
    final mine = people.where((p) => p['idUsu'] == _uid).firstOrNull;
    final done = t['completada'] == true || t['completada'] == 1;
    bool finished(dynamic p) => p['completada'] == true || p['completada'] == 1;
    final count = people.where(finished).length;
    return _panel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t['titulo'] as String,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if ((t['descripcion'] as String? ?? '').isNotEmpty)
            Text(t['descripcion'] as String),
          const SizedBox(height: 8),
          Text(
            'Prioridad ${t['prioridad']} · ${t['fechaFinalizacion'] ?? 'Sin fecha límite'}',
          ),
          Wrap(
            spacing: 6,
            children: (t['categorias'] as List)
                .map((id) => Chip(label: Text(categoriasEquipo[id] ?? '')))
                .toList(),
          ),
          Text(
            done
                ? '¡Tarea completada!'
                : '$count de ${people.length} partes completadas',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: people.isEmpty ? 0 : count / people.length,
          ),
          const SizedBox(height: 8),
          ...people.map(
            (p) => Text('${finished(p) ? '✓' : '○'} @${p['nickName']}'),
          ),
          if (!done && mine != null && !finished(mine))
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: FilledButton.icon(
                onPressed: () => _complete(t['idTarea'] as int),
                icon: const Icon(Icons.check),
                label: const Text('Marcar mi parte'),
              ),
            ),
          if (!done && mine != null && finished(mine))
            const Text('Tu parte está lista. Esperando al resto del equipo.'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          CabeceraApp(
            titulo: 'Equipos',
            alVolver: () => Navigator.maybePop(context),
          ),
          if (_busy) const LinearProgressIndicator(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  TextButton(
                    onPressed: _busy ? null : _load,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: AbsorbPointer(
                      absorbing: _busy,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(18),
                        children: _data == null
                            ? []
                            : widget.equipoId == null
                            ? _list()
                            : _detail(),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    ),
  );
}

class _NombreDialog extends StatefulWidget {
  const _NombreDialog({
    required this.title,
    required this.code,
    required this.maxLength,
  });
  final String title;
  final bool code;
  final int maxLength;
  @override
  State<_NombreDialog> createState() => _NombreDialogState();
}

class _NombreDialogState extends State<_NombreDialog> {
  final _controller = TextEditingController();
  final _form = GlobalKey<FormState>();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    scrollable: true,
    content: Form(
      key: _form,
      child: TextFormField(
        controller: _controller,
        autofocus: true,
        maxLength: widget.code ? 8 : widget.maxLength,
        textCapitalization: widget.code
            ? TextCapitalization.characters
            : TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: widget.code ? 'Código' : 'Nombre',
        ),
        validator: (s) => widget.code
            ? RegExp(r'^[A-Z0-9]{8}$').hasMatch((s ?? '').trim().toUpperCase())
                  ? null
                  : 'Escribe los 8 caracteres'
            : (s ?? '').trim().isEmpty
            ? 'Escribe un nombre'
            : null,
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: () {
          if (_form.currentState!.validate()) {
            Navigator.pop(
              context,
              widget.code
                  ? _controller.text.trim().toUpperCase()
                  : _controller.text.trim(),
            );
          }
        },
        child: const Text('Continuar'),
      ),
    ],
  );
}
