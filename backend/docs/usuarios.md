# Usuarios y autenticacion en el backend unificado

Registro y login forman parte de `backend/app.py`, junto a `/avatar/suggest`.
Configuracion, dependencias y comandos: [README del backend](../README.md).
Todos usan el mismo proceso `backend.app:app` y el puerto 8000.

Desde la raiz del repositorio:

```powershell
.\.venv\Scripts\python.exe -m uvicorn backend.app:app --host 127.0.0.1 --port 8000
```

Swagger: `http://127.0.0.1:8000/docs`.

## Endpoints

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


## Modulos y alcance

- `backend/database/db.py`: conexiones PyMySQL con TLS verificado y transacciones.
- `backend/database/consultas.py`: consulta auxiliar de existencia de usuario.
- `backend/utils/prueba_conexion.py`: diagnostico del conector Python sin escrituras.
- `backend/core/seguridad.py`: hash Argon2 y JWT con `sub` y `exp`.
- `backend/models/usuario.py`: cuerpos de registro y login.
- `backend/models/Tarea.py`: modelos de tareas; no implica endpoints implementados.
- `backend/utils/generadores.py`: IDs enteros aleatorios de ocho digitos.

El JWT requiere `SECRET_KEY`, `ALGORITHM=HS256` y `ACCESS_TOKEN_EXPIRE_MINUTES`
en `backend/.env`. El token del avatar conserva su mecanismo independiente.
No hay aun validacion de JWT para rutas protegidas ni CRUD de equipos o tareas.
El registro no inicializa estadisticas; se conserva el contrato previo.
