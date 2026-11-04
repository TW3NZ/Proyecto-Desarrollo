import 'package:flutter/foundation.dart';

import '../models/actividad_team.dart';
import '../models/equipo_modelo.dart';

/// Datos de trabajo temporales compartidos por las pantallas de cada Team.
class TeamTrabajoStore extends ChangeNotifier {
  TeamTrabajoStore._();
  static final TeamTrabajoStore instancia = TeamTrabajoStore._();

  final Map<String, List<TareaTeam>> _tareas = {};
  final Map<String, List<ActividadTeam>> _actividades = {};

  List<TareaTeam> tareas(Equipo equipo) {
    return _tareas.putIfAbsent(equipo.id, () {
      final titulos = equipo.tareas.isEmpty ? <String>[] : equipo.tareas;
      final peso = titulos.isEmpty ? 0.0 : 100.0 / titulos.length;
      final responsables = <String, String>{};
      for (final asignacion in equipo.asignaciones) {
        final partes = asignacion.split(' — ');
        if (partes.length < 2) continue;
        final miembro = partes[1].split(' (').first.trim();
        responsables[partes.first.trim()] = miembro;
      }
      return [
        for (var i = 0; i < titulos.length; i++)
          TareaTeam(
            id: '${equipo.id}-task-$i',
            titulo: titulos[i],
            responsableId:
                responsables[titulos[i]] ??
                (equipo.creadorId.isEmpty
                    ? (equipo.integrantes.isEmpty
                          ? ''
                          : equipo.integrantes.first)
                    : equipo.creadorId),
            fechaInicio: equipo.fechaInicio,
            fechaEntrega: equipo.fechaFin,
            peso: peso,
          ),
      ];
    });
  }

  List<ActividadTeam> actividades(Equipo equipo) =>
      List.unmodifiable(_actividades.putIfAbsent(equipo.id, () => []));

  double progreso(Equipo equipo) {
    final activas = tareas(equipo).where((t) => !t.archivada).toList();
    if (activas.isEmpty) return 0;
    final sumaPesos = activas.fold<double>(0, (s, t) => s + t.peso);
    if (sumaPesos <= 0) return 0;
    return activas.fold<double>(0, (s, t) => s + t.peso * t.progreso / 100) *
        100 /
        sumaPesos;
  }

  void guardarTarea(Equipo equipo, TareaTeam tarea) {
    final lista = tareas(equipo);
    final indice = lista.indexWhere((t) => t.id == tarea.id);
    if (indice < 0) {
      final existentes = lista.where((t) => !t.archivada).toList();
      final nuevoPeso = tarea.peso.clamp(0, 100).toDouble();
      final sumaExistentes = existentes.fold<double>(0, (s, t) => s + t.peso);
      if (existentes.isNotEmpty) {
        for (final existente in existentes) {
          existente.peso = sumaExistentes <= 0
              ? (100 - nuevoPeso) / existentes.length
              : existente.peso * (100 - nuevoPeso) / sumaExistentes;
        }
      }
      tarea.peso = nuevoPeso;
      lista.add(tarea);
    } else {
      lista[indice] = tarea;
    }
    _normalizarPesos(equipo);
    notifyListeners();
  }

  void eliminarTarea(Equipo equipo, TareaTeam tarea) {
    // La tarea queda archivada para mantener la referencia de su historial.
    tarea.archivada = true;
    _normalizarPesos(equipo);
    notifyListeners();
  }

  void actualizarProgreso(Equipo equipo, TareaTeam tarea, int progreso) {
    tarea.progreso = progreso.clamp(0, 100).toInt();
    notifyListeners();
  }

  void publicar(
    Equipo equipo,
    TareaTeam tarea,
    String miembroId,
    String descripcion,
  ) {
    final lista = _actividades.putIfAbsent(equipo.id, () => []);
    lista.add(
      ActividadTeam(
        id: '${DateTime.now().microsecondsSinceEpoch}',
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

  void _normalizarPesos(Equipo equipo) {
    final activas = tareas(equipo).where((t) => !t.archivada).toList();
    if (activas.isEmpty) return;
    final total = activas.fold<double>(0, (s, t) => s + t.peso);
    if (total <= 0) {
      for (final tarea in activas) {
        tarea.peso = 100 / activas.length;
      }
    } else {
      for (final tarea in activas) {
        tarea.peso = tarea.peso * 100 / total;
      }
    }
  }
}
