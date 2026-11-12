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

  static CategoriaTarea? desdeId(int id) => switch (id) {
    1 => CategoriaTarea.educacion,
    2 => CategoriaTarea.finanzas,
    3 => CategoriaTarea.salud,
    4 => CategoriaTarea.disciplina,
    _ => null,
  };
}

/// Id en la tabla `Categoria` de MySQL. El orden del enum no coincide con los
/// ids sembrados, así que el mapeo es explícito.
extension CategoriaTareaApi on CategoriaTarea {
  int get idCategoria => switch (this) {
    CategoriaTarea.educacion => 1,
    CategoriaTarea.finanzas => 2,
    CategoriaTarea.salud => 3,
    CategoriaTarea.disciplina => 4,
  };
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
  final int id;
  final int? proyectoId;
  final int usuarioId;
  final String titulo;
  final Set<CategoriaTarea> categorias;
  final PrioridadTarea prioridad;
  final String descripcion;
  final DateTime fecha;
  final DateTime? fechaFinalizacion;
  final int? responsableId;
  bool completada;

  NuevaTarea({
    required this.id,
    this.proyectoId,
    required this.usuarioId,
    required this.titulo,
    required this.categorias,
    required this.prioridad,
    this.descripcion = '',
    DateTime? fecha,
    this.fechaFinalizacion,
    this.responsableId,
    this.completada = false,
  }) : fecha = fecha ?? DateTime.now();

  factory NuevaTarea.fromApiJson(Map<String, dynamic> json) {
    final categorias = <CategoriaTarea>{};
    final rawCategorias = json['categorias'];
    if (rawCategorias is List) {
      for (final raw in rawCategorias) {
        if (raw is int) {
          final categoria = CategoriaTarea.desdeId(raw);
          if (categoria != null) categorias.add(categoria);
        }
      }
    }

    return NuevaTarea(
      id: json['idTarea'] as int,
      usuarioId: json['idUsu'] as int,
      proyectoId: json['idProyecto'] as int?,
      responsableId: json['idResponsable'] as int?,
      titulo: json['Titulo'] as String,
      prioridad: _prioridadDesdeApi(json['Prioridad']),
      descripcion: json['Descripcion'] as String? ?? '',
      fecha: _fechaDesdeApi(json['Fecha']) ?? DateTime.now(),
      fechaFinalizacion: _fechaDesdeApi(json['Fecha_Fin']),
      completada: json['Completada'] == true,
      categorias: Set.unmodifiable(categorias),
    );
  }
}

PrioridadTarea _prioridadDesdeApi(Object? valor) => switch (valor) {
  'Alta' => PrioridadTarea.alta,
  'Baja' => PrioridadTarea.baja,
  _ => PrioridadTarea.media,
};

DateTime? _fechaDesdeApi(Object? valor) =>
    valor is String ? DateTime.tryParse(valor) : null;
