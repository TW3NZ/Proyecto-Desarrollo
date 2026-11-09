import '../models/equipo_modelo.dart';

/// Fuente temporal compartida para los equipos creados durante esta sesión.
class EquiposStore {
  EquiposStore._();

  static final List<Equipo> _equipos = [];

  static List<Equipo> get equipos => List.unmodifiable(_equipos);

  static void agregar(Equipo equipo) => _equipos.add(equipo);
}
