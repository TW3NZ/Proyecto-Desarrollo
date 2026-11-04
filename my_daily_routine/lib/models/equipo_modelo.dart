/// Un team al que pertenece el usuario (lo que se muestra en "Tus teams activos").
///
/// Más adelante se le pueden agregar `codigo`, `miembros`, `creadoPor`, etc.,
/// o convertirlo en el modelo definitivo con `toJson` / `fromJson`.
class Equipo {
  final String id;
  final String proyectoId;
  final String nombre;
  final String nombreProyecto;
  final String meta;
  final String categoria;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final List<String> tareas;
  final List<String> integrantes;
  final List<String> asignaciones;
  final String? imagen;
  final String creadorId;
  final List<MiembroEquipo> miembros;

  /// Letras que se muestran dentro del círculo, por ejemplo "UTB".
  final String siglas;

  final int miembrosConectados;

  Equipo({
    required this.id,
    this.proyectoId = '',
    required this.nombre,
    required this.siglas,
    this.miembrosConectados = 0,
    this.nombreProyecto = '',
    this.meta = '',
    this.categoria = '',
    DateTime? fechaInicio,
    DateTime? fechaFin,
    this.tareas = const [],
    this.integrantes = const [],
    this.asignaciones = const [],
    this.imagen,
    this.creadorId = '',
    this.miembros = const [],
  }) : fechaInicio = fechaInicio ?? DateTime(2000),
       fechaFin = fechaFin ?? DateTime(2000);
}

enum RolEquipo { creador, administrador, integrante }

class MiembroEquipo {
  const MiembroEquipo({
    required this.id,
    required this.nombre,
    required this.rol,
  });

  final String id;
  final String nombre;
  final RolEquipo rol;
}

/// Centraliza los permisos que se aplican a cada rol del equipo.
class PermisosEquipo {
  PermisosEquipo._();

  static bool puedeGestionarRoles(MiembroEquipo miembro) =>
      miembro.rol == RolEquipo.creador;

  static bool puedeGestionarProyecto(MiembroEquipo miembro) =>
      miembro.rol == RolEquipo.creador ||
      miembro.rol == RolEquipo.administrador;

  static bool puedeGestionarTareas(MiembroEquipo miembro) =>
      puedeGestionarProyecto(miembro);

  static bool puedeEditarProyecto(MiembroEquipo miembro) =>
      puedeGestionarProyecto(miembro);

  static bool puedeOrganizarActividades(MiembroEquipo miembro) =>
      puedeGestionarProyecto(miembro);

  static bool puedeAdministrarIntegrantes(MiembroEquipo miembro) =>
      puedeGestionarProyecto(miembro);

  static bool puedeParticipar(MiembroEquipo miembro) => true;

  static bool puedeCambiarRol({
    required MiembroEquipo actor,
    required MiembroEquipo objetivo,
  }) => puedeGestionarRoles(actor) && objetivo.rol != RolEquipo.creador;
}
