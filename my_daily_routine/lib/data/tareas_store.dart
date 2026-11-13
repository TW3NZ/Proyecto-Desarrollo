import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/tarea_modelo.dart';
import '../services/tareas_api_service.dart';
import 'estadisticas_store.dart';
import 'id_temporal_store.dart';
import 'usuarios_store.dart';

class TareasStore extends ChangeNotifier {
  TareasStore({
    Future<String?> Function()? read,
    Future<void> Function(String)? write,
    Future<void> Function(String)? publishWidget,
    TareasApiService? api,
  }) : _read =
           read ?? (() => SharedPreferencesAsync().getString(preferenceKey)),
       _write =
           write ??
           ((value) =>
               SharedPreferencesAsync().setString(preferenceKey, value)),
       _publishWidgetOverride = publishWidget,
       _api = api ?? TareasApiService() {
    UsuariosStore.sessionVersion.addListener(_reset);
  }

  void _reset() {
    _loading = null;
    _tareas.clear();
    _enProceso.clear();
    loadFailed = false;
    notifyListeners();
    _pending = _pending
        .then((_) => _publicarWidget('[]'))
        .catchError((Object _) {});
  }

  @override
  void dispose() {
    UsuariosStore.sessionVersion.removeListener(_reset);
    super.dispose();
  }

  static final TareasStore instancia = TareasStore();
  static const preferenceKey = 'tareas.v1';
  static const _widgetProvider = 'TareasWidgetProvider';
  static const _widgetDataKey = 'tareas_json';

  final Future<String?> Function() _read;
  final Future<void> Function(String) _write;
  final Future<void> Function(String)? _publishWidgetOverride;
  final TareasApiService _api;
  final Set<int> _enProceso = {};
  final List<NuevaTarea> _tareas = [];
  Future<void> _pending = Future<void>.value();
  Future<void>? _loading;

  bool loadFailed = false;

  List<NuevaTarea> get tareas => List.unmodifiable(_tareas);

  /// Recupera las tareas de la cuenta y publica la instantánea del widget.
  /// No borra la instantánea si la lectura falla, para no perder el progreso
  /// que ya estaba visible en la pantalla de inicio.
  Future<void> inicializarWidget() async {
    await load();
    if (loadFailed) return;
    await _sincronizar();
  }

  Future<void> load() => _loading ??= _load();

  Future<void> refresh() {
    _loading = null;
    return load();
  }

  Future<void> _load() async {
    final epoch = UsuariosStore.sessionVersion.value;
    if (_esUsuarioReal()) {
      try {
        final restored = await _api.obtenerTareas(token: UsuariosStore.token!);
        if (epoch != UsuariosStore.sessionVersion.value) return;
        _tareas
          ..clear()
          ..addAll(restored);
        loadFailed = false;
        notifyListeners();
        await _sincronizar();
      } catch (_) {
        if (epoch == UsuariosStore.sessionVersion.value) {
          loadFailed = true;
          _loading = null;
          notifyListeners();
        }
        rethrow;
      }
      return;
    }
    try {
      final raw = await _read();
      if (epoch != UsuariosStore.sessionVersion.value) return;
      if (raw != null) {
        final decoded = jsonDecode(raw);
        if (decoded is! List) throw const FormatException();
        final restored = <NuevaTarea>[];
        for (final item in decoded) {
          if (item is! Map) continue;
          final tarea = _tareaDesdeJson(Map<String, dynamic>.from(item));
          if (tarea != null && tarea.usuarioId <= 0) restored.add(tarea);
        }
        _tareas
          ..clear()
          ..addAll(restored);
        IdTemporalStore.reservar(restored.map((tarea) => tarea.id));
      }
      loadFailed = false;
    } catch (_) {
      loadFailed = true;
    } finally {
      notifyListeners();
    }
  }

  Future<void> agregarTarea(NuevaTarea tarea) {
    if (_esUsuarioReal() &&
        tarea.usuarioId != UsuariosStore.usuarioActual?.id) {
      return Future<void>.value();
    }
    _tareas.add(tarea);
    notifyListeners();
    return _sincronizar();
  }

  Future<void> eliminarTarea(NuevaTarea tarea) {
    if (_esUsuarioReal()) {
      throw StateError('El borrado remoto no esta disponible.');
    }
    if (!_tareas.remove(tarea)) return Future<void>.value();
    notifyListeners();
    return _sincronizar();
  }

  Future<void> alternarCompletada(NuevaTarea tarea) async {
    if (!_tareas.contains(tarea)) return;
    if (_enProceso.contains(tarea.id)) return;

    final epoch = UsuariosStore.sessionVersion.value;
    final estabaCompletada = tarea.completada;
    final usuarioReal = _esUsuarioReal();

    // Para un usuario real, una tarea completada no se puede desmarcar
    // (no existe endpoint que sincronice esa operación).
    if (usuarioReal && estabaCompletada) return;

    // "Completar" de un usuario real: sincronizar primero (pesimista).
    if (usuarioReal && !estabaCompletada) {
      final token = UsuariosStore.token;
      if (token == null || token.isEmpty) return;
      _enProceso.add(tarea.id);
      try {
        final stats = await _api.completarTarea(
          idTarea: tarea.id,
          token: token,
        );
        if (epoch != UsuariosStore.sessionVersion.value) return;
        EstadisticasStore.instancia.aplicar(stats);
      } finally {
        _enProceso.remove(tarea.id);
      }
    }

    tarea.completada = !estabaCompletada;

    if (!estabaCompletada && tarea.completada) {
      EstadisticasStore.instancia.procesarTareaCompletada(tarea);
    }

    notifyListeners();
    await _sincronizar();
  }

  bool _esUsuarioReal() =>
      (UsuariosStore.usuarioActual?.id ?? UsuariosStore.idUsuarioPractica) > 0;

  Future<void> alternarCompletadaPorIndice(int indice) {
    if (indice < 0 || indice >= _tareas.length) return Future<void>.value();
    return alternarCompletada(_tareas[indice]);
  }

  /// Persiste la lista y actualiza el widget en serie. Si una actualización
  /// falla, la cadena se recupera para que el siguiente cambio vuelva a
  /// intentarlo, en lugar de quedar bloqueada para siempre.
  Future<void> _sincronizar() {
    final remote = _esUsuarioReal();
    final epoch = UsuariosStore.sessionVersion.value;
    final tareasJson = jsonEncode(_tareas.map(_tareaAJson).toList());
    final widgetJson = jsonEncode(
      _tareas
          .map(
            (tarea) => {
              'id': tarea.id,
              'titulo': tarea.titulo,
              'prioridad': tarea.prioridad.name,
              'completada': tarea.completada,
            },
          )
          .toList(),
    );

    _pending = _pending
        .then((_) async {
          if (epoch != UsuariosStore.sessionVersion.value) return;
          if (!remote) await _write(tareasJson);
          await _publicarWidget(widgetJson);
        })
        .catchError((Object error, StackTrace stack) {
          FlutterError.reportError(
            FlutterErrorDetails(
              exception: error,
              stack: stack,
              library: 'TareasStore',
              context: ErrorDescription('actualizando las tareas y el widget'),
            ),
          );
        });
    return _pending;
  }

  Future<void> _publicarWidget(String widgetJson) async {
    final override = _publishWidgetOverride;
    if (override != null) {
      await override(widgetJson);
      return;
    }
    if (defaultTargetPlatform != TargetPlatform.android) return;

    final saved = await HomeWidget.saveWidgetData<String>(
      _widgetDataKey,
      widgetJson,
    );
    if (saved != true) {
      throw StateError('No se pudo guardar la instantánea del widget.');
    }
    final updated = await HomeWidget.updateWidget(androidName: _widgetProvider);
    if (updated != true) {
      throw StateError('No se pudo solicitar la actualización del widget.');
    }
  }

  static Map<String, Object?> _tareaAJson(NuevaTarea tarea) => {
    'id': tarea.id,
    'proyectoId': tarea.proyectoId,
    'usuarioId': tarea.usuarioId,
    'titulo': tarea.titulo,
    'categorias': tarea.categorias.map((categoria) => categoria.name).toList(),
    'prioridad': tarea.prioridad.name,
    'descripcion': tarea.descripcion,
    'fecha': tarea.fecha.toIso8601String(),
    'fechaFinalizacion': tarea.fechaFinalizacion?.toIso8601String(),
    'responsableId': tarea.responsableId,
    'completada': tarea.completada,
  };

  static NuevaTarea? _tareaDesdeJson(Map<String, dynamic> json) {
    final id = json['id'];
    final usuarioId = json['usuarioId'];
    final titulo = json['titulo'];
    if (id is! int || usuarioId is! int || titulo is! String) return null;
    if (titulo.trim().isEmpty) return null;

    final prioridad = PrioridadTarea.values.firstWhere(
      (value) => value.name == json['prioridad'],
      orElse: () => PrioridadTarea.media,
    );
    final categorias = <CategoriaTarea>{};
    final rawCategorias = json['categorias'];
    if (rawCategorias is List) {
      for (final raw in rawCategorias) {
        for (final value in CategoriaTarea.values) {
          if (value.name == raw) categorias.add(value);
        }
      }
    }

    DateTime? fecha(Object? value) =>
        value is String ? DateTime.tryParse(value) : null;

    return NuevaTarea(
      id: id,
      proyectoId: json['proyectoId'] is int ? json['proyectoId'] as int : null,
      usuarioId: usuarioId,
      titulo: titulo,
      categorias: Set.unmodifiable(categorias),
      prioridad: prioridad,
      descripcion: json['descripcion'] is String
          ? json['descripcion'] as String
          : '',
      fecha: fecha(json['fecha']) ?? DateTime.now(),
      fechaFinalizacion: fecha(json['fechaFinalizacion']),
      responsableId: json['responsableId'] is int
          ? json['responsableId'] as int
          : null,
      completada: json['completada'] == true,
    );
  }
}
