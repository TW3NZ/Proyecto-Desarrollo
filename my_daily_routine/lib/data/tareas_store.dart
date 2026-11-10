import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/tarea_modelo.dart';
import 'estadisticas_store.dart';
import 'id_temporal_store.dart';

class TareasStore extends ChangeNotifier {
  TareasStore({
    Future<String?> Function()? read,
    Future<void> Function(String)? write,
    Future<void> Function(String)? publishWidget,
  }) : _read =
           read ?? (() => SharedPreferencesAsync().getString(preferenceKey)),
       _write =
           write ??
           ((value) =>
               SharedPreferencesAsync().setString(preferenceKey, value)),
       _publishWidgetOverride = publishWidget;

  static final TareasStore instancia = TareasStore();
  static const preferenceKey = 'tareas.v1';
  static const _widgetProvider = 'TareasWidgetProvider';
  static const _widgetDataKey = 'tareas_json';

  final Future<String?> Function() _read;
  final Future<void> Function(String) _write;
  final Future<void> Function(String)? _publishWidgetOverride;
  final List<NuevaTarea> _tareas = [];
  Future<void> _pending = Future<void>.value();
  Future<void>? _loading;

  bool loadFailed = false;

  List<NuevaTarea> get tareas => List.unmodifiable(_tareas);

  /// Recupera las tareas locales y publica la instantánea que usa el widget.
  /// No borra la instantánea si la lectura falla, para no perder el progreso
  /// que ya estaba visible en la pantalla de inicio.
  Future<void> inicializarWidget() async {
    await load();
    if (loadFailed) return;
    await _sincronizar();
  }

  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    try {
      final raw = await _read();
      if (raw != null) {
        final decoded = jsonDecode(raw);
        if (decoded is! List) throw const FormatException();
        final restored = <NuevaTarea>[];
        for (final item in decoded) {
          if (item is! Map) continue;
          final tarea = _tareaDesdeJson(Map<String, dynamic>.from(item));
          if (tarea != null) restored.add(tarea);
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
    _tareas.add(tarea);
    notifyListeners();
    return _sincronizar();
  }

  Future<void> eliminarTarea(NuevaTarea tarea) {
    if (!_tareas.remove(tarea)) return Future<void>.value();
    notifyListeners();
    return _sincronizar();
  }

  Future<void> alternarCompletada(NuevaTarea tarea) {
    if (!_tareas.contains(tarea)) return Future<void>.value();

    final estabaCompletada = tarea.completada;
    tarea.completada = !tarea.completada;

    if (!estabaCompletada && tarea.completada) {
      EstadisticasStore.instancia.procesarTareaCompletada(tarea);
    }

    notifyListeners();
    return _sincronizar();
  }

  Future<void> alternarCompletadaPorIndice(int indice) {
    if (indice < 0 || indice >= _tareas.length) return Future<void>.value();
    return alternarCompletada(_tareas[indice]);
  }

  /// Persiste la lista y actualiza el widget en serie. Si una actualización
  /// falla, la cadena se recupera para que el siguiente cambio vuelva a
  /// intentarlo, en lugar de quedar bloqueada para siempre.
  Future<void> _sincronizar() {
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
          await _write(tareasJson);
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
