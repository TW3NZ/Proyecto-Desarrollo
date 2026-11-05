# Widget de tareas para Android

## 2026-11-04 — Primera versión nativa

### Acuerdo del usuario

Implementar un widget Android para Daily Routine que muestre tareas reales y su estado, con identidad azul/blanca. Se solicita usar `home_widget`, reutilizar el almacén de tareas y no conectar servicios remotos.

### Implementación inicial

- `TareasStore` es la fuente de verdad. Las tareas siguen en memoria y el widget recibe una instantánea para renderizar; no se añade FastAPI ni almacenamiento permanente.
- El widget mostraba el nombre, el número de pendientes, una cifra de completadas y hasta cinco títulos. Actualizaba la vista después de crear o completar tareas desde la app.
- Android/iOS no comparten una vista Flutter de widget: Android renderiza recursos nativos `RemoteViews` y la comunicación se realiza con `home_widget`.

## 2026-11-04 — Lista desplazable, prioridad e interacción

El usuario pidió mejorar el widget existente con cabecera azul, icono, porcentaje y barra de progreso, lista desplazable con prioridades, y selección por tarea. Aclaró que se debe conservar el almacén temporal y no añadir persistencia permanente. Para mantener sincronía sin duplicar el estado de las pantallas, eligió que tocar una tarea abra la app para aplicar el cambio con `TareasStore`.

### Implementación

- El proveedor existente ahora dibuja una cabecera azul con icono, nombre, contador de pendientes, porcentaje completado y barra de progreso.
- La lista usa `ListView` con `RemoteViewsService`, la colección nativa de Android que permite scroll vertical. La cabecera queda fija fuera de la colección.
- Las filas representan las tareas del almacén actual, conservan la prioridad del modelo (`alta`, `media`, `baja`) y distinguen las completadas con check y color atenuado.
- Al tocar una fila, Android lanza la app mediante la acción de `home_widget`; Dart aplica el índice recibido mediante `TareasStore.alternarCompletada`, que sigue actualizando estadísticas y widgets.
- El porcentaje y los contadores se recalculan desde toda la lista remitida por Flutter tras cada creación, eliminación o cambio de estado. `TareasStore` ofrece `eliminarTarea` para mantener esta actualización aunque la interfaz actual no tenga todavía un control de borrado.

### Límites y pendientes

- La tarea marcada abre la aplicación, según la alternativa elegida por el usuario. No se implementa una tarea ni un sistema de estado paralelo en código nativo.
- Las tareas viven en memoria: si Android termina el proceso de la app, se pierde el estado de `TareasStore`, y un toque frío del widget no puede recuperar una tarea que ya no existe en memoria. No se añadió persistencia para ocultar esta limitación.
- El launcher determina la altura del widget. La lista puede desplazarse dentro del espacio asignado, aunque gestos y recortes concretos dependen del launcher.
- La implementación y su apariencia deben validarse en un dispositivo Android; la compilación nativa no se pudo ejecutar durante esta sesión porque el entorno no permite escribir en el directorio externo de Gradle.
