/// Valores de progreso y preferencias de aura asociados a una cuenta.
///
/// `usuarioId` funciona como referencia a la identidad propietaria de estas
/// estadísticas y puede usarse como clave primaria compartida en la base de
/// datos futura.
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
