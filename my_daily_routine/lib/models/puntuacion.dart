import 'tarea_modelo.dart';

/// Mirrors the server only for the offline practice account.
double puntosTarea(
  PrioridadTarea prioridad,
  int pendientes, {
  bool vencida = false,
}) {
  final factor = switch (prioridad) {
    PrioridadTarea.baja => 0.8,
    PrioridadTarea.media => 1.0,
    PrioridadTarea.alta => 1.2,
  };
  return (vencida ? -10 : 30 / (pendientes < 1 ? 1 : pendientes)) * factor;
}
