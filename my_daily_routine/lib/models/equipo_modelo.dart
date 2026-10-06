/// Un team al que pertenece el usuario (lo que se muestra en "Tus teams activos").
///
/// Más adelante se le pueden agregar `codigo`, `miembros`, `creadoPor`, etc.,
/// o convertirlo en el modelo definitivo con `toJson` / `fromJson`.
class Equipo {
  final String id;
  final String nombre;

  /// Letras que se muestran dentro del círculo, por ejemplo "UTB".
  final String siglas;

  final int miembrosConectados;

  const Equipo({
    required this.id,
    required this.nombre,
    required this.siglas,
    this.miembrosConectados = 0,
  });
}
