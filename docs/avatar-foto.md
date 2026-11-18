# Avatar desde una foto

Flujo: **Tu avatar → Crear desde una foto → Tomar foto / Elegir foto → Analizar foto → Usar propuesta → Guardar cambios**. Elegir la foto no la envía. Volver sin usar la propuesta conserva el borrador anterior; usarla permite seguir editando antes de guardar.

El análisis lo hace el backend desplegado en Render, que ya tiene configurada la clave de OpenAI. No hace falta ejecutar nada en local.

## Configuración de la app

En `.tools/avatar-flutter.json` (raíz del repositorio, ignorado por Git):

```json
{
  "API_URL": "https://my-daily-rutine.onrender.com",
  "AVATAR_API_URL": "https://my-daily-rutine.onrender.com"
}
```

Después de iniciar sesión, la app envía su JWT en `Authorization: Bearer`; no se necesita un token compartido en el cliente. Cambiar estos valores exige reiniciar la app, no solo hot reload.

## Autorización y tratamiento de la imagen

- La propuesta se solicita solo desde el botón **Analizar foto**, tras el aviso de envío.
- El backend acepta JPEG, PNG y WebP de hasta 4 MB, limita dimensiones, elimina metadatos al recodificar y envía a OpenAI un JPEG de hasta 1024 píxeles por lado.
- El servidor no persiste ni registra las fotos. La cámara puede dejar archivos temporales en la caché administrada por el sistema o el plugin; no se guardan en `AvatarStore`.
- `store=false` no garantiza por sí solo la ausencia de retención del proveedor; consulta [los controles de datos de OpenAI](https://developers.openai.com/api/docs/guides/your-data).
- La propuesta solo se guarda al pulsar **Guardar cambios**. La apariencia se guarda por cuenta en MySQL y no se copia entre usuarios.
- Si Android cierra el proceso durante la cámara, al volver a esta pantalla se intenta recuperar la selección; nunca se envía automáticamente. Un borrador no guardado puede perderse al terminar el proceso.

## Alcance

- OpenAI elige colores, peinado, ojos, nariz y boca entre los valores existentes. No genera imágenes nuevas. El parecido es aproximado y depende del catálogo y de la iluminación.
- El personaje Hombre/Mujer, la complexión, la altura y el movimiento siguen siendo manuales. Los atributos no visibles quedan como estaban.

## Backend local (alternativa)

Para desarrollar contra un backend propio, inicia FastAPI y configura la app con `API_URL` y `AVATAR_API_URL` en `http://10.0.2.2:8000` (emulador Android). En ese caso el `.env` local necesita `OPENAI_API_KEY`, `OPENAI_AVATAR_MODEL` y un `AVATAR_SERVICE_TOKEN` de al menos 24 caracteres; opcionalmente, `AVATAR_API_TOKEN` en el JSON de Flutter con el mismo valor. Nunca pases `backend/.env` como archivo de configuración de Flutter: contiene la clave privada de OpenAI.

El HTTP local está permitido solo en la variante Android debug. Para teléfono físico, iOS o builds de distribución se requiere HTTPS. La instalación y ejecución del backend se describen en [backend/README.md](../backend/README.md).

## Verificación

```bash
.venv/bin/python -m pytest backend/test -q
cd my_daily_routine
flutter test test/avatar_photo_test.dart test/avatar_test.dart test/avatar_face_test.dart test/avatar_hairstyles_test.dart
```

Las pruebas usan respuestas simuladas: no suben imágenes personales ni consumen la API. La revisión de cámara, permisos y parecido con una foto real requiere ejecución manual en un dispositivo.

Referencias de implementación: [imágenes de entrada](https://developers.openai.com/api/docs/guides/images-vision), [salidas estructuradas](https://developers.openai.com/api/docs/guides/structured-outputs) e [image_picker](https://pub.dev/packages/image_picker).
