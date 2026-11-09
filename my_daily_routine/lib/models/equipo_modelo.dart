/// Espacio de trabajo que agrupa usuarios y proyectos.
class Equipo {
  Equipo({
    required this.id,
    required this.nombre,
    required this.siglas,
    required this.creadorId,
    required this.miembros,
    this.imagen,
  }) : assert(miembros.any((m) => m.usuarioId == creadorId));

  final int id;
  final String nombre;
  final String siglas;
  final String? imagen;
  final int creadorId;
  final List<MiembroEquipo> miembros;
}

/// Pertenencia de un usuario al equipo (tabla MIEMBRO_EQUIPO).
class MiembroEquipo {
  const MiembroEquipo({
    required this.id,
    required this.equipoId,
    required this.usuarioId,
  });

  final int id;
  final int equipoId;
  final int usuarioId;
}
