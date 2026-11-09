import 'tarea_modelo.dart';

class TareaTeam {
  TareaTeam({
    required this.id,
    required this.proyectoId,
    required this.usuarioId,
    required this.titulo,
    required this.responsableId,
    required this.fechaInicio,
    required this.fechaEntrega,
    required this.peso,
    required this.categorias,
    required this.prioridad,
    this.descripcion = '',
    this.progreso = 0,
    this.archivada = false,
  });

  final int id;
  final int proyectoId;
  final int usuarioId;
  String titulo;
  String descripcion;
  int responsableId;
  DateTime fechaInicio;
  DateTime fechaEntrega;
  double peso;
  int progreso;
  bool archivada;
  Set<CategoriaTarea> categorias;
  PrioridadTarea prioridad;
}

class ActividadTeam {
  const ActividadTeam({
    required this.id,
    required this.proyectoId,
    required this.integranteId,
    required this.tareaId,
    required this.fecha,
    required this.porcentaje,
    required this.descripcion,
  });

  final int id;
  final int proyectoId;
  final int integranteId;
  final int tareaId;
  final DateTime fecha;
  final int porcentaje;
  final String descripcion;
}
