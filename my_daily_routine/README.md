# Daily Routine

Aplicación Flutter para organizar tareas y seguir su cumplimiento. Consulta el [README principal](../README.md) para el estado completo de la aplicación.

## Widget de tareas para Android

La aplicación incluye un widget nativo para Android. Muestra el nombre **Daily Routine**, el total de tareas pendientes, el porcentaje completado, una barra de progreso y una lista desplazable con las tareas y su prioridad. Tocar una fila abre la aplicación y marca la tarea usando el `TareasStore` existente; el widget se actualiza con el nuevo progreso. La cabecera no muestra el icono de la app.

### Cómo agregarlo a la pantalla de inicio

1. Mantén pulsado un espacio vacío de la pantalla de inicio del dispositivo.
2. Abre **Widgets** en el menú del launcher.
3. Busca **Daily Routine**.
4. Mantén pulsado el widget y arrástralo a la pantalla de inicio. Ajusta su tamaño si el launcher lo permite.

La lista se desplaza verticalmente dentro del espacio que le asigne el launcher; la cabecera permanece fija. La prioridad usa los valores ya guardados en cada tarea: alta, media o baja. El tamaño visible puede variar según el launcher.

Las tareas se mantienen en memoria, como en el resto de la aplicación; no se añade persistencia permanente. Si Android termina el proceso de la app, el `TareasStore` volátil se reinicia y las tareas desaparecen. Por esa razón, marcar desde el widget abre la app para aplicar la acción al almacén compartido con las pantallas y las estadísticas. Esta primera versión solo está disponible en Android.

Consulta [las decisiones y límites del widget](../docs/decisiones-widget-tareas.md) para más detalles de implementación.
