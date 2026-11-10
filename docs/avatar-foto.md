# Avatar desde una foto

Flujo: **Tu avatar → Crear desde una foto → Tomar foto / Elegir foto → Analizar foto → Usar propuesta → Guardar cambios**. Elegir la foto no la envía. Volver sin usar la propuesta conserva el borrador anterior; usarla permite seguir editando antes de guardar.

## Ejecutar el servicio (PowerShell, desde la raíz)

Requiere Python 3.12 o superior con pip. Crear un entorno e instalar:

```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r backend/requirements.txt
$env:OPENAI_API_KEY = 'TU_CLAVE_DE_OPENAI'
$env:OPENAI_AVATAR_MODEL = 'gpt-4.1-mini'
$env:AVATAR_SERVICE_TOKEN = 'UN_TOKEN_LOCAL_ALEATORIO_DE_AL_MENOS_24_CARACTERES'
.\.venv\Scripts\python.exe -m uvicorn backend.app:app --host 127.0.0.1 --port 8000
```

Los valores mostrados son marcadores que debes reemplazar. `backend/.env.example` enumera las variables; el servicio lee el entorno y no carga `.env` automáticamente. No guardar claves reales en el repositorio. Si la clave ya está configurada en el entorno, no reemplazarla. Se usa Responses API con salida estructurada y `store=false`.

En otra terminal, usa el mismo token local (no la clave de OpenAI):

```powershell
cd my_daily_routine
flutter pub get
flutter run --dart-define=AVATAR_API_URL=http://10.0.2.2:8000 --dart-define=AVATAR_API_TOKEN=UN_TOKEN_LOCAL_ALEATORIO_DE_AL_MENOS_24_CARACTERES
```

`10.0.2.2` accede al equipo anfitrión desde el emulador Android. El HTTP local está permitido solo en la variante Android debug. Para teléfono físico, usar un servicio HTTPS alcanzable desde el dispositivo; iOS y builds de distribución deben usar HTTPS. Cambiar los `dart-define` requiere reiniciar la app, no solo hot reload. La cámara está disponible en Android/iOS; escritorio permite elegir archivo. El backend no habilita CORS: esta entrega se verifica como app móvil, no como despliegue web.

## Alcance y datos

- OpenAI elige colores, peinado, ojos, nariz y boca entre los valores existentes. No genera imágenes nuevas. El parecido es aproximado y depende del catálogo y de la iluminación.
- Personaje Hombre/Mujer y movimiento siguen siendo manuales. Los atributos no visibles quedan como estaban.
- El backend acepta JPEG, PNG y WebP de hasta 4 MB, limita dimensiones, elimina metadatos al recodificar y envía un JPEG de hasta 1024 píxeles por lado. No persiste ni registra las fotos. La cámara puede dejar archivos temporales en la caché administrada por el sistema/plugin; no se guardan en `AvatarStore`.
- El aviso de envío aparece antes de analizar. `store=false` no garantiza ausencia de retención por el proveedor: consultar [los controles de datos de OpenAI](https://developers.openai.com/api/docs/guides/your-data).
- La propuesta solo se guarda al pulsar **Guardar cambios**. El almacenamiento del avatar sigue siendo local al dispositivo, como el editor existente.
- Si Android cierra el proceso durante la cámara, al volver a abrir esta pantalla se intenta recuperar la selección; nunca se envía automáticamente. Un borrador no guardado puede perderse al terminar el proceso.

El token compartido es una barrera para pruebas locales, **no autenticación de usuarios para producción**: está incluido en la app de desarrollo. Antes de publicar este servicio se necesita autenticación real, cuotas por cuenta, límites de concurrencia/coste y HTTPS. No exponer este prototipo directamente a Internet.

## Verificación

```powershell
.\.venv\Scripts\python.exe -m pytest backend -q
cd my_daily_routine
flutter test test/avatar_photo_test.dart test/avatar_test.dart test/avatar_face_test.dart test/avatar_hairstyles_test.dart
```

Las pruebas usan respuestas simuladas: no suben imágenes personales ni consumen la API. La revisión de cámara/permisos en dispositivo y del parecido con una foto real requiere ejecución manual.

Referencias de implementación: [imágenes de entrada](https://developers.openai.com/api/docs/guides/images-vision), [salidas estructuradas](https://developers.openai.com/api/docs/guides/structured-outputs) e [image_picker](https://pub.dev/packages/image_picker).
