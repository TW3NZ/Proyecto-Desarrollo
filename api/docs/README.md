# API My Daily Routine — FastAPI + MySQL

**Fecha:** 2026-11-11
**Alcance:** documenta el estado actual de `api/`. No presenta como implementado nada que no esté en el código.

## 1. Qué es y cómo se ubica

API REST de autenticación y datos del proyecto, construida con **FastAPI + MySQL**. Es un servicio **independiente** del backend de avatar (`backend/`):

| Servicio | Responsabilidad | Usa MySQL | Usa OpenAI |
|---|---|---|---|
| `api/` | Usuarios, autenticación y datos | Sí | No |
| `backend/` | Foto → propuesta de atributos del avatar | No | Sí |
| Flutter | Cliente de ambos; decide y guarda | — | — |

Los dos servicios **no se comunican entre sí**. Flutter es el único cliente de ambos.

## 2. Estructura actual

```text
api/
├── main.py                  # endpoints de registro y login
├── requirements.txt         # dependencias
├── .env                     # configuración local (ignorado por Git)
├── .env.example             # plantilla de configuración
├── __init__.py
├── BD_script/
│   └── BD_My_Daily_Routine.sql   # esquema SQL de la base
├── core/
│   ├── __init__.py
│   └── seguridad.py         # JWT y hasher de contraseñas (Argon2)
├── models/
│   ├── __init__.py
│   ├── usuario.py           # modelos de usuario y login
│   └── Tarea.py             # modelos de tareas y categorías
├── utils/
│   ├── __init__.py
│   └── generadores.py       # generación de idUsu único
├── dataBase/
│   ├── __init__.py
│   ├── db.py                # conexión a MySQL
│   ├── consultas.py         # consulta auxiliar (existe_id)
│   └── prueba_conexion.py   # script de diagnóstico
└── docs/
    └── README.md            # este documento
```

## 3. Requisitos

- **Python** 3.13.
- **MySQL** con acceso local.

## 4. Crear el entorno virtual e instalar dependencias

Desde la carpeta `api/`:

```bash
python -m venv .venv
.venv/bin/python -m pip install -r requirements.txt
```

En Windows, la ruta del intérprete es `.venv\Scripts\python.exe`.

## 5. Configurar `.env`

1. Crea tu archivo `.env` a partir de la plantilla:

   ```bash
   cp .env.example .env
   ```

2. Rellena los valores reales. Variables:

   | Variable | Uso |
   |---|---|
   | `DB_HOST` | Host de MySQL. |
   | `DB_PORT` | Puerto de MySQL (por defecto `3306`). |
   | `DB_USER` | Usuario de MySQL. |
   | `DB_PASSWORD` | Contraseña de MySQL. |
   | `DB_NAME` | Nombre de la base de datos. |
   | `SECRET_KEY` | Secreto para firmar el JWT (al menos 32 bytes). |
   | `ALGORITHM` | Algoritmo del JWT (`HS256` por defecto). |
   | `ACCESS_TOKEN_EXPIRE_MINUTES` | Expiración del token en minutos (`120` por defecto). |

> `.env` está ignorado por Git. Nunca lo subas al repositorio.

## 6. Importar el script SQL

El esquema completo está en `BD_script/BD_My_Daily_Routine.sql`. Ejecútalo para crear la base y las tablas:

```bash
mysql -u TU_USUARIO -p < BD_script/BD_My_Daily_Routine.sql
```

El script crea la base `BD_my_daily_routine` y las tablas `Usuario`, `Estadistica`, `Equipo`, `MiembroEquipo`, `Categoria`, `Proyecto`, `MiembroProyecto`, `Tarea`, `Actividad_Tarea` y `TareaCategoria`. El valor de `DB_NAME` en tu `.env` debe coincidir con el nombre de la base creada.

## 7. Ejecutar FastAPI

Desde la carpeta `api/`:

```bash
.venv/bin/python -m uvicorn main:app --host 0.0.0.0 --port 8001 --reload
```

- `--host 0.0.0.0`: permite acceder desde un teléfono en la misma red Wi-Fi.
- `--port 8001`: evita chocar con `backend/` (que usa el puerto 8000).
- Deja la terminal abierta mientras pruebas.
- Swagger está en `http://IP_DEL_COMPUTADOR:8001/docs` (o `http://127.0.0.1:8001/docs`).

> **Importante:** se ejecuta desde `api/` con `main:app`. Los módulos usan imports de nivel superior (`dataBase`, `models`, `core`, `utils`), por lo que la forma `api.main:app` desde la raíz del repositorio **no funciona**.

### Prueba de conexión (opcional)

```bash
.venv/bin/python -m dataBase.prueba_conexion
```

## 8. Endpoints

### `POST /usuarios` — registro

Cuerpo (JSON):

| Campo | Tipo | Obligatorio | Observaciones |
|---|---|---|---|
| `name` | string | sí | Nombre. |
| `lastName` | string | sí | Apellido. |
| `nickName` | string | sí | Nombre de usuario (único). |
| `email` | string | sí | Email válido (único). |
| `password` | string | sí | Se guarda con hash Argon2. |
| `createDate` | string | sí | Fecha `YYYY-MM-DD`. |
| `genero` | string | sí | `"Hombre"` o `"Mujer"`. |
| `foto` | string | no | Opcional. |

Respuestas:

| Código | Significado | Cuerpo |
|---|---|---|
| `201` | Registro correcto | `{"mensaje": "Usuario registrado correctamente"}` |
| `422` | Validación fallida | Lista de errores de Pydantic |

El **`idUsu` lo genera el servidor** y **no se devuelve** en la respuesta.

### `POST /auth/login/user` — inicio de sesión

Cuerpo (JSON):

| Campo | Tipo | Obligatorio | Observaciones |
|---|---|---|---|
| `identificador` | string | sí | Email o `nickName`. |
| `password` | string | sí | Contraseña. |

Respuesta `200`:

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
|---|---|
| `200` | Credenciales correctas; devuelve el JWT y los datos públicos del usuario. |
| `401` | Usuario o contraseña incorrectos. |
| `422` | Validación fallida. |

## 9. Módulos

- `dataBase/db.py`: conexión a MySQL con PyMySQL (`DictCursor`, `autocommit=True`), leyendo `api/.env`.
- `dataBase/consultas.py`: función auxiliar `existe_id`.
- `dataBase/prueba_conexion.py`: diagnóstico de conexión.
- `core/seguridad.py`: `crear_token` (JWT con `sub` y `exp`) y `password_hash` (Argon2).
- `models/usuario.py`: modelos `User`, `createUser` y `LoginUser`.
- `models/Tarea.py`: modelos de tareas y categorías.
- `utils/generadores.py`: `generar_id_unico()` (id numérico de 8 dígitos no repetido).
- `main.py`: endpoints de registro y login.

## 10. Estado por funcionalidad

| Funcionalidad | Estado |
|---|---|
| Conexión a MySQL | Implementada |
| Hash de contraseñas (Argon2) | Implementado |
| Creación de JWT | Implementada |
| Registro de usuario | Implementado |
| Inicio de sesión | Implementado |
| Validación / lectura de JWT en rutas protegidas | No implementada |
| CRUD de tareas | No implementado (solo modelos) |
| CORS | No configurado (solo se usa desde la app móvil) |

## 11. Deuda técnica

- `SECRET_KEY` debe ser un valor aleatorio de al menos 32 bytes.
- Nombres de archivo inconsistentes: `models/Tarea.py` (mayúscula) frente a `models/usuario.py` (minúscula).
- `dataBase/consultas.py` quedó sin uso tras quitar el import de `main.py`; se conserva por ahora.
- No hay pruebas automatizadas de los endpoints.
