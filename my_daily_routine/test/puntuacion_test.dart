import 'package:flutter_test/flutter_test.dart';
import 'package:my_daily_routine/models/estadisticas.dart';
import 'package:my_daily_routine/models/puntuacion.dart';
import 'package:my_daily_routine/models/tarea_modelo.dart';

void main() {
  test('new user starts with every statistic and aura at 100', () {
    final stats = Estadisticas(usuarioId: 42);
    expect([
      stats.inteligencia,
      stats.finanzas,
      stats.salud,
      stats.disciplina,
      stats.general,
    ], everyElement(100));
  });
  test('practice reward decreases with pending count', () {
    expect(puntosTarea(PrioridadTarea.media, 1), 30);
    expect(puntosTarea(PrioridadTarea.media, 5), 6);
    expect(puntosTarea(PrioridadTarea.media, 10), 3);
    expect(puntosTarea(PrioridadTarea.alta, 1), 36);
    expect(puntosTarea(PrioridadTarea.baja, 1, vencida: true), -8);
  });
}
