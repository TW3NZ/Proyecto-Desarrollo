# Backend de My Daily Rutine

Servicio FastAPI único para registro de usuarios, login con JWT y propuesta de atributos del avatar mediante OpenAI. Todas las rutas se ejecutan desde `backend.app:app` en el mismo puerto; la antigua carpeta `api/` se integró aquí.

## Organización

El explorador HTML de la base está en `/admin`; instrucciones en [docs/admin.md](docs/admin.md). Usa el mismo servidor y consulta tablas, registros, estructura y relaciones.

Sus archivos separados son `backend/admin/index.html`, `backend/admin/admin.css` y `backend/admin/admin.js`. Toda la API HTTP administrativa está en `backend/app.py`; el JavaScript recibe las tablas y registros mediante sus endpoints JSON.

```text
backend/
├── app.py                    # /usuarios, /auth/login/user y /avatar/suggest
├── requirements.txt          # Dependencias
├── .env                      # Credenciales locales, ignoradas por Git
├── .env.example              # Plantilla sin credenciales reales
├── README.md
├── core/                     # Hash Argon2 y JWT
├── models/                   # Modelos Pydantic de usuarios, tareas y categorías
├── database/                 # Conector MySQL con TLS y consultas Python
├── docs/usuarios.md          # Contratos de registro y login
├── utils/                    # Configuración, generadores y diagnósticos
│   ├── __init__.py
│   ├── settings.py           # Carga del entorno
│   └── check_connection.py   # Prueba real opcional con OpenAI
└── test/
    ├── __init__.py
    ├── test_app.py
    └── test_settings.py
```

## 1. Preparar el entorno

Los comandos siguientes son para **PowerShell**, desde la raíz del repositorio (`Proyecto-Desarrollo`), no desde `backend`.

Si ya existe `.venv`, conserva ese entorno. Para una instalación nueva con Python 3.12 o superior:

```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r backend/requirements.txt
```

Si el entorno fue creado con `uv` y no tiene pip, en este equipo puedes instalar las dependencias con:

```powershell
.\.tools\uv\uv.exe pip install --python .venv/Scripts/python.exe -r backend/requirements.txt
```

Configura `backend/.env` siguiendo `.env.example`. Si ya existe, no lo sobrescribas:

```dotenv
OPENAI_API_KEY=TU_CLAVE_PRIVADA
OPENAI_AVATAR_MODEL=gpt-4.1-mini
AVATAR_SERVICE_TOKEN=UN_TOKEN_LOCAL_ALEATORIO_DE_AL_MENOS_24_CARACTERES
```

Reemplaza los marcadores. El backend carga automáticamente ese archivo y sus valores tienen prioridad sobre variables del sistema. Reinicia el servidor si lo cambias. La clave de OpenAI pertenece exclusivamente al servidor.

## Configuración de Aiven MySQL

En `backend/.env` se reservan las siguientes variables, exclusivamente para el servidor:

```dotenv
DB_HOST=HOST_DE_TU_SERVICIO.aivencloud.com
DB_PORT=10472
DB_USER=avnadmin
DB_PASSWORD='TU_CONTRASEÑA'
DB_NAME=BD_my_daily_routine
DB_SSL_CA="-----BEGIN CERTIFICATE-----
CONTENIDO_COMPLETO_DEL_CERTIFICADO_CA_DE_AIVEN
-----END CERTIFICATE-----"
DB_SSL_VERIFY_CERT=true
DB_CONNECT_TIMEOUT=10
```

Confirma host, puerto y usuario con tu servicio. Completa la contraseña localmente y pega el certificado CA completo de Aiven en `DB_SSL_CA`, entre comillas dobles y conservando sus saltos de línea. No pongas una ruta: por decisión del usuario, el certificado se mantiene explícito en el `.env`. `DB_NAME` corresponde a la base creada por `database/BD_My_Daily_Routine.sql`, no a `defaultdb`. El timeout está expresado en segundos. No copies estas variables al archivo de configuración de Flutter ni al APK.

**Estado al 2026-11-11:** registro y login usan MySQL desde `backend/database/db.py`, con validación del certificado y del host mediante el PEM del `.env`. La comprobación previa encontró 10 tablas. Los endpoints de equipos y tareas siguen pendientes. El script SQL se conserva en `database/` en la raíz y no se ejecuta automáticamente.

La configuración de autenticación comparte el mismo `.env`:

```dotenv
SECRET_KEY=UN_SECRETO_ALEATORIO_DE_AL_MENOS_32_CARACTERES
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=120
```

`SECRET_KEY` firma el JWT y es independiente de `AVATAR_SERVICE_TOKEN`. En la consolidación se añadió un secreto aleatorio al `.env` local si no existía; no se sobrescribieron las credenciales de Aiven ni OpenAI. Las rutas y sus cuerpos JSON están en [docs/usuarios.md](docs/usuarios.md).

Para comprobar la conexión con el mismo conector Python de la API, sin modificar datos:

```powershell
.\.venv\Scripts\python.exe -m backend.utils.prueba_conexion
```

Para repetir la prueba de solo lectura desde la raíz:

```powershell
.\.venv\Scripts\python.exe -m backend.utils.check_database
```

La utilidad usa el cliente `mysql` del PATH o la instalación local de MySQL Server 8.0 en Windows. Ejecuta `SELECT 1`, consulta el cifrado TLS y cuenta las tablas. Usa exclusivamente las credenciales de `backend/.env`, sin imprimirlas, y siempre exige `VERIFY_IDENTITY`, aunque `DB_SSL_VERIFY_CERT` se cambie. El cliente MySQL requiere un archivo de CA: la utilidad crea una copia temporal del certificado y la elimina al terminar; no requiere mantener una ruta ni otro archivo de configuración. El timeout de conexión se toma de `DB_CONNECT_TIMEOUT` (1–120 segundos).

## 2. Iniciar el backend — terminal 1

Desde la raíz:

```powershell
.\.venv\Scripts\python.exe -m uvicorn backend.app:app --host 127.0.0.1 --port 8000
```

Espera el mensaje `Application startup complete` y deja esta terminal abierta. Para detener el servidor, pulsa `Ctrl+C`.

La documentación interactiva está en `http://127.0.0.1:8000/docs`. Este mismo proceso sirve los tres endpoints; no se necesita un segundo servidor en el puerto 8001. El registro/login SQL está disponible en la API; esta consolidación no cambia el flujo de autenticación de Flutter.

## 3. Iniciar la app en el emulador Android — terminal 2

**Desde VS Code:** detén la sesión actual (Shift+F5) y pulsa **Debug/Depurar** sobre `main()` en `lib/main.dart`, o usa F5 con el perfil **My Daily Rutine - Avatar con fotos**. Los ajustes del workspace añaden automáticamente el archivo de configuración a `flutter run`, también para el inicio directo desde `main.dart`. Funciona al abrir la raíz del repositorio o solo `my_daily_routine`. Mantén el backend ejecutándose en su terminal. Si VS Code estaba abierto al cambiar estos ajustes, ejecuta **Developer: Reload Window** y vuelve a iniciar la depuración. No basta con hot reload. El botón de extensiones genéricas como Code Runner no equivale al depurador Dart/Flutter.

**Desde terminal:**

Enciende tu emulador desde Android Studio (Device Manager). Abre otra terminal desde la raíz y ejecuta:

```powershell
cd my_daily_routine
flutter pub get
flutter devices
flutter run --dart-define-from-file=../.tools/avatar-flutter.json
```

Si aparecen varios dispositivos, selecciona el emulador Android o añade `-d ID_DEL_EMULADOR` al comando `flutter run`, usando el ID de `flutter devices`.

En este equipo ya está preparado `.tools/avatar-flutter.json`. Para reproducir la configuración en otro equipo, crea ese archivo en la raíz del repositorio con esta estructura y reemplaza el token por el mismo `AVATAR_SERVICE_TOKEN` de `backend/.env`:

```json
{
  "API_URL": "http://10.0.2.2:8000",
  "AVATAR_API_URL": "http://10.0.2.2:8000",
  "AVATAR_API_TOKEN": "EL_MISMO_TOKEN_LOCAL_DEL_BACKEND"
}
```

`10.0.2.2` es la dirección del equipo anfitrión desde el emulador Android. `API_URL` configura registro y login; `AVATAR_API_URL` configura las fotos. Ambas apuntan al mismo backend. Este JSON está ignorado por Git y contiene solo URL y token local: **nunca agregues la clave de OpenAI ni pases `backend/.env` a Flutter**. Si cambias URL o token, detén la app y vuelve a ejecutar `flutter run`; hot reload no actualiza estos valores.

El flujo actual de registro es `CrearUsuario → UsuariosStore.registrar → AuthApiService → POST /usuarios → INSERT Usuario + commit en Aiven`. El ingreso de práctica `admin / 12345678` en modo debug sigue siendo local y no crea un usuario en MySQL. La configuración del emulador no actualiza los APK ya construidos.

## 4. Probar la personalización

1. Inicia sesión con `admin` / `12345678`.
2. Abre **Tu avatar → Crear desde una foto**.
3. Toma una foto o elige una imagen de la galería del emulador. Puedes arrastrar una imagen al emulador para copiarla y seleccionarla.
4. Pulsa **Analizar foto** para autorizar el envío.
5. Revisa la propuesta, pulsa **Usar propuesta** y después **Guardar cambios**.

Usa una foto con una sola persona, de frente y bien iluminada. Si el emulador no tiene cámara configurada, usa la galería. El parecido depende de las opciones disponibles en el catálogo.

## Pruebas adicionales

Desde la raíz, pruebas automáticas sin llamadas reales a OpenAI:

```powershell
.\.venv\Scripts\python.exe -m pytest backend/test -q
```

Prueba real opcional de la clave y del endpoint (consume una petición de API):

```powershell
.\.venv\Scripts\python.exe -m backend.utils.check_connection
```

La prueba real envía la ilustración del avatar incluida en el proyecto y muestra el código HTTP y los atributos recibidos. Usa FastAPI en proceso: no requiere tener uvicorn abierto y no verifica la conexión desde el emulador ni la cámara. Una respuesta correcta muestra `Backend HTTP: 200` y una propuesta validada.

## Problemas habituales

- **La función de fotos no está configurada:** inicia Flutter con el JSON indicado y comprueba que el token tenga al menos 24 caracteres.
- **Acceso no autorizado:** el token de Flutter debe coincidir con `AVATAR_SERVICE_TOKEN`; no es la clave de OpenAI.
- **Error de conexión:** comprueba que uvicorn siga abierto en el puerto 8000 y que la app use `10.0.2.2`, no `localhost`.
- **Puerto ocupado:** detén la instancia anterior o cambia el puerto tanto en uvicorn como en el JSON.
- **Servicio ocupado o sin cuota:** revisa la cuota de la cuenta de API y vuelve a intentar más tarde.
- **ModuleNotFoundError:** ejecuta desde la raíz e instala las dependencias en `.venv`.

Estos comandos son para el emulador Android y una compilación debug. Para un teléfono físico se necesita una dirección alcanzable desde el dispositivo; para distribución, HTTPS y autenticación real. Consulta [el alcance y tratamiento de fotos](../docs/avatar-foto.md).
