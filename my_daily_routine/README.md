# Daily Routine

Para generar e instalar el APK de prueba consulta [la guía de compilación](../scripts/README.md).

Aplicación Flutter para organizar tareas y seguir su cumplimiento. Consulta el [README principal](../README.md) para el estado completo de la aplicación.

## Acceso de prueba sin registro

- **Usuario:** `admin` (o `admin@mydailyroutine.local`).
- **Contraseña:** `12345678`.

Escribe estas credenciales en el login y pulsa **Iniciar sesión**. La cuenta local de práctica viene incluida y sigue disponible al reiniciar la app. Consulta [los detalles del acceso de prueba](../README.md#credenciales-de-prueba-ingresar-sin-registrarse).

## Avatar desde una foto

En **Tu avatar → Crear desde una foto** puedes tomar o elegir una imagen, enviarla para análisis y revisar la propuesta antes de guardarla. Requiere ejecutar el backend y configurar la URL/token de desarrollo: [instrucciones completas](../docs/avatar-foto.md). La clave de OpenAI se configura únicamente en el servidor.

## Widget de tareas para Android

La aplicación incluye un widget nativo para Android. Muestra el nombre **Daily Routine**, el total de tareas pendientes, el porcentaje completado, una barra de progreso y una lista desplazable con las tareas y su prioridad. Tocar una fila abre la aplicación y marca la tarea usando el `TareasStore` existente; el widget se actualiza con el nuevo progreso. La cabecera no muestra el icono de la app.

### Cómo agregarlo a la pantalla de inicio

1. Mantén pulsado un espacio vacío de la pantalla de inicio del dispositivo.
2. Abre **Widgets** en el menú del launcher.
3. Busca **Daily Routine**.
4. Mantén pulsado el widget y arrástralo a la pantalla de inicio. Ajusta su tamaño si el launcher lo permite.

La lista se desplaza verticalmente dentro del espacio que le asigne el launcher; la cabecera permanece fija. La prioridad usa los valores ya guardados en cada tarea: alta, media o baja. El tamaño visible puede variar según el launcher.

Las tareas personales se guardan localmente, por lo que el progreso del widget se conserva al reiniciar la app. Las cuentas y las estadísticas siguen en memoria. Marcar desde el widget abre la app para aplicar la acción al `TareasStore` compartido con las pantallas y las estadísticas. Esta primera versión solo está disponible en Android.

Consulta [las decisiones y límites del widget](../docs/decisiones-widget-tareas.md) para más detalles de implementación.
