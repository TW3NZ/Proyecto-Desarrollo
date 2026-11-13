# Publicar el backend en Render mediante Web Service

**Actualización 2026-11-13:** el usuario solicitó conectar también el panel HTML a
Render. Para habilitarlo, cambia `ADMIN_ENABLED` a `true` y configura autenticación
y CORS según [la guía del panel](admin.md). Los valores `false` de esta guía
describen el despliegue inicial con el panel desactivado.

## 1. Preparar GitHub

Render descargará el código de `TW3NZ/Proyecto-Desarrollo`, rama `master`.
Primero hay que subir los cambios de preparación del despliegue a esa rama.
No subir `backend/.env` ni `.tools/avatar-flutter.json`: contienen secretos.
La base de datos sigue en Aiven; este despliegue no crea ni reinicializa tablas.

## 2. Crear el servicio desde cero

En [Render](https://dashboard.render.com/), conecta GitHub y permite acceso al repositorio.
Selecciona **New → Web Service**, conecta `TW3NZ/Proyecto-Desarrollo` y configura
los siguientes campos. Esta es la modalidad elegida para el proyecto; la configuración
se guarda directamente en el formulario de Render.

| Campo | Valor |
| --- | --- |
| Name | `my-daily-rutine-api` (o un nombre disponible) |
| Branch | `master` |
| Language | Python 3 |
| Root Directory | **Vacío** |
| Build Command | `pip install -r backend/requirements.txt` |
| Start Command | `python -m uvicorn backend.app:app --host 0.0.0.0 --port $PORT` |
| Instance Type | Free, para pruebas |
| Health Check Path | `/health` |

En Region elige, si está disponible, la región más cercana a tu servicio Aiven.
El Health Check Path puede aparecer dentro de Advanced o en Settings del servicio.

Root Directory debe quedar vacío porque los imports son `backend.*`.
`$PORT` es una variable de Render: no reemplazarla por el puerto local ni añadir `--reload`.

## 3. Variables de entorno en Render

En Environment añade las siguientes variables. Se guardan en Render, no en GitHub
ni en el código Flutter. Render no recibe automáticamente tu `.env` local.

| Variable | Valor |
| --- | --- |
| `PYTHON_VERSION` | `3.12.16` |
| `ADMIN_ENABLED` | `false` |
| `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, `DB_NAME` | Copiar los valores actuales de `backend/.env` |
| `DB_SSL_CA` | Certificado PEM completo de Aiven, como se indica abajo |
| `OPENAI_API_KEY` | Clave del backend |
| `OPENAI_AVATAR_MODEL` | `gpt-4.1-mini`, o el valor que ya usas |
| `AVATAR_SERVICE_TOKEN` | Token del servicio, mínimo 24 caracteres; debe coincidir con Flutter |
| `SECRET_KEY` | Clave aleatoria de mínimo 32 caracteres, generada con el comando de abajo |
| `ALGORITHM` | `HS256` |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | `120` |

Para generar una clave JWT manualmente desde la raíz del proyecto:

```powershell
.\.venv\Scripts\python.exe -c "import secrets; print(secrets.token_urlsafe(48))"
```

En el campo de valor de `DB_SSL_CA` pega desde `-----BEGIN CERTIFICATE-----` hasta
`-----END CERTIFICATE-----`, conservando saltos de línea reales. **No** incluyas
`DB_SSL_CA=`, las comillas exteriores del `.env` ni caracteres literales `\n`.
El backend verifica el certificado y el nombre del servidor usando ese PEM.
No hacen falta ADMIN_USER ni ADMIN_PASSWORD porque `/admin` estará deshabilitado.

También puedes usar **Add from .env** para importar las variables de tu archivo local
en Render. Antes de desplegar, cambia `ADMIN_ENABLED` a `false`, añade `PYTHON_VERSION`,
revisa el PEM y elimina las variables `ADMIN_USER`, `ADMIN_PASSWORD` y
`ADMIN_ALLOWED_ORIGINS` de la configuración remota. No modifiques el `.env` local
para desactivar el panel: ese valor corresponde únicamente a Render.

## 4. Desplegar y comprobar

Pulsa **Deploy Web Service** y espera a que el servicio aparezca Live. Usa la URL HTTPS que Render
asigne realmente; el siguiente nombre es solo un ejemplo:

```powershell
$backendUrl = 'https://TU-SERVICIO.onrender.com'
Invoke-RestMethod "$backendUrl/health"
Start-Process "$backendUrl/docs"
```

`/health` devuelve `{"status":"ok"}`: confirma que FastAPI arrancó, **no** que Aiven
o OpenAI estén conectados. `/admin` debe devolver 404 en Render.
Para verificar Aiven de extremo a extremo, inicia sesión con una cuenta existente
desde `/docs` en `POST /auth/login/user`; no publiques contraseñas en capturas.
También puedes registrar una cuenta de prueba desde la app y confirmar su fila con
el panel local. El registro sí escribe datos reales. La prueba con una foto desde
la app consume la cuota correspondiente de OpenAI.

Si Aiven tiene una lista de IP permitidas, autoriza los rangos de salida del servicio
que Render muestra en su información de conexión. Conserva TLS activado.

## 5. Apuntar Flutter al servidor

URL desplegada comunicada por el usuario el 2026-11-13:
`https://my-daily-rutine.onrender.com`. La configuración local de debug
`.tools/avatar-flutter.json` apunta a ella para usuarios, tareas y fotos,
conservando el token existente. El mismo token debe estar configurado en Render.

En el archivo local ignorado `.tools/avatar-flutter.json` conserva el token y cambia
las dos URLs por la URL real del servicio, sin `/docs`, `/health` ni `/avatar/suggest`:

```json
{
  "API_URL": "https://TU-SERVICIO.onrender.com",
  "AVATAR_API_URL": "https://TU-SERVICIO.onrender.com",
  "AVATAR_API_TOKEN": "MISMO_VALOR_DE_AVATAR_SERVICE_TOKEN"
}
```

Detén y reinicia la app; hot reload no actualiza los valores de compilación.
El debug configurado en VS Code carga ese archivo. Para ejecutarlo manualmente:

```powershell
cd my_daily_routine
flutter run --dart-define-from-file=../.tools/avatar-flutter.json
```

Para compilar directamente un APK con esta configuración, desde `my_daily_routine`:

```powershell
flutter build apk --release --dart-define-from-file=../.tools/avatar-flutter.json
```

El APK se genera en `build/app/outputs/flutter-apk/app-release.apk`. El token del
servicio se incluye en la app y puede extraerse: esta configuración sirve para
pruebas controladas. Antes de distribución pública conviene sustituirlo por acceso
autenticado por usuario y límites de uso. Nunca incluir OPENAI_API_KEY, DB_PASSWORD
ni SECRET_KEY en la configuración Flutter.

## Diagnóstico

- `No module named backend`: dejar Root Directory vacío y usar el Start Command indicado.
- Error PEM/certificado: revisar saltos de línea y contenido completo de DB_SSL_CA.
- Tiempo de espera MySQL: revisar host, puerto y acceso de red en Aiven.
- 503 de autenticación: revisar SECRET_KEY y ALGORITHM.
- 401 de avatar: verificar que los tokens del servidor y Flutter coincidan.
- Primera petición lenta: Free se duerme después de 15 minutos sin tráfico y puede
  tardar alrededor de un minuto en despertar. Abre `/health` y espera antes de probar
  la app. Esto puede superar los tiempos de espera del cliente.

## Decisiones de preparación — 2026-11-13

- Solicitud del usuario: desplegar desde cero en Render mediante **New → Web Service**.
- Configuración mediante el formulario de Render, documentada aquí; se retiró la
  plantilla Blueprint de la preparación inicial para mantener una única vía de despliegue.
- Se conserva Aiven existente; Free es una opción de pruebas, no una promesa de disponibilidad.
- `/health` comprueba solo el proceso para no consumir OpenAI ni consultar MySQL
  en cada sondeo. El panel continúa local mediante `ADMIN_ENABLED=false` en Render.
- Pendientes externos: conectar la cuenta de Render, cargar secretos, realizar el
  despliegue real y verificar login y foto contra su URL. Preparar archivos no implica
  que el servicio ya esté publicado.

Referencias: [FastAPI en Render](https://render.com/docs/deploy-fastapi),
[variables de entorno](https://render.com/docs/configure-environment-variables),
[Python](https://render.com/docs/python-version),
[limitaciones Free](https://render.com/docs/free).
