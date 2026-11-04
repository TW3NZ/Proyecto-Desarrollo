import '../models/equipo_modelo.dart';

/// Fuente temporal compartida para los equipos creados durante esta sesión.
class EquiposStore {
  EquiposStore._();

  static final List<Equipo> _equipos = [];
  static int _siguienteIdProyecto = 0;

  static List<Equipo> get equipos => List.unmodifiable(_equipos);

  static String generarProyectoId() {
    _siguienteIdProyecto++;
    return 'P${DateTime.now().microsecondsSinceEpoch}-$_siguienteIdProyecto';
  }

  static void agregar(Equipo equipo) => _equipos.add(equipo);
}
