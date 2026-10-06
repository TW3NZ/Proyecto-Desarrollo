import 'package:flutter/foundation.dart';

import '../models/tarea_modelo.dart';
import 'estadisticas_store.dart';

class TareasStore extends ChangeNotifier {
  TareasStore._();

  static final TareasStore instancia = TareasStore._();

  final List<NuevaTarea> _tareas = [];

  List<NuevaTarea> get tareas => List.unmodifiable(_tareas);

  void agregarTarea(NuevaTarea tarea) {
    _tareas.add(tarea);
    notifyListeners();
  }

  void alternarCompletada(NuevaTarea tarea) {
    if (!_tareas.contains(tarea)) return;

    final estabaCompletada = tarea.completada;

    tarea.completada = !tarea.completada;

    // Solo otorgar puntos cuando pasa de NO completada a completada.
    if (!estabaCompletada && tarea.completada) {
      EstadisticasStore.instancia.procesarTareaCompletada(tarea);
    }

    notifyListeners();
  }
}