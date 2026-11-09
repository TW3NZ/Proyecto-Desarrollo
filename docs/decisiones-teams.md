
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
