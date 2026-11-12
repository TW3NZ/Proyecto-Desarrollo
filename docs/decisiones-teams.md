
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
