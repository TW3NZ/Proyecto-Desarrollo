# Tareas en el backend unificado

`POST /tareas` y `GET /tareas` forman parte de `backend/app.py`, junto a registro, login y `/avatar/suggest`.
Configuración, dependencias y comandos: [README del backend](../README.md).
Todos usan el mismo proceso `backend.app:app` y el puerto 8000.

Desde la raíz del repositorio:

```powershell
.\.venv\Scripts\python.exe -m uvicorn backend.app:app --host 127.0.0.1 --port 8000
```

Swagger: `http://127.0.0.1:8000/docs`.

## Autenticación

Ambos endpoints exigen JWT. El token se obtiene en `POST /auth/login/user` y se envía como:

```
Authorization: Bearer <JWT>
```

El `idUsu` se obtiene **exclusivamente del token** (`sub`), nunca de un campo enviado por el cliente. Sin token (o con token inválido/expirado), la respuesta es `401`.

## Endpoints

### `POST /tareas` — crear tarea

Cuerpo (JSON):

| Campo | Tipo | Obligatorio | Observaciones |
|---|---|---|---|
| `Titulo` | string | sí | Título de la tarea. |
| `Prioridad` | string | sí | `"Baja"`, `"Media"` o `"Alta"`. |
| `categorias` | list[int] | sí | Al menos una; ids `1`–`4` (ver categorías). |
| `idProyecto` | int | no | Solo si es tarea de proyecto; `null` = tarea personal. |
| `idResponsable` | int | no | Responsable (`MiembroProyecto`); `null` si no aplica. |
| `Descripcion` | string | no | Opcional. |
| `Fecha` | string | no | `YYYY-MM-DD`; si se omite, se usa la fecha actual. |
| `Fecha_Fin` | string | no | `YYYY-MM-DD`; opcional. |
| `Completada` | bool | no | `false` por defecto. |

> `idUsu` **no** va en el cuerpo: se obtiene del JWT.

Respuestas:

| Código | Significado | Cuerpo |
|---|---|---|
| `201` | Tarea creada | `{"mensaje": "Tarea creada correctamente", "idTarea": 12345678}` |
| `401` | Sin token o token inválido/expirado | — |
| `422` | Validación fallida | Lista de errores de Pydantic |
| `500` | Error de base de datos (FK o clave duplicada) | — |

El **`idTarea` lo genera el servidor** (8 dígitos, único contra `Tarea`) y se devuelve en la respuesta.

### `GET /tareas` — historial de tareas

Devuelve las tareas del usuario autenticado (el `idUsu` sale del JWT; **no** se acepta `?idUsu=`).

Respuesta `200` (lista):

```json
[
  {
    "idTarea": 12345678,
    "idUsu": 34922209,
    "idResponsable": null,
    "idProyecto": null,
    "Titulo": "Estudiar Python",
    "Prioridad": "Alta",
    "Descripcion": "Repasar FastAPI",
    "Fecha": "2026-11-12",
    "Fecha_Fin": null,
    "Completada": false,
    "categorias": [1, 3]
  }
]
```

| Código | Significado |
|---|---|
| `200` | Lista de tareas (puede ser `[]`). |
| `401` | Sin token o token inválido/expirado. |

### `PATCH /tareas/{idTarea}/completar` — marcar como completada

Requiere JWT; el `idUsu` sale del token y la tarea debe pertenecer al usuario autenticado. No recibe cuerpo.

| Código | Significado | Cuerpo |
|---|---|---|
| `200` | Tarea completada | `{"mensaje": "Tarea completada correctamente"}` |
| `401` | Sin token o token inválido/expirado | — |
| `404` | La tarea no existe o no pertenece al usuario | — |

Es **idempotente**: completar una tarea ya completada no produce efectos secundarios.

## Categorías (fijas)

| id | nombre |
|---|---|
| 1 | Educación |
| 2 | Finanzas |
| 3 | Salud |
| 4 | Disciplina |

Son un conjunto fijo; **no existe endpoint para crearlas**. Están sembradas en la base.

## Tarea personal vs. de proyecto

- **Personal:** `idProyecto = null` e `idResponsable = null`. No exige equipo ni proyecto.
- **De proyecto:** `idProyecto` apunta a un `Proyecto` existente. Si se envía `idResponsable`, debe ser un `MiembroProyecto` existente (por clave foránea).

## Notas

- `idCategoria`, `idProyecto` e `idResponsable` se validan por claves foráneas; si no existen, la operación devuelve `500`.
- Toda tarea tiene al menos una categoría (el `INNER JOIN` del historial asume esta regla).
- Pendiente: validar que el responsable pertenezca al equipo del proyecto (regla de `AGENTS.md`) cuando `idProyecto` no es nulo.

## Módulos y alcance

- `backend/app.py`: rutas `POST /tareas` y `GET /tareas` + dependencia `usuario_actual_id`.
- `backend/core/seguridad.py`: `verificar_token` (valida firma, algoritmo, expiración y presencia de `sub`/`exp`).
- `backend/models/Tarea.py`: modelo `tareaCreate` (cuerpo de la petición, sin `idUsu`).
- `backend/utils/generadores.py`: `generar_id_unico_tarea()` (idTarea único).
- `backend/database/db.py`: conexión MySQL con TLS y transacciones.

No hay aún CRUD de equipos ni de proyectos.
