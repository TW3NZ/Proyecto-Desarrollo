/// Valores de progreso y preferencias de aura asociados a una cuenta.
///
/// `usuarioId` identifica la cuenta propietaria. Para cuentas reales, los
/// valores proceden de MySQL y los puntos se calculan en el backend.
class Estadisticas {
  Estadisticas({
    required this.usuarioId,
    this.inteligencia = 0,
    this.finanzas = 0,
    this.salud = 0,
    this.disciplina = 0,
    this.inteligenciaActiva = true,
    this.finanzasActiva = true,
    this.saludActiva = true,
    this.disciplinaActiva = true,
  });

  final int usuarioId;

  double inteligencia;
  double finanzas;
  double salud;
  double disciplina;

  bool inteligenciaActiva;
  bool finanzasActiva;
  bool saludActiva;
  bool disciplinaActiva;

  double get general {
    final valoresActivos = <double>[
      if (inteligenciaActiva) inteligencia,
      if (finanzasActiva) finanzas,
      if (saludActiva) salud,
      if (disciplinaActiva) disciplina,
    ];

    if (valoresActivos.isEmpty) return 0;
    return valoresActivos.reduce((a, b) => a + b) / valoresActivos.length;
  }
}
