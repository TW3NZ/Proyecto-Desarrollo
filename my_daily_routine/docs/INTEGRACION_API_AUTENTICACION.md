# Integración de autenticación: Flutter · FastAPI · MySQL

**Fecha:** 2026-11-11
**Alcance:** documenta únicamente lo que está implementado en el código actual. No describe funcionalidades futuras.

Este documento explica cómo se conecta la aplicación Flutter (`my_daily_routine/`) con el servicio FastAPI (`api/`) y la base de datos MySQL para el **registro de usuarios** y el **inicio de sesión**.

---

## A. Arquitectura general

| Componente | Responsabilidad |
| --- | --- |
| **Flutter** | Recoge las credenciales, valida los formularios, llama a la API por HTTP/JSON, guarda el JWT en almacenamiento seguro, persiste el perfil público y restaura la sesión al arrancar. |
| **FastAPI (`api/`)** | Expone los endpoints de registro y login, valida las peticiones con Pydantic, hashea y verifica contraseñas (Argon2), genera el JWT y consulta MySQL. |
| **MySQL** | Persistencia de los usuarios (tabla `Usuario`) y, en el futuro, de las demás entidades. |

Cómo se comunican:

```text
Flutter  ──(HTTP JSON)──▶  FastAPI (api/)  ──(PyMySQL)──▶  MySQL
   ▲                            │
   └────  JWT + datos públicos ─┘
```

- Flutter **nunca** habla directamente con MySQL; solo con FastAPI.
- El JWT viaja en el cuerpo de la respuesta de login (no se usa todavía para autorizar otros endpoints, porque hoy no hay endpoints protegidos). Flutter lo guarda listo para adjuntarlo como `Authorization: Bearer <token>` cuando existan.

---

## B. Estructura de archivos

### Nuevos o modificados en Flutter

| Archivo | Responsabilidad |
| --- | --- |
| `lib/services/auth_api_service.dart` | Cliente HTTP de login (`POST /auth/login/user`) y registro (`POST /usuarios`). Usa `http.Client` inyectable, timeout de 15 s y mapea códigos HTTP a mensajes (`AuthApiException`). |
| `lib/data/token_storage.dart` | Abstracción `TokenStorage` y su implementación `SecureTokenStorage`, que guarda el JWT con `flutter_secure_storage` (Keychain en iOS, Keystore en Android) bajo la clave `auth.jwt`. |
| `lib/utils/jwt.dart` | Decodifica el payload del JWT **sin verificar la firma** (la app no conoce el secreto) para leer `sub` y `exp` y decidir si la sesión local es válida. |
| `lib/models/usuario.dart` | Modelo `Usuario` + enum `Genero`, con serialización hacia/desde la API (`fromApiJson`, `toCreateUserJson`) y hacia/desde el perfil local (`toProfileJson`, `fromProfileJson`). |
| `lib/data/usuarios_store.dart` | Fachada de autenticación y sesión. Conserva la API pública que usan el resto de módulos (`usuarioActual`, `buscarPorId`, `idUsuarioPractica`, `cerrarSesion`). Gestiona `load`, `iniciarSesion`, `registrar` y `cerrarSesion`. |
| `lib/screens/login.dart` | Pantalla de login. Llama a `UsuariosStore.iniciarSesion` de forma asíncrona, muestra estado de carga y errores, y navega a `home` o `welcome`. |
| `lib/screens/crear_usuario.dart` | Pantalla de registro. Valida el formulario y llama a `UsuariosStore.registrar`; vuelve al login solo si la API responde `201`. |
| `lib/main.dart` | Carga la sesión (`UsuariosStore.load()`) antes de `runApp` y decide la ruta inicial (`home` si hay sesión, `login` si no). |
| `test/login_navigation_test.dart` | Pruebas de widget del login usando un `AuthApiService` y un `TokenStorage` falsos. |
| `pubspec.yaml` | Añade la dependencia `flutter_secure_storage`. |

### Referencia en `api/` (no se modifica en esta integración)

| Archivo | Responsabilidad |
| --- | --- |
| `api/main.py` | Define los endpoints `POST /usuarios` y `POST /auth/login/user`. |
| `api/models/usuario.py` | Modelos Pydantic `User`, `createUser` y `LoginUser`. |
| `api/core/seguridad.py` | Genera el JWT (`sub`, `exp`) y expone el hasher de contraseñas (Argon2). |
| `api/dataBase/db.py` | Conexión a MySQL con PyMySQL, leyendo `api/.env`. |
| `api/utils/generadores.py` | Genera el `idUsu` numérico único. |

---

## C. Configuración del entorno local

### Requisitos

- **Flutter / Dart**: SDK compatible con `pubspec.yaml` (`sdk: ^3.13.1`).
- **Python**: 3.13 (entorno virtual en `api/.venv`).
- **MySQL**: base de datos local. El esquema completo se crea con `api/BD_script/BD_My_Daily_Routine.sql`.

### Dependencias

- **Flutter** (`pubspec.yaml`): `http`, `shared_preferences`, `flutter_secure_storage`.
- **Python** (`api/requirements.txt`): FastAPI, Pydantic v2 (con `email-validator`), PyMySQL, PyJWT, `pwdlib[argon2]`, `python-dotenv`.

### Entorno virtual de Python

El servicio `api/` se ejecuta con su propio entorno virtual (`api/.venv`). No es necesario activarlo si se invoca su intérprete directamente (ver sección E).

### Variables de entorno (`api/.env`)

El servicio `api/` lee su configuración de `api/.env` (archivo ignorado por Git). **Cada integrante crea su propio `.env` copiando `api/.env.example` y rellenando los valores reales.** Variables esperadas, **sin valores reales**:

```dotenv
DB_HOST=
DB_PORT=3306
DB_USER=
DB_PASSWORD=
DB_NAME=
SECRET_KEY=
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=120
```

> **Nunca** incluyas contraseñas, claves secretas ni credenciales reales en este documento, en el README ni en el control de versiones. `SECRET_KEY` debe ser un valor aleatorio de al menos 32 bytes.

### Base de datos (script SQL)

El esquema completo está en `api/BD_script/BD_My_Daily_Routine.sql`. Para crear la base y las tablas:

```bash
mysql -u TU_USUARIO -p < api/BD_script/BD_My_Daily_Routine.sql
```

El script crea la base `BD_my_daily_routine` y las tablas (`Usuario`, `Estadistica`, `Equipo`, `MiembroEquipo`, `Categoria`, `Proyecto`, `MiembroProyecto`, `Tarea`, `Actividad_Tarea` y `TareaCategoria`). El valor de `DB_NAME` en tu `.env` debe coincidir con el nombre de la base creada.

---

## D. Configuración de la URL de la API

Flutter obtiene la URL de la API mediante:

```dart
const String.fromEnvironment('API_URL')
```

Ese valor se inyecta al compilar/ejecutar con `--dart-define-from-file`, usando un archivo **local y excluido de Git**:

`.tools/api-flutter.json`

```json
{
  "API_URL": "http://IP_DEL_COMPUTADOR:8001"
}
```

- `IP_DEL_COMPUTADOR` es la IP del equipo en la red local (por ejemplo `192.168.1.20`).
- El archivo `.tools/` está ignorado por Git, así que **no se sube al repositorio** y cada integrante crea el suyo con su propia IP.
- Para probar desde un **dispositivo físico**, el teléfono y el equipo deben estar en la **misma red Wi-Fi**, y FastAPI debe escuchar en `0.0.0.0` (no en `127.0.0.1`).
- El HTTP plano solo está habilitado en compilaciones **debug** de Android (`android/app/src/debug/AndroidManifest.xml` tiene `usesCleartextTraffic="true"`). Para release se requiere HTTPS.

---

## E. Cómo ejecutar FastAPI

Desde la carpeta `api/`:

```bash
.venv/bin/python -m uvicorn main:app --host 0.0.0.0 --port 8001 --reload
```

- `--host 0.0.0.0`: permite que el teléfono alcance la API por la red local.
- `--port 8001`: puerto distinto del que usa el servicio de avatar (`backend/`, puerto 8000).
- La terminal debe permanecer abierta mientras se prueba.
- Swagger está disponible en:

```
http://IP_DEL_COMPUTADOR:8001/docs
```

---

## F. Cómo ejecutar Flutter

Desde `my_daily_routine/`:

```bash
flutter pub get
flutter run --dart-define-from-file=../.tools/api-flutter.json
```

Para generar un APK de **depuración**:

```bash
flutter build apk --debug --dart-define-from-file=../.tools/api-flutter.json
```

- El APK se genera en: `my_daily_routine/build/app/outputs/flutter-apk/app-debug.apk`.
- Para instalarlo en un dispositivo con depuración USB habilitada:

```bash
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

---

## G. Endpoints implementados

### `POST /usuarios` — registro

**Cuerpo de la petición (JSON):**

| Campo | Tipo | Obligatorio | Observaciones |
| --- | --- | --- | --- |
| `name` | string | sí | Nombre. |
| `lastName` | string | sí | Apellido. |
| `nickName` | string | sí | Nombre de usuario. |
| `email` | string | sí | Email válido (`EmailStr`). |
| `password` | string | sí | Se guarda con hash Argon2. |
| `createDate` | string | sí | Fecha en formato `YYYY-MM-DD`. |
| `genero` | string | sí | Solo `"Hombre"` o `"Mujer"`. |
| `foto` | string | no | Opcional; Flutter lo envía como `null`. |

**Respuestas:**

| Código | Significado | Cuerpo |
| --- | --- | --- |
| `201` | Registro correcto | `{"mensaje": "Usuario registrado correctamente"}` |
| `422` | Validación fallida | Lista de errores de Pydantic |

- El **ID (`idUsu`) lo genera el servidor** y **no se devuelve** en la respuesta. Por eso, tras registrarse, la app vuelve al login y el usuario inicia sesión.

### `POST /auth/login/user` — inicio de sesión

**Cuerpo de la petición (JSON):**

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

> El JWT contiene solo `sub` (el `idUsu` como texto) y `exp` (marca de expiración). La contraseña nunca se devuelve.

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
8. `load()` valida la **expiración** del token y que el `sub` del JWT coincida con el `id` del perfil guardado. Si algo no cuadra, limpia la sesión por completo.

### Registro

1. El usuario rellena el formulario y Flutter valida localmente los campos.
2. Flutter envía `POST /usuarios` (sin `idUsu`).
3. FastAPI valida con Pydantic, genera el `idUsu` único, hashea la contraseña e inserta la fila en MySQL.
4. Si responde `201`, Flutter vuelve al login para que el usuario inicie sesión.

### Validaciones locales vs. servidor

| Validación | Dónde |
| --- | --- |
| Campos obligatorios, formato de email, longitud mínima de contraseña, confirmación de contraseña | Flutter (formulario). |
| Cuenta de práctica `admin` / `12345678` (solo `kDebugMode`) | Flutter (no llama a la API). |
| Expiración del JWT y coherencia token/perfil | Flutter (sin verificar firma). |
| Tipos de datos, email válido, `genero` permitido, formato de fecha | FastAPI (Pydantic). |
| Que el usuario exista y la contraseña sea correcta | FastAPI (consulta a MySQL + verificación de hash). |

---

## I. Pruebas

### Prueba manual

1. Levanta FastAPI (sección E) y la app (sección F).
2. **Registro:** pulsa "Crear usuario", completa el formulario y confirma que vuelve al login.
3. **Inicio de sesión:** entra con el `nickName`/email y contraseña recién creados.
4. **Verificar en MySQL:**

   ```sql
   SELECT idUsu, nameUsu, lastName, nickName, email, genero
   FROM Usuario
   WHERE nickName = 'NICK_USADO';
   ```

5. **Comprobar `idUsu`:** confirma que la fila tiene un `idUsu` numérico generado por el servidor.
6. **Persistencia de sesión:** cierra la app por completo y vuelve a abrirla; si el token no venció, debe entrar directo a `home` sin pedir credenciales.

### Pruebas automatizadas de Flutter

```bash
flutter analyze
flutter test
```

### Resultados verificados (2026-11-11)

- `flutter analyze`: **"No issues found!"** (sin errores ni advertencias).
- `flutter test`: **"All tests passed!"** (31 pruebas), incluidas las dos de `test/login_navigation_test.dart` (login directo y login con tutorial).
