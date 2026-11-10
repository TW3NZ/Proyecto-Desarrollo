/// Genera IDs enteros temporales para los datos en memoria de esta sesión.
///
/// Los IDs negativos los distingue de los IDs definitivos positivos que
/// devolverá FastAPI. Un contador compartido evita colisiones entre entidades.
class IdTemporalStore {
  IdTemporalStore._();

  static int _siguienteId = -2;

  static int generar() => _siguienteId--;

  /// Evita reutilizar IDs ya recuperados de una persistencia local.
  static void reservar(Iterable<int> ids) {
    for (final id in ids) {
      if (id < 0 && id <= _siguienteId) _siguienteId = id - 1;
    }
  }
}
