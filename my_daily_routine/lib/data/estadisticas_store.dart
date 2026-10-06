import 'package:flutter/foundation.dart';

import '../models/tarea_modelo.dart';

class EstadisticasStore extends ChangeNotifier {
  EstadisticasStore._();

  static final EstadisticasStore instancia = EstadisticasStore._();

  // Estadísticas del personaje
  double _inteligencia = 0;
  double _finanzas = 0;
  double _salud = 0;
  double _disciplina = 0;

  // Estadísticas activadas para calcular el aura
  bool _inteligenciaActiva = true;
  bool _finanzasActiva = true;
  bool _saludActiva = true;
  bool _disciplinaActiva = true;

  // General / Aura
  double get general {
    final estadisticasActivas = <double>[];

    if (_inteligenciaActiva) {
      estadisticasActivas.add(_inteligencia);
    }

    if (_finanzasActiva) {
      estadisticasActivas.add(_finanzas);
    }

    if (_saludActiva) {
      estadisticasActivas.add(_salud);
    }

    if (_disciplinaActiva) {
      estadisticasActivas.add(_disciplina);
    }

    if (estadisticasActivas.isEmpty) {
      return 0;
    }

    final suma = estadisticasActivas.reduce((a, b) => a + b);

    return suma / estadisticasActivas.length;
  }

  double get inteligencia => _inteligencia;
  double get finanzas => _finanzas;
  double get salud => _salud;
  double get disciplina => _disciplina;

  bool get inteligenciaActiva => _inteligenciaActiva;
  bool get finanzasActiva => _finanzasActiva;
  bool get saludActiva => _saludActiva;
  bool get disciplinaActiva => _disciplinaActiva;

  void procesarTareaCompletada(NuevaTarea tarea) {
    if (tarea.categorias.isEmpty) return;

    final puntosTotales = _puntosPorPrioridad(tarea.prioridad);

    final puntosPorCategoria =
        puntosTotales / tarea.categorias.length;

    for (final categoria in tarea.categorias) {
      switch (categoria) {
        case CategoriaTarea.educacion:
          _inteligencia = _sumarPuntos(
            _inteligencia,
            puntosPorCategoria,
          );
          break;

        case CategoriaTarea.finanzas:
          _finanzas = _sumarPuntos(
            _finanzas,
            puntosPorCategoria,
          );
          break;

        case CategoriaTarea.salud:
          _salud = _sumarPuntos(
            _salud,
            puntosPorCategoria,
          );
          break;

        case CategoriaTarea.disciplina:
          _disciplina = _sumarPuntos(
            _disciplina,
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

    if (nuevoValor >= 100) {
      return 100;
    }

    return nuevoValor;
  }

  void cambiarInteligenciaActiva() {
    _inteligenciaActiva = !_inteligenciaActiva;
    notifyListeners();
  }

  void cambiarFinanzasActiva() {
    _finanzasActiva = !_finanzasActiva;
    notifyListeners();
  }

  void cambiarSaludActiva() {
    _saludActiva = !_saludActiva;
    notifyListeners();
  }

  void cambiarDisciplinaActiva() {
    _disciplinaActiva = !_disciplinaActiva;
    notifyListeners();
  }
}