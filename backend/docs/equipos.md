# Equipos: API y prueba manual

Todas las rutas están en `backend/app.py` y requieren `Authorization: Bearer <JWT>` de un usuario real. La identidad del actor se obtiene del JWT. Las consultas viven en `backend/database/equipos.py`; no hay otro servidor.

| Método y ruta | Datos / resultado |
| --- | --- |
| GET `/equipos` | Equipos del usuario actual. |
| POST `/equipos` | `{"nombre":"Estudio"}` → `idEquipo`, `codigo`. El creador es líder y miembro; incluye proyecto General. |
| POST `/equipos/unirse` | `{"codigo":"ABCD2345"}` → `idEquipo`. Repetir no duplica la pertenencia. |
| GET `/equipos/{id}` | Miembros, proyectos y tareas visibles. Solo el líder obtiene el código. |
| POST `/equipos/{id}/proyectos` | `{"nombre":"Entrega"}`. Solo líder; admite `meta` y `categoria` opcionales. |
| POST `/equipos/{id}/proyectos/{proyecto}/tareas` | Solo líder; ejemplo abajo. |
| PATCH `/equipos/{id}/tareas/{tarea}/mi-parte` | Sin cuerpo. Solo un asignado puede marcar su propia parte. Devuelve `completada`, `miParteCompletada` y sus `estadisticas`. |

```json
{
  "titulo": "Preparar presentación",
  "descripcion": "Cada integrante prepara su sección",
  "prioridad": "Media",
  "fechaLimite": "2026-12-01",
  "categorias": [1, 4],
  "participantes": [12345678, 23456789]
}
```

Los participantes son IDs de usuarios del mismo equipo. La asignación crea su pertenencia al proyecto cuando falta. `fechaLimite` puede ser `null`; debe haber al menos una categoría y un participante. El líder ve todos sus proyectos; cada miembro ve los proyectos a los que fue asignado. No se devuelven emails, contraseñas ni hashes.

## Preparar el servicio

Para una base existente, aplicar 001 y 002 si aún faltan, y luego **una sola vez**:

```powershell
python -m backend.utils.migrate_profile --migration 003 --apply
python -m uvicorn backend.app:app --host 0.0.0.0 --port 8000
```

La migración 003 ya fue aplicada al Aiven configurado en este equipo el 2026-11-14. No repetirla. MySQL confirma DDL implícitamente; ante una ejecución interrumpida, revisar las tablas antes de continuar. Para una base nueva el esquema completo ya incluye estos cambios y no debe ejecutarse después 003.

En Render hay que desplegar el código actualizado del backend. Para probar Flutter contra Render, usar su configuración habitual `API_URL=https://my-daily-rutine.onrender.com`. Para un backend local y emulador Android:

```powershell
cd my_daily_routine
flutter run --dart-define=API_URL=http://10.0.2.2:8000
```

## Recorrido con dos cuentas reales

1. Entrar en Equipos y crear un equipo con la cuenta A; copiar su código.
2. Con la cuenta B, elegir Unirse y escribir el código.
3. Con A, actualizar la pantalla deslizando hacia abajo. En General, asignar una tarea a A y B y elegir categorías.
4. Con A, marcar su parte y confirmar: aparece 1 de 2, sin recompensa todavía.
5. Con B, actualizar y marcar su parte: la tarea queda completada para ambos. Actualizar A para consultar el nuevo saldo.
6. Repetir la petición o actualizar no suma de nuevo. Una cuenta no asignada no puede completar partes ajenas.

Las estadísticas tienen tope 100: si ya están en 100, el saldo no sube aunque la tarea genere un evento. La cuenta de práctica conserva el prototipo local y no sirve para probar colaboración remota.

## Verificación automatizada

```powershell
python -m pytest backend/test -q
$env:RUN_MYSQL_TESTS='1'
python -m pytest backend/test/test_equipos_mysql.py backend/test/test_perfil_mysql.py -q
Remove-Item Env:RUN_MYSQL_TESTS
cd my_daily_routine
flutter test --no-pub test/equipos_test.dart
```

Las pruebas MySQL insertan datos dentro de una transacción y los revierten incluso si fallan. No ejecutan DDL.
