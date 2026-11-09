import 'tarea_modelo.dart';

/// Proyecto independiente asociado a un único equipo.
class Proyecto {
  Proyecto({
    required this.id,
    required this.equipoId,
    required this.nombre,
    required this.meta,
    required this.categoria,
    required this.fechaInicio,
    required this.fechaFin,
    required List<NuevaTarea> tareas,
    this.imagen,
  }) : tareas = List.of(tareas);

  final int id;
  final int equipoId;
  final String nombre;
  final String meta;
  final CategoriaTarea categoria;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String? imagen;
  final List<NuevaTarea> tareas;
}
