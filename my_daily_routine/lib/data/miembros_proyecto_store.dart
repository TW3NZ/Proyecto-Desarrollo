import '../models/equipo_modelo.dart';
import '../models/miembro_proyecto.dart';

/// Registros temporales de MIEMBRO_PROYECTO, aislados por proyecto.
class MiembrosProyectoStore {
  MiembrosProyectoStore._();

  static final Map<int, List<MiembroProyecto>> _porProyecto = {};

  static List<MiembroProyecto> deProyecto(int proyectoId) =>
      List.unmodifiable(_porProyecto[proyectoId] ?? const []);

  static MiembroProyecto? buscar(int proyectoId, int miembroId) {
    for (final relacion in _porProyecto[proyectoId] ?? const <MiembroProyecto>[]) {
      if (relacion.miembroId == miembroId) return relacion;
    }
    return null;
  }

  static MiembroProyecto? buscarPorUsuario({
    required int proyectoId,
    required int usuarioId,
    required Iterable<MiembroEquipo> miembrosEquipo,
  }) {
    for (final miembro in miembrosEquipo) {
      if (miembro.usuarioId != usuarioId) continue;
      final relacion = buscar(proyectoId, miembro.id);
      if (relacion != null) return relacion;
    }
    return null;
  }

  static void guardarProyecto(
    int proyectoId,
    Iterable<MiembroProyecto> relaciones,
  ) {
    final registros = relaciones.toList(growable: false);
    final miembrosRegistrados = <int>{};
    for (final relacion in registros) {
      if (relacion.proyectoId != proyectoId) {
        throw ArgumentError.value(
          relacion.proyectoId,
          'relaciones',
          'Todas las pertenencias deben corresponder al proyecto indicado.',
        );
      }
      if (!miembrosRegistrados.add(relacion.miembroId)) {
        throw ArgumentError.value(
          relacion.miembroId,
          'relaciones',
          'Un miembro solo puede tener una pertenencia por proyecto.',
        );
      }
    }
    _porProyecto[proyectoId] = registros;
  }
}
