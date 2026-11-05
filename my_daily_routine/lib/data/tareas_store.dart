import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../models/tarea_modelo.dart';
import 'estadisticas_store.dart';

class TareasStore extends ChangeNotifier {
  TareasStore._();

  static final TareasStore instancia = TareasStore._();
  static const _widgetProvider = 'TareasWidgetProvider';

  final List<NuevaTarea> _tareas = [];
  Future<void> _widgetUpdates = Future<void>.value();

  List<NuevaTarea> get tareas => List.unmodifiable(_tareas);

  Future<void> inicializarWidget() => _actualizarWidget();

  void agregarTarea(NuevaTarea tarea) {
    _tareas.add(tarea);
    _actualizarWidget();
    notifyListeners();
  }

  void eliminarTarea(NuevaTarea tarea) {
    if (!_tareas.remove(tarea)) return;
    _actualizarWidget();
    notifyListeners();
  }

  void alternarCompletada(NuevaTarea tarea) {
    if (!_tareas.contains(tarea)) return;

    final estabaCompletada = tarea.completada;
    tarea.completada = !tarea.completada;

    if (!estabaCompletada && tarea.completada) {
      EstadisticasStore.instancia.procesarTareaCompletada(tarea);
    }

    _actualizarWidget();
    notifyListeners();
  }

  void alternarCompletadaPorIndice(int indice) {
    if (indice < 0 || indice >= _tareas.length) return;
    alternarCompletada(_tareas[indice]);
  }

  Future<void> _actualizarWidget() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;

    final resumen = jsonEncode(
      _tareas
          .map(
            (tarea) => {
              'titulo': tarea.titulo,
              'prioridad': tarea.prioridad.name,
              'completada': tarea.completada,
            },
          )
          .toList(),
    );
    _widgetUpdates = _widgetUpdates.then((_) async {
      await HomeWidget.saveWidgetData<String>('tareas_json', resumen);
      await HomeWidget.updateWidget(androidName: _widgetProvider);
    });
    await _widgetUpdates;
  }
}
