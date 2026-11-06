# Decisiones sobre tareas

## 2026-11-05 — Fecha de finalización opcional

El usuario pidió que una tarea pueda tener fecha de finalización y que sea opcional. Se conserva la fecha de creación existente y se añade una fecha independiente, elegible al crear la tarea y removible antes de guardarla. Sin fecha, la tarea conserva su flujo actual.

### Implementación

- `NuevaTarea.fechaFinalizacion` es nullable.
- El formulario permite elegir desde hoy hasta diez años adelante; dejar vacío o quitar la selección equivale a no fijar fecha.
- La tarjeta muestra la fecha si existe y la resalta en rojo cuando ya pasó y la tarea sigue pendiente. El detalle distingue fecha de creación y fecha de finalización.
- El almacén de tareas sigue siendo temporal en memoria, según el diseño existente.

Pendiente: permitir modificar la fecha después de crear una tarea, si se incorpora edición de tareas.
