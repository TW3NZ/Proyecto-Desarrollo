import 'package:flutter/material.dart';

/// Categorías disponibles. Una tarea puede pertenecer a una o varias.
enum CategoriaTarea {
  educacion('Educación', Icons.school_rounded),
  salud('Salud', Icons.favorite_rounded),
  finanzas('Finanzas', Icons.savings_rounded),
  disciplina('Disciplina', Icons.bolt_rounded);

  final String etiqueta;
  final IconData icono;
  const CategoriaTarea(this.etiqueta, this.icono);
}

/// Prioridad de la tarea.
enum PrioridadTarea {
  baja('Baja'),
  media('Media'),
  alta('Alta');

  final String etiqueta;
  const PrioridadTarea(this.etiqueta);
}

/// Datos de una tarea creada por el usuario.
class NuevaTarea {
  final String titulo;
  final Set<CategoriaTarea> categorias;
  final PrioridadTarea prioridad;
  final String descripcion;
  final DateTime fecha;
  bool completada;

  NuevaTarea({
    required this.titulo,
    required this.categorias,
    required this.prioridad,
    this.descripcion = '',
    DateTime? fecha,
    this.completada = false,
  }) : fecha = fecha ?? DateTime.now();
}
