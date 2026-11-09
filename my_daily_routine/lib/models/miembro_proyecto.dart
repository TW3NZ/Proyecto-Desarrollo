/// Rol de una pertenencia de equipo dentro de un proyecto.
enum RolProyecto { creador, administrador, integrante }

/// Participación de un miembro del equipo en un proyecto (MIEMBRO_PROYECTO).
class MiembroProyecto {
  const MiembroProyecto({
    required this.id,
    required this.miembroId,
    required this.proyectoId,
    required this.rol,
  });

  final int id;
  final int miembroId;
  final int proyectoId;
  final RolProyecto rol;
}

class PermisosProyecto {
  PermisosProyecto._();

  static bool puedeGestionarRoles(RolProyecto rol) =>
      rol == RolProyecto.creador;

  static bool puedeCambiarRol({
    required RolProyecto actor,
    required RolProyecto objetivo,
  }) => actor == RolProyecto.creador && objetivo != RolProyecto.creador;

  static bool puedeGestionarTareas(RolProyecto rol) =>
      rol == RolProyecto.creador || rol == RolProyecto.administrador;

  static bool puedeGestionarProyecto(RolProyecto rol) =>
      puedeGestionarTareas(rol);
}
