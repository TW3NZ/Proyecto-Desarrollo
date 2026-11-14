
## 2026-11-14 — Equipos persistentes y aportes por persona

**Acuerdo confirmado:** el líder asigna una tarea a uno o varios miembros del mismo equipo. Cada uno marca su parte; solo cuando todos terminan se completa la tarea. Cada asignado recibe los puntos completos. No se reparten entre personas ni se entregan al resto del proyecto. La finalización requiere confirmación y no se puede deshacer.

**Implementación:** API única en `backend/app.py`, consultas en `backend/database/equipos.py`, frontend real en `screens/equipos_remotos.dart` y servicio HTTP separado. La cuenta de práctica conserva su flujo local. Equipos nuevos incluyen un proyecto General como elección de usabilidad; el líder puede crear otros. La pertenencia a un proyecto se incorpora al asignar su primera tarea, y sus tareas son visibles para sus miembros y el líder del equipo.

Invitaciones: ocho caracteres aleatorios en mayúsculas, sin caracteres visualmente ambiguos. El código identifica el equipo, no sustituye el JWT. Solo el líder lo consulta para compartirlo. Reingresar no duplica la membresía. No hay todavía rotación del código, expulsión, transferencia de liderazgo, edición de asignados ni reapertura de tareas.

Persistencia: migración 003 crea `EquipoInvitacion`, `ParticipanteTarea` (parte completada y fecha UTC) y claves compuestas que impiden relaciones entre equipos/proyectos incorrectos. `EventoPuntuacion` es único por tarea, tipo y usuario. Todas las confirmaciones del equipo se serializan; los usuarios se bloquean en orden de ID, y la última parte, los eventos y todos los saldos se confirman en una sola transacción. Se usa READ COMMITTED para leer el saldo vigente después de obtener los bloqueos, incluso si otro equipo acaba de entregar puntos.

**Elección provisional de puntuación:** se reutiliza `30 × factorPrioridad / N`, repartido entre las categorías de la tarea, y se aplica íntegro a cada asignado. Para tareas colaborativas N es el número de tareas pendientes del mismo proyecto justo antes de completarla. Así todos reciben la misma recompensa nominal aunque tengan distintas tareas personales. El saldo individual se limita a 100. No se recalculan eventos anteriores.

Las fechas límite se interpretan en Colombia como en tareas personales. Como elección de implementación, la penalización única de 8/10/12 según prioridad corresponde solo a asignados cuya parte siga pendiente al vencer; quien terminó su parte no es penalizado por esperar a otros. Se sincroniza al consultar estadísticas o marcar aportes, antes de marcar una contribución tardía. Sin fecha no hay penalización. No hay un proceso automático en segundo plano.

**Alcance de entrega:** creación, unión por código, proyectos, asignación múltiple, avance individual, consulta y recompensa persistentes. Actualización manual al entrar o deslizar hacia abajo; no hay notificaciones ni actualización en tiempo real. Migración aplicada en Aiven y pruebas con datos revertidos. Despliegue de este código en Render y APK actualizado son pasos posteriores; el APK anterior no contiene esta función.

Contrato y prueba manual: [backend/docs/equipos.md](../backend/docs/equipos.md). Esta entrega sustituye los pendientes históricos de participantes y persistencia indicados debajo.

## 2026-11-12 — La tarjeta «Mi ID de usuario» muestra el idUsu real

Con la integración de autenticación, la tarjeta «Mi ID de usuario» de la pantalla Teams dejó de estar vacía: ahora muestra el `idUsu` del usuario que inició sesión (`UsuariosStore.usuarioActual.id`; `-1` para la cuenta de práctica) e incluye un botón para copiarlo al portapapeles. Esto reemplaza la nota del 2026-11-05 en la que el campo se dejaba vacío.

## 2026-11-10 — Recompensa por tarea y pertenencia al equipo confirmadas

El usuario confirmó que los puntos se entregan al completar cada tarea y que cada participante recibe la recompensa completa, sin dividirla entre personas. Por ejemplo, una tarea con 5 puntos de finanzas concede 5 a cada beneficiario. El motivo es reconocer el trabajo conjunto con la misma recompensa individual.

También confirmó que todo participante del proyecto debe ser miembro del equipo propietario. Una pertenencia a otro equipo no habilita el acceso: la relación usada debe corresponder al equipo del proyecto. Esta regla deberá garantizarse en el backend y el esquema, además de los filtros de Flutter.

Alcance de esta entrega: actualizar las reglas y el análisis; no se modificó ni ejecutó SQL ni se implementaron recompensas. Pendientes: precisar si se seleccionan participantes por tarea o se recompensa a todos los del proyecto; definir reapertura y cambios de miembros. Las propuestas de registro transaccional e idempotencia siguen siendo decisiones técnicas por implementar.

## 2026-11-10 — Análisis previo de la base de datos y recompensas compartidas

El usuario aportó `database/BD_My_Daily_Routine.sql` y pidió analizarlo antes de continuar con equipos. Confirmó la selección de usuarios para equipos, participantes por proyecto y puntos por trabajo conjunto. Se revisaron las diez tablas y su correspondencia con Flutter: la estructura principal ya existe, pero faltan garantías de pertenencia coherente, contrato del responsable y un registro transaccional de recompensas sin duplicados. La política exacta de beneficiarios y reparto queda pendiente. El detalle está en [analisis-base-datos-equipos.md](analisis-base-datos-equipos.md). No se modificó ni ejecutó el SQL y no se implementaron nuevas funciones.

## 2026-11-05 — Espacio para el ID personal

A petición del usuario, la pantalla Teams incorpora una tarjeta «Mi ID de usuario» con el campo de valor vacío. La tarjeta queda preparada para recibir un ID, pero no se genera, carga ni vincula uno hasta definir esa lógica.

## 2026-11-09 — Equipo y proyecto como entidades separadas

A petición del usuario, `Equipo` representa el espacio de trabajo y conserva sus datos de identidad, creador y miembros. `Proyecto` es un modelo separado, pertenece a un solo equipo mediante `equipoId` y puede haber varios proyectos por equipo. Sus tareas `NuevaTarea` se relacionan mediante `proyectoId` y mantienen `usuarioId` como propietario; las tareas personales conservan `proyectoId` nulo.

El flujo crea primero el equipo y permite crear proyectos desde su página. Las tareas, el progreso y las actividades se consultan por proyecto. `TareaTeam` conserva el estado colaborativo independiente de `NuevaTarea.completada`. Los IDs siguen siendo enteros temporales negativos hasta la futura integración con FastAPI.

Alcance actual: persistencia en memoria; sin SQL ni API. Pendiente para backend: definir almacenamiento y migración de relaciones con la base de datos.

## 2026-11-09 — Pertenencia y permisos por proyecto

Al contrastar el flujo con `modelo_logico_My_Daily_Routine-2.pdf`, se separa la pertenencia de equipo de la participación en un proyecto: `MiembroEquipo` enlaza un usuario con un equipo y `MiembroProyecto` enlaza esa pertenencia con un proyecto y su rol. Ningún rol de proyecto se interpreta como permiso global sobre los demás proyectos del equipo.

La aplicación muestra a cada usuario solo los equipos y proyectos a los que pertenece. El creador del equipo puede crear proyectos; dentro de cada proyecto, las tareas y actividades se filtran o habilitan según la relación y el rol de ese proyecto. Los IDs agregados como miembros deben corresponder a usuarios existentes en el almacén local.

Alcance actual: relaciones y permisos en memoria, sin persistencia ni API. Pendiente para backend: aplicar las mismas claves foráneas y restricciones de unicidad en FastAPI/MySQL.
