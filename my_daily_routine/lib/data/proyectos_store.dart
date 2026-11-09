import '../models/proyecto_modelo.dart';

/// Almacenamiento temporal de proyectos durante la sesión.
class ProyectosStore {
  ProyectosStore._();
  static final List<Proyecto> _proyectos = [];

  static List<Proyecto> get proyectos => List.unmodifiable(_proyectos);
  static List<Proyecto> proyectosDeEquipo(int equipoId) =>
      List.unmodifiable(_proyectos.where((p) => p.equipoId == equipoId));
  static Proyecto? buscarPorId(int id) {
    for (final proyecto in _proyectos) {
      if (proyecto.id == id) return proyecto;
    }
    return null;
  }

  static void agregar(Proyecto proyecto) => _proyectos.add(proyecto);
}
