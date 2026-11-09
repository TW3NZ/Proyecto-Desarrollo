import 'package:flutter/foundation.dart';

import '../models/estadisticas.dart';
import '../models/tarea_modelo.dart';
import 'usuarios_store.dart';

class EstadisticasStore extends ChangeNotifier {
  EstadisticasStore._();

  static final EstadisticasStore instancia = EstadisticasStore._();

  final Map<int, Estadisticas> _porUsuario = {};

  int get _usuarioIdActual =>
      UsuariosStore.usuarioActual?.id ?? UsuariosStore.idUsuarioPractica;

  /// Estadísticas de la sesión actual (la cuenta de práctica si no hay sesión).
  Estadisticas get actual => paraUsuario(_usuarioIdActual);

  /// Obtiene o inicializa las estadísticas de una cuenta concreta.
  Estadisticas paraUsuario(int usuarioId) => _porUsuario.putIfAbsent(
    usuarioId,
    () => Estadisticas(usuarioId: usuarioId),
  );

  double get general => actual.general;

  double get inteligencia => actual.inteligencia;
  double get finanzas => actual.finanzas;
  double get salud => actual.salud;
  double get disciplina => actual.disciplina;

  bool get inteligenciaActiva => actual.inteligenciaActiva;
  bool get finanzasActiva => actual.finanzasActiva;
  bool get saludActiva => actual.saludActiva;
  bool get disciplinaActiva => actual.disciplinaActiva;

  void procesarTareaCompletada(NuevaTarea tarea) {
    if (tarea.categorias.isEmpty) return;

    final puntosTotales = _puntosPorPrioridad(tarea.prioridad);
    final puntosPorCategoria = puntosTotales / tarea.categorias.length;
    final estadisticas = actual;

    for (final categoria in tarea.categorias) {
      switch (categoria) {
        case CategoriaTarea.educacion:
          estadisticas.inteligencia = _sumarPuntos(
            estadisticas.inteligencia,
            puntosPorCategoria,
          );
          break;
        case CategoriaTarea.finanzas:
          estadisticas.finanzas = _sumarPuntos(
            estadisticas.finanzas,
            puntosPorCategoria,
          );
          break;
        case CategoriaTarea.salud:
          estadisticas.salud = _sumarPuntos(
            estadisticas.salud,
            puntosPorCategoria,
          );
          break;
        case CategoriaTarea.disciplina:
          estadisticas.disciplina = _sumarPuntos(
            estadisticas.disciplina,
            puntosPorCategoria,
          );
          break;
      }
    }

    notifyListeners();
  }

  double _puntosPorPrioridad(PrioridadTarea prioridad) {
    switch (prioridad) {
      case PrioridadTarea.baja:
        return 5;
      case PrioridadTarea.media:
        return 10;
      case PrioridadTarea.alta:
        return 15;
    }
  }

  double _sumarPuntos(double actual, double puntos) {
    final nuevoValor = actual + puntos;
    return nuevoValor >= 100 ? 100 : nuevoValor;
  }

  void cambiarInteligenciaActiva() {
    actual.inteligenciaActiva = !actual.inteligenciaActiva;
    notifyListeners();
  }

  void cambiarFinanzasActiva() {
    actual.finanzasActiva = !actual.finanzasActiva;
    notifyListeners();
  }

  void cambiarSaludActiva() {
    actual.saludActiva = !actual.saludActiva;
    notifyListeners();
  }

  void cambiarDisciplinaActiva() {
    actual.disciplinaActiva = !actual.disciplinaActiva;
    notifyListeners();
  }
}
