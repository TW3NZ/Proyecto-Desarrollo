# Integración de autenticación: Flutter · FastAPI · MySQL

**Fecha:** 2026-11-11 (actualizado 2026-11-12)
**Alcance:** documenta únicamente lo que está implementado en el código actual. No describe funcionalidades futuras.

Este documento explica cómo se conecta la aplicación Flutter (`my_daily_routine/`) con el backend FastAPI unificado (`backend/`) y la base de datos MySQL para el **registro de usuarios**, el **inicio de sesión** y el uso del **JWT** en las rutas protegidas de datos.

---

## A. Arquitectura general

| Componente | Responsabilidad |
| --- | --- |
| **Flutter** | Recoge las credenciales, valida los formularios, llama a la API por HTTP/JSON, guarda el JWT en almacenamiento seguro, persiste el perfil público y restaura la sesión al arrancar. |
| **FastAPI (`backend/`)** | Servidor unificado: expone registro, login y `/avatar/suggest`; valida con Pydantic, hashea y verifica contraseñas (Argon2), emite el JWT, protege las rutas de datos y consulta MySQL. |
| **MySQL (Aiven)** | Base de datos alojada en la nube (Aiven); persistencia de usuarios, tareas y demás entidades. |

Cómo se comunican:

```text
Flutter  ──(HTTP JSON + Authorization: Bearer)──▶  FastAPI (backend/)  ──(PyMySQL/TLS)──▶  MySQL (Aiven)
   ▲                                                    │
   └────────────  JWT + datos públicos  ────────────────┘
```

- Flutter **nunca** habla directamente con MySQL; solo con FastAPI.
- El JWT se obtiene en el login y se guarda en almacenamiento seguro. Se envía como `Authorization: Bearer <token>` en todas las rutas protegidas (tareas, estadísticas, avatar y equipos; ver [`backend/docs/`](../../backend/docs/)).

---

## B. Estructura de archivos

### Nuevos o modificados en Flutter

| Archivo | Responsabilidad |
| --- | --- |
| `lib/services/auth_api_service.dart` | Cliente HTTP de login (`POST /auth/login/user`) y registro (`POST /usuarios`). |
| `lib/services/tareas_api_service.dart` | Cliente HTTP de `POST /tareas`; envía `Authorization: Bearer <token>`. |
| `lib/data/token_storage.dart` | Guarda el JWT con `flutter_secure_storage` (Keychain/Keystore) bajo la clave `auth.jwt`. |
| `lib/utils/jwt.dart` | Decodifica el payload del JWT **sin verificar firma** para leer `sub` y `exp` y decidir la sesión local. |
| `lib/models/usuario.dart` | Modelo `Usuario` + `Genero`, con serialización hacia/desde la API y el perfil local. |
| `lib/data/usuarios_store.dart` | Fachada de autenticación y sesión: `load`, `iniciarSesion`, `registrar`, `cerrarSesion`, `usuarioActual` y `token`. |
| `lib/screens/login.dart` | Pantalla de login (async, estado de carga, errores). |
| `lib/screens/crear_usuario.dart` | Pantalla de registro (async, estado de carga, errores). |
| `lib/main.dart` | Carga la sesión antes de `runApp` y decide la ruta inicial. |
| `test/login_navigation_test.dart` | Pruebas de widget del login con servicios y almacenamiento falsos. |
| `pubspec.yaml` | Añade `flutter_secure_storage`. |

### Referencia en `backend/`

| Archivo | Responsabilidad |
| --- | --- |
| `backend/app.py` | Punto de entrada único: registro, login, tareas, estadísticas, avatar, equipos y panel administrativo; dependencia de autenticación `usuario_actual_id`. |
| `backend/models/usuario.py` | Modelos `User`, `createUser` y `LoginUser`. |
| `backend/models/Tarea.py` | Modelos de tareas y categorías. |
| `backend/core/seguridad.py` | Emite el JWT (`crear_token`) y lo verifica (`verificar_token`); hasher Argon2. |
| `backend/database/db.py` | Conexión a MySQL con TLS (Aiven), leyendo `backend/.env`. |
| `backend/utils/generadores.py` | Genera ids numéricos únicos. |

---

## C. Configuración del entorno local

La aplicación en uso se conecta al backend desplegado en Render (`https://my-daily-rutine.onrender.com`). Esta sección describe cómo reproducir el backend y la base de datos en un equipo para desarrollar; es una alternativa, no el camino principal.

### Requisitos

- **Flutter / Dart**: SDK compatible con `pubspec.yaml` (`sdk: ^3.13.1`).
- **Python**: 3.13 (entorno virtual en la raíz del repositorio, `.venv`).
- **MySQL**: base de datos alojada en **Aiven** (no local). El esquema está en `database/BD_My_Daily_Routine.sql`.

### Dependencias

- **Flutter** (`pubspec.yaml`): `http`, `shared_preferences`, `flutter_secure_storage`.
- **Python** (`backend/requirements.txt`): FastAPI, uvicorn, openai, pillow, PyMySQL, PyJWT, `pwdlib[argon2]`, `python-dotenv`, `email-validator`, pytest, httpx.

### Entorno virtual de Python

Se usa un único `.venv` en la raíz del repositorio. Para crearlo e instalar:

```bash
python3 -m venv .venv
.venv/bin/python -m pip install -r backend/requirements.txt
```

### Variables de entorno (`backend/.env`)

El backend lee su configuración de `backend/.env` (ignorado por Git). **Cada integrante crea su propio `.env` copiando `backend/.env.example`.** Variables principales, **sin valores reales**:

```dotenv
OPENAI_API_KEY=
OPENAI_AVATAR_MODEL=gpt-4.1-mini
AVATAR_SERVICE_TOKEN=

DB_HOST=
DB_PORT=
DB_USER=
DB_PASSWORD=
DB_NAME=BD_my_daily_routine
DB_SSL_CA=
DB_SSL_VERIFY_CERT=true

SECRET_KEY=
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=120
```

> **Nunca** incluyas contraseñas, claves secretas ni credenciales reales en este documento, en el README ni en el control de versiones. `SECRET_KEY` debe ser un valor aleatorio de al menos 32 bytes.

### Base de datos (script SQL)

El esquema completo está en `database/BD_My_Daily_Routine.sql`. La base ya está inicializada en Aiven; el script solo se ejecuta para crear un servicio nuevo. Consulta [`database/README.md`](../../database/README.md).

---

## D. Configuración de la URL de la API

Flutter obtiene la URL mediante:

```dart
const String.fromEnvironment('API_URL')
```

Ese valor se inyecta con `--dart-define-from-file`, usando un archivo **local y excluido de Git** (`.tools/`), por ejemplo `.tools/avatar-flutter.json`.

Para el backend de Render:

```json
{
  "API_URL": "https://my-daily-rutine.onrender.com",
  "AVATAR_API_URL": "https://my-daily-rutine.onrender.com"
}
```

- `API_URL` configura registro, login, tareas, estadísticas y equipos; `AVATAR_API_URL` configura las fotos. Ambas apuntan al mismo backend unificado.
- No hace falta `AVATAR_API_TOKEN`: después del login, la app envía el JWT de la cuenta.
- Para un **backend local en el emulador Android** se usa `http://10.0.2.2:8000`, con el servidor ejecutándose en el equipo anfitrión.
- Para un **dispositivo físico** contra un backend local, el teléfono y el equipo deben estar en la **misma red Wi-Fi**, y FastAPI debe escuchar en `0.0.0.0`.
- El HTTP plano solo está habilitado en compilaciones **debug** de Android; para release se requiere HTTPS.

---

## E. Cómo ejecutar FastAPI (alternativa local)

El backend de producción ya está desplegado en Render y la app puede usarlo sin ejecutar nada en local. Esta sección describe cómo levantar una copia propia para desarrollar.

Desde la raíz del repositorio:

```bash
.venv/bin/python -m uvicorn backend.app:app --host 0.0.0.0 --port 8000 --reload
```

- `--host 0.0.0.0`: permite que el teléfono alcance la API por la red local.
- `--port 8000`: puerto del backend unificado.
- La terminal debe permanecer abierta mientras se prueba.
- Swagger: `http://IP_DEL_COMPUTADOR:8000/docs`.

---

## F. Cómo ejecutar Flutter

Desde `my_daily_routine/`:

```bash
flutter pub get
flutter run --dart-define-from-file=../.tools/avatar-flutter.json
```

Para generar un APK de **depuración**:

```bash
flutter build apk --debug --dart-define-from-file=../.tools/avatar-flutter.json
```

- El APK se genera en: `my_daily_routine/build/app/outputs/flutter-apk/app-debug.apk`.
- Para instalarlo: `adb install -r build/app/outputs/flutter-apk/app-debug.apk`.

---

## G. Endpoints implementados

Esta sección detalla el registro, el inicio de sesión y las tareas personales. Los contratos del resto de rutas actuales —estadísticas, avatar, equipos, proyectos y panel administrativo— están en [`backend/docs/`](../../backend/docs/).

### `POST /usuarios` — registro (público)

**Cuerpo (JSON):**

| Campo | Tipo | Obligatorio | Observaciones |
| --- | --- | --- | --- |
| `name` | string | sí | Nombre. |
| `lastName` | string | sí | Apellido. |
| `nickName` | string | sí | Nombre de usuario (único). |
| `email` | string | sí | Email válido (único). |
| `password` | string | sí | Se guarda con hash Argon2. |
| `createDate` | string | sí | `YYYY-MM-DD`. |
| `genero` | string | sí | `"Hombre"` o `"Mujer"`. |
| `foto` | string | no | Opcional. |

**Respuestas:** `201` → `{"mensaje": "Usuario registrado correctamente"}`; `422` → errores de validación. El `idUsu` lo genera el servidor y **no se devuelve**.

### `POST /auth/login/user` — inicio de sesión (público)

**Cuerpo (JSON):**

| Campo | Tipo | Obligatorio | Observaciones |
| --- | --- | --- | --- |
| `identificador` | string | sí | Email o `nickName`. |
| `password` | string | sí | Contraseña. |

**Respuesta `200`:**

```json
{
  "access_token": "<JWT>",
  "token_type": "bearer",
  "usuario": {
    "idUsu": 12345678,
    "nameUsu": "Nombre",
    "lastName": "Apellido",
    "nickName": "nick",
    "email": "correo@example.com",
    "createDate": "2026-11-11",
    "genero": "Hombre",
    "foto": null
  }
}
```

| Código | Significado |
| --- | --- |
| `200` | Credenciales correctas; devuelve el JWT y los datos públicos del usuario (incluido `idUsu`). |
| `401` | Usuario o contraseña incorrectos. |
| `422` | Validación fallida. |

> El JWT contiene `sub` (el `idUsu` como texto) y `exp`. La contraseña nunca se devuelve.

### `POST /tareas` y `GET /tareas` (protegidos)

Requieren `Authorization: Bearer <JWT>`; el `idUsu` se obtiene del token. Detalle completo en [`backend/docs/tareas.md`](../../backend/docs/tareas.md).

---

## H. Flujo de autenticación

### Inicio de sesión

1. El usuario escribe su identificador (email o `nickName`) y contraseña.
2. Flutter (`AuthApiService`) envía `POST /auth/login/user`.
3. FastAPI consulta MySQL: `SELECT ... FROM Usuario WHERE nickName = %s OR email = %s`.
4. FastAPI verifica la contraseña con el hash almacenado (Argon2).
5. Si es correcta, FastAPI genera el JWT (`sub` = `idUsu`, `exp` = ahora + minutos configurados).
6. Flutter guarda el JWT con `flutter_secure_storage` y el perfil público con `shared_preferences`.
7. Al abrir la app de nuevo, `UsuariosStore.load()` lee el token y el perfil y restaura `usuarioActual`.
8. `load()` valida la **expiración** del token y que el `sub` coincida con el `id` del perfil. Si algo no cuadra, limpia la sesión.

### Registro

1. El usuario rellena el formulario y Flutter valida localmente.
2. Flutter envía `POST /usuarios` (sin `idUsu`).
3. FastAPI valida con Pydantic, genera el `idUsu`, hashea la contraseña e inserta en MySQL.
4. Con `201`, Flutter vuelve al login para que el usuario inicie sesión.

### Validaciones locales vs. servidor

| Validación | Dónde |
| --- | --- |
| Campos obligatorios, formato de email, longitud de contraseña, confirmación | Flutter (formulario). |
| Expiración del JWT y coherencia token/perfil | Flutter (sin verificar firma). |
| Firma, algoritmo, expiración y `sub`/`exp` del JWT | FastAPI (`verificar_token`). |
| Tipos de datos, email válido, `genero`, formato de fecha | FastAPI (Pydantic). |
| Que el usuario exista y la contraseña sea correcta | FastAPI (MySQL + hash). |

---

## I. Pruebas

### Prueba manual

1. Levanta FastAPI (sección E) y la app (sección F).
2. **Registro:** crea un usuario y confirma que vuelve al login.
3. **Inicio de sesión:** entra con las credenciales recién creadas.
4. **Verificar en MySQL:** `SELECT idUsu, nickName, email FROM Usuario WHERE nickName = 'NICK_USADO';`
5. **Persistencia de sesión:** cierra y reabre la app; si el token no venció, entra directo a `home`.

### Pruebas automatizadas de Flutter

```bash
flutter analyze
flutter test
```

### Resultados verificados (2026-11-12)

- `flutter analyze`: **"No issues found!"**.
- `flutter test`: **"All tests passed!"** (31 pruebas).
- Autenticación JWT: `POST /tareas` y `GET /tareas` sin token → `401`; con token → `201`/`200`; el `idUsu` creado coincide con el `sub` del JWT.
