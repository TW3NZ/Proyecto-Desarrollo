import 'package:flutter/foundation.dart';

import '../models/actividad_team.dart';
import '../models/proyecto_modelo.dart';
import '../models/tarea_modelo.dart';
import 'id_temporal_store.dart';

/// Progreso colaborativo, separado de los datos originales de NuevaTarea.
class TeamTrabajoStore extends ChangeNotifier {
  TeamTrabajoStore._();
  static final TeamTrabajoStore instancia = TeamTrabajoStore._();
  final Map<int, List<TareaTeam>> _tareas = {};
  final Map<int, List<ActividadTeam>> _actividades = {};

  List<TareaTeam> tareas(
    Proyecto proyecto,
  ) => _tareas.putIfAbsent(proyecto.id, () {
    final peso = proyecto.tareas.isEmpty ? 0.0 : 100.0 / proyecto.tareas.length;
    return [
      for (var i = 0; i < proyecto.tareas.length; i++)
        TareaTeam(
          id: proyecto.tareas[i].id,
          proyectoId: proyecto.id,
          usuarioId: proyecto.tareas[i].usuarioId,
          titulo: proyecto.tareas[i].titulo,
          descripcion: proyecto.tareas[i].descripcion,
          responsableId:
              proyecto.tareas[i].responsableId ?? proyecto.tareas[i].usuarioId,
          fechaInicio: proyecto.tareas[i].fecha,
          fechaEntrega:
              proyecto.tareas[i].fechaFinalizacion ?? proyecto.tareas[i].fecha,
          peso: peso,
          progreso: proyecto.tareas[i].completada ? 100 : 0,
          categorias: Set.of(proyecto.tareas[i].categorias),
          prioridad: proyecto.tareas[i].prioridad,
        ),
    ];
  });

  List<ActividadTeam> actividades(Proyecto proyecto) =>
      List.unmodifiable(_actividades.putIfAbsent(proyecto.id, () => []));
  double progreso(Proyecto proyecto) {
    final activas = tareas(proyecto).where((t) => !t.archivada).toList();
    final pesos = activas.fold<double>(0, (s, t) => s + t.peso);
    if (activas.isEmpty || pesos <= 0) return 0;
    return activas.fold<double>(0, (s, t) => s + t.peso * t.progreso / 100) *
        100 /
        pesos;
  }

  void guardarTarea(Proyecto proyecto, TareaTeam tarea) {
    final lista = tareas(proyecto);
    final index = lista.indexWhere((t) => t.id == tarea.id);
    if (index < 0) {
      tarea.peso = tarea.peso.clamp(0, 100).toDouble();
      lista.add(tarea);
    } else {
      lista[index] = tarea;
    }
    final original = proyecto.tareas.indexWhere((t) => t.id == tarea.id);
    final datos = NuevaTarea(
      id: tarea.id,
      proyectoId: proyecto.id,
      usuarioId: tarea.usuarioId,
      titulo: tarea.titulo,
      categorias: Set.unmodifiable(tarea.categorias),
      prioridad: tarea.prioridad,
      descripcion: tarea.descripcion,
      fecha: tarea.fechaInicio,
      fechaFinalizacion: tarea.fechaEntrega,
      responsableId: tarea.responsableId,
      completada: original >= 0 && proyecto.tareas[original].completada,
    );
    if (original >= 0) {
      proyecto.tareas[original] = datos;
    } else {
      proyecto.tareas.add(datos);
    }
    _normalizar(proyecto);
    notifyListeners();
  }

  void eliminarTarea(Proyecto proyecto, TareaTeam tarea) {
    tarea.archivada = true;
    _normalizar(proyecto);
    notifyListeners();
  }

  void actualizarProgreso(Proyecto proyecto, TareaTeam tarea, int progreso) {
    tarea.progreso = progreso.clamp(0, 100);
    notifyListeners();
  }

  void publicar(
    Proyecto proyecto,
    TareaTeam tarea,
    int miembroId,
    String descripcion,
  ) {
    final lista = _actividades.putIfAbsent(proyecto.id, () => []);
    lista.add(
      ActividadTeam(
        id: IdTemporalStore.generar(),
        proyectoId: proyecto.id,
        integranteId: miembroId,
        tareaId: tarea.id,
        fecha: DateTime.now(),
        porcentaje: tarea.progreso,
        descripcion: descripcion.trim(),
      ),
    );
    lista.sort((a, b) => b.fecha.compareTo(a.fecha));
    notifyListeners();
  }

  void _normalizar(Proyecto proyecto) {
    final activas = tareas(proyecto).where((t) => !t.archivada).toList();
    if (activas.isEmpty) return;
    final total = activas.fold<double>(0, (s, t) => s + t.peso);
    for (final t in activas) {
      t.peso = total <= 0 ? 100 / activas.length : t.peso * 100 / total;
    }
  }
}
