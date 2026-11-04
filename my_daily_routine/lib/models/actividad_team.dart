class TareaTeam {
  TareaTeam({
    required this.id,
    required this.titulo,
    required this.responsableId,
    required this.fechaInicio,
    required this.fechaEntrega,
    required this.peso,
    this.descripcion = '',
    this.progreso = 0,
    this.archivada = false,
  });

  final String id;
  String titulo;
  String descripcion;
  String responsableId;
  DateTime fechaInicio;
  DateTime fechaEntrega;
  double peso;
  int progreso;
  bool archivada;
}

class ActividadTeam {
  const ActividadTeam({
    required this.id,
    required this.integranteId,
    required this.tareaId,
    required this.fecha,
    required this.porcentaje,
    required this.descripcion,
  });

  final String id;
  final String integranteId;
  final String tareaId;
  final DateTime fecha;
  final int porcentaje;
  final String descripcion;
}
