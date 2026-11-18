# My Daily Routine — aplicación Flutter

Aplicación móvil del proyecto My Daily Routine. Consulta el [README principal](../README.md) para la descripción completa, la arquitectura y las funcionalidades.

## Ejecutar conectada a Render

```bash
flutter pub get
flutter run --dart-define-from-file=../.tools/avatar-flutter.json
```

El archivo `.tools/avatar-flutter.json` se crea en la raíz del repositorio y contiene `API_URL` y `AVATAR_API_URL` apuntando a `https://my-daily-rutine.onrender.com`. Tras el login, la app usa el JWT de la cuenta; no se necesita token compartido ni clave de OpenAI. Los pasos completos están en el [README principal](../README.md#instalación-y-ejecución-con-el-backend-de-render).

Cada cambio en los `dart-define` requiere detener y volver a iniciar la app.

## Avatar desde una foto

En **Tu avatar → Crear desde una foto** puedes tomar o elegir una imagen, autorizar el envío y revisar la propuesta antes de guardarla. La clave de OpenAI está solo en el servidor y las fotos no se almacenan. Detalles en [la guía del avatar desde una foto](../docs/avatar-foto.md).

## Widget de tareas para Android

La aplicación incluye un widget nativo para Android. Muestra el nombre **Daily Routine**, el total de tareas pendientes, el porcentaje completado, una barra de progreso y una lista desplazable con las tareas y su prioridad.

Tocar una fila abre la aplicación. La lista se alimenta de la instantánea que publica la app y se actualiza con el progreso; el marcado de tareas se realiza dentro de la aplicación, donde las cuentas reales piden confirmación. Esta primera versión del widget solo está disponible en Android.

### Cómo agregarlo a la pantalla de inicio

1. Mantén pulsado un espacio vacío de la pantalla de inicio del dispositivo.
2. Abre **Widgets** en el menú del launcher.
3. Busca **Daily Routine**.
4. Mantén pulsado el widget y arrástralo a la pantalla de inicio. Ajusta su tamaño si el launcher lo permite.

La prioridad usa los valores guardados en cada tarea: alta, media o baja. El tamaño visible puede variar según el launcher. Consulta [las decisiones y límites del widget](../docs/decisiones-widget-tareas.md).

## Pruebas

```bash
flutter test
flutter analyze
```
