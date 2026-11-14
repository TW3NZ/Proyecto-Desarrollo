# Perfil y progreso por usuario

Decisión del usuario, 2026-11-13: guardar tareas, finalización, estadísticas y
personalización del avatar en la base de datos vinculadas a la cuenta. Las
expresiones se calculan a partir de estadísticas; no son una preferencia guardada.

## API

Todas estas rutas requieren `Authorization: Bearer <JWT>`. El propietario se
obtiene de `sub`; no se recibe un identificador de usuario en el cuerpo.

| Método y ruta | Resultado |
| --- | --- |
| `GET /usuarios/me/avatar` | Apariencia guardada, o catálogo predeterminado para una cuenta nueva |
| `PUT /usuarios/me/avatar` | Valida y guarda el objeto `AvatarConfig.toJson()` completo |
| `GET /usuarios/me/estadisticas` | Estadísticas persistidas, actualizadas desde el historial, y preferencias del aura |
| `PUT /usuarios/me/estadisticas/preferencias` | Guarda los cuatro booleanos `inteligenciaActiva`, `finanzasActiva`, `saludActiva`, `disciplinaActiva` |
| `GET /tareas` | Tareas propias pendientes y completadas |
| `POST /tareas` | Crea una tarea propia pendiente; no concede puntos |
| `PATCH /tareas/{id}/completar` | Confirma la tarea y devuelve también `estadisticas` en la misma transacción |

La apariencia incluye personaje, peinado, ojos, nariz, boca, piel, cabello,
camiseta, pantalón, color RGB de ojos y ropa, prenda, movimiento, altura y anchura.
No se almacenan fotos ni se crean texturas fuera del catálogo existente.
Los campos desconocidos y valores fuera del catálogo/rango se rechazan.

## Persistencia y cálculo

**Actualización 2026-11-14:** el cálculo vigente está documentado en
[decisiones de estadísticas](../../docs/decisiones-estadisticas.md). Las cuentas
nuevas empiezan en 100; los saldos se actualizan mediante eventos únicos de
vencimiento y finalización. La recuperación es `30 × W / (N × K)` y la penalización
única `10 × W / K`. Las reglas de recálculo histórico descritas debajo corresponden
a la versión inicial y ya no se ejecutan. Los saldos existentes se conservan.

- `Tarea` y `TareaCategoria` ya guardan propietario y finalización.
- `Estadistica` conserva una fila por `idUsu`, con valores `DECIMAL(8,4)`.
- `PerfilUsuario` tiene PK/FK `idUsu`, JSON `avatar` y JSON `preferencias`.
  Guardar apariencia no sobrescribe las preferencias del aura y viceversa.
- Se conserva la regla personal previa: 5/10/15 puntos según prioridad,
  divididos entre categorías, límite 100 por estadística. Educación corresponde
  a inteligencia. Aura es el promedio de las categorías activas.
- Elección de implementación: recalcular desde las tareas personales completadas
  y persistir el resultado, en vez de acumular puntos enviados por el teléfono.
  Recupera el progreso histórico y hace idempotentes los reintentos. El usuario
  se bloquea con `FOR UPDATE` antes de leer/mutar; completar y guardar puntos
  pertenecen a la misma transacción. Un fallo revierte ambas operaciones.
- Las recompensas colaborativas siguen pendientes de la decisión sobre sus
  beneficiarios. Las tareas de proyecto se conservan, pero se excluyen de este
  cálculo personal. No se implementó reparto a miembros de equipos.
- La regla actual trata el historial como fuente de verdad. Cambiar más adelante
  las recompensas o permitir borrar tareas requiere definir una migración de
  puntos o un registro de recompensas; no modificar esta fórmula silenciosamente.

## Migración y despliegue

Después de la migración 001, aplicar la 002 para esta versión:

```powershell
.\.venv\Scripts\python.exe -m backend.utils.migrate_profile --migration 002 --apply
```

La 002 configura el valor predeterminado 100 y crea `EventoPuntuacion`. Ya aplicada
en Aiven; no elimina tareas ni reinicia saldos. Desplegar el nuevo backend después
de migrar, sin mantener instancias antiguas que recalculen los saldos.

La migración `database/migrations/001_perfil_usuario.sql` amplía las cuatro
columnas de estadísticas y crea `PerfilUsuario`. No borra usuarios ni tareas.
MySQL hace commit implícito del DDL; no ejecutar el esquema completo sobre Aiven.

Desde la raíz:

```powershell
# Revisar el SQL sin ejecutar:
.\.venv\Scripts\python.exe -m backend.utils.migrate_profile
# Aplicar en la base configurada en backend/.env:
.\.venv\Scripts\python.exe -m backend.utils.migrate_profile --apply
```

Aplicada a Aiven el 2026-11-13 y verificada con una transacción de prueba revertida.
Después, subir/desplegar la versión nueva de `backend/` en Render y reconstruir
Flutter. El cambio del esquema no publica automáticamente las nuevas rutas.

## Flutter y datos anteriores

Inicio recupera tareas, estadísticas y avatar, muestra fallos de carga y permite
reintentar. Guardar avatar/preferencias espera confirmación del servidor.
Al cambiar de cuenta se vacía el estado anterior y se descartan respuestas tardías.
Las tareas reales ya no se leen/escriben desde `tareas.v1`; se conserva una
instantánea local para mostrar el widget, que no es la fuente de verdad.
La confirmación de finalización sigue en la app; el enlace del widget no completa
tareas reales automáticamente. No hay edición/borrado ni desmarcado remoto nuevos.

La cuenta de práctica sigue siendo local. El token de sesión permanece en el
almacenamiento seguro; el perfil básico de sesión mantiene su caché existente.
El avatar antiguo era una preferencia global sin propietario: se conserva su
archivo local para práctica, pero no se copia automáticamente a usuarios reales.
Cada usuario real debe guardar su selección una vez para tenerla en su cuenta.
Los puntos antiguos que solo existían en memoria se reconstruyen a partir de
las tareas personales que sí constan completadas en MySQL.

## Verificación

```powershell
.\.venv\Scripts\python.exe -m pytest backend/test -q
# Integración opcional; usa datos temporales y rollback en Aiven:
$env:RUN_MYSQL_TESTS='1'
.\.venv\Scripts\python.exe -m pytest backend/test/test_perfil_mysql.py -q
Remove-Item Env:RUN_MYSQL_TESTS
cd my_daily_routine
flutter test --no-pub test/perfil_remoto_test.dart test/tareas_store_test.dart
```

Prueba manual después del despliegue: entrar con A, crear/completar una tarea,
guardar rasgos y preferencias, cerrar sesión, entrar con B y verificar que no
hereda datos. Volver a A desde otra instalación y comprobar recuperación.
