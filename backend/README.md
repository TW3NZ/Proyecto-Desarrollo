# Backend de My Daily Routine

Servicio FastAPI único del proyecto: registro e inicio de sesión con JWT, tareas personales y de equipo, estadísticas por cuenta, apariencia del avatar, propuesta de atributos desde una foto y panel administrativo de consulta. La persistencia está en MySQL (Aiven).

## Producción: Render

El backend desplegado está en `https://my-daily-rutine.onrender.com` y es el que usa la app por defecto.

- Salud: `GET /health` → `{"status":"ok"}`
- Documentación interactiva: `https://my-daily-rutine.onrender.com/docs`
- Esquema OpenAPI: `https://my-daily-rutine.onrender.com/openapi.json`

Las variables de entorno se configuran en **Render → Environment** y no se versionan. La guía completa de despliegue está en [docs/render.md](docs/render.md). Para publicar cambios basta con subir el código a la rama conectada; no se requiere un servidor local.

## Endpoints

| Método y ruta | Descripción |
| --- | --- |
| `GET /health` | Estado del servicio |
| `POST /usuarios` | Registro de cuenta |
| `POST /auth/login/user` | Inicio de sesión; devuelve JWT |
| `GET /tareas` | Tareas del usuario autenticado |
| `POST /tareas` | Crear tarea personal |
| `PATCH /tareas/{idTarea}/completar` | Completar tarea personal |
| `GET /usuarios/me/estadisticas` | Estadísticas de la cuenta |
| `PUT /usuarios/me/estadisticas/preferencias` | Preferencias de las estadísticas |
| `GET /usuarios/me/avatar` | Apariencia guardada |
| `PUT /usuarios/me/avatar` | Guardar apariencia |
| `GET /equipos` | Equipos del usuario |
| `POST /equipos` | Crear equipo |
| `POST /equipos/unirse` | Unirse con código |
| `GET /equipos/{equipo_id}` | Detalle del equipo y sus proyectos |
| `POST /equipos/{equipo_id}/proyectos` | Crear proyecto |
| `POST /equipos/{equipo_id}/proyectos/{proyecto_id}/tareas` | Asignar tarea a miembros |
| `PATCH /equipos/{equipo_id}/tareas/{tarea_id}/mi-parte` | Marcar la parte propia |
| `POST /avatar/suggest` | Propuesta de avatar desde una foto |
| `/admin` y `/admin/api/*` | Panel administrativo de consulta |

Los contratos con cuerpos y códigos de respuesta están en:

- [Usuarios y login](docs/usuarios.md)
- [Tareas](docs/tareas.md)
- [Perfil, estadísticas y avatar](docs/perfil.md)
- [Equipos y proyectos](docs/equipos.md)
- [Panel administrativo](docs/admin.md)

Las rutas protegidas obtienen el usuario del `sub` del JWT; nunca de un campo enviado por el cliente. La regla de pertenencia a equipos y la idempotencia de las recompensas se validan en el backend y en el esquema.

## Organización

```text
backend/
├── app.py                 # Punto de entrada y todas las rutas FastAPI
├── requirements.txt       # Dependencias
├── .env.example           # Plantilla de variables (sin credenciales reales)
├── core/                  # Hash Argon2 y utilidades del JWT
├── models/                # Modelos Pydantic
├── database/              # Conexión MySQL y consultas
├── admin/                 # HTML, CSS y JavaScript del panel
├── utils/                 # Configuración, generadores y diagnósticos
├── docs/                  # Contratos de la API y guía de despliegue
└── test/                  # Pruebas con pytest
```

## Ejecutar en local (alternativa de desarrollo)

Requisitos: Python 3.12 o superior, dependencias de `requirements.txt` y acceso a la base MySQL. La clave de OpenAI solo es necesaria para probar la función de fotos.

### 1. Entorno virtual

macOS o Linux, desde la raíz del repositorio:

```bash
python3 -m venv .venv
.venv/bin/python -m pip install -r backend/requirements.txt
```

En Windows (PowerShell):

```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r backend/requirements.txt
```

### 2. Variables de entorno

Copia `backend/.env.example` a `backend/.env` y completa los valores. El archivo `.env` está ignorado por Git y nunca debe subirse.

```dotenv
OPENAI_API_KEY=TU_CLAVE_PRIVADA
OPENAI_AVATAR_MODEL=gpt-4.1-mini
AVATAR_SERVICE_TOKEN=UN_TOKEN_ALEATORIO_DE_AL_MENOS_24_CARACTERES

DB_HOST=HOST_DE_TU_SERVICIO.aivencloud.com
DB_PORT=10472
DB_USER=avnadmin
DB_PASSWORD='TU_CONTRASEÑA'
DB_NAME=BD_my_daily_routine
DB_SSL_CA="-----BEGIN CERTIFICATE-----
CONTENIDO_COMPLETO_DEL_CERTIFICADO_CA
-----END CERTIFICATE-----"
DB_SSL_VERIFY_CERT=true
DB_CONNECT_TIMEOUT=10

SECRET_KEY=UN_SECRETO_ALEATORIO_DE_AL_MENOS_32_CARACTERES
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=120
```

- `DB_NAME` corresponde a la base creada por `database/BD_My_Daily_Routine.sql`, no a `defaultdb`.
- El certificado de Aiven se pega completo dentro de `DB_SSL_CA`, entre comillas y conservando los saltos de línea. No se usa una ruta a otro archivo.
- `SECRET_KEY` firma el JWT y es independiente de `AVATAR_SERVICE_TOKEN`.
- El backend carga `backend/.env` automáticamente, sin importar el directorio desde el que se ejecute. Reinicia el servidor tras editarlo.
- No copies estas variables a Flutter ni al APK.

### 3. Esquema y migraciones

Aplica el esquema de `database/BD_My_Daily_Routine.sql` en una base nueva y después las migraciones de `database/migrations/` en orden. La base de producción ya las tiene aplicadas.

### 4. Iniciar el servidor

Desde la raíz:

```bash
.venv/bin/python -m uvicorn backend.app:app --host 127.0.0.1 --port 8000
```

En Windows:

```powershell
.\.venv\Scripts\python.exe -m uvicorn backend.app:app --host 127.0.0.1 --port 8000
```

Espera `Application startup complete`. La documentación local queda en `http://127.0.0.1:8000/docs`.

Para usar este backend desde el emulador Android, la URL es `http://10.0.2.2:8000` (el host visto desde el emulador). En un teléfono físico se necesita una dirección HTTPS alcanzable o un túnel. El HTTP plano solo está permitido en compilaciones debug de Android.

### 5. Panel administrativo

El explorador de la base está en `/admin`. Usa `ADMIN_USER`, `ADMIN_PASSWORD`, `ADMIN_ALLOWED_ORIGINS` y `ADMIN_ENABLED` del entorno. Es de solo lectura y no expone contraseñas ni hashes. Instrucciones en [docs/admin.md](docs/admin.md).

## Pruebas

Desde la raíz:

```bash
.venv/bin/python -m pytest backend/test -q
```

Las pruebas usan respuestas simuladas y no llaman a OpenAI ni a MySQL, salvo las marcadas como integración, que se habilitan con `RUN_MYSQL_TESTS=1` y revierten sus datos.

Prueba real opcional de la clave de OpenAI y del endpoint de fotos (consume una petición):

```bash
.venv/bin/python -m backend.utils.check_connection
```

## Problemas habituales

- **`/health` no responde:** el servicio de Render puede estar iniciando; espera y reintenta.
- **Error de conexión desde la app:** revisa que `API_URL` apunte a la URL de Render y reinicia la app después de cambiar los `dart-define`.
- **401 en el login:** verifica las credenciales o el estado de la base.
- **La función de fotos responde 503:** falta `OPENAI_API_KEY` en el servidor.
- **429 al analizar una foto:** cuota de OpenAI agotada o servicio ocupado.
- **`ModuleNotFoundError`:** ejecuta desde la raíz e instala las dependencias en `.venv`.

No existe una cuenta de prueba incluida en el backend: las cuentas se crean con `POST /usuarios`.
