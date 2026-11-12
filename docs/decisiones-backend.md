# Decisiones del backend

## 2026-11-11 — Comprobación del registro desde Flutter

Al revisar la conexión solicitada por el usuario, Flutter ya contenía registro y login HTTP mediante `AuthApiService`, pero `.tools/avatar-flutter.json` no tenía `API_URL`: solo configuraba las fotos. Se añadió `API_URL=http://10.0.2.2:8000` conservando las demás variables. Es necesario detener y volver a iniciar Flutter para incorporar ese valor de compilación.

La consulta real de solo lectura encontró 0 filas en `Usuario` en ese momento. El código de registro ejecuta INSERT y commit en Aiven, pero esta comprobación no creó una cuenta ni demuestra un registro completo desde el emulador. El usuario de práctica debug permanece local. La configuración local corregida no actualiza APK existentes.

## 2026-11-11 — Acceso local sin contraseña

El usuario confirmó que el panel permanecerá local y pidió evitar introducir credenciales. Se elimina el formulario de usuario/contraseña y la cabecera Authorization del frontend. Live Server intenta conectar automáticamente al backend local del puerto 8000; solo muestra la configuración de dirección si falla. Aiven sigue usando el `.env` exclusivamente en el servidor.

La excepción de autenticación comprueba loopback en cliente y host, origen local permitido y ausencia de cabeceras de proxy. Las conexiones no locales conservan la autenticación alternativa previa. No se exponen secretos ni se eliminan sus valores del `.env`. Se verificaron 28 pruebas del backend y la navegación en Chrome, tanto directa como desde Live Server, sin proporcionar credenciales al navegador.

## 2026-11-11 — Consultas desde Live Server

El usuario reportó un 404 en `:5500/admin/api/schema`. La causa era que el frontend utilizaba una URL relativa al origen del HTML y enviaba las consultas a Live Server en lugar de FastAPI. Se añadió una conexión explícita al backend cuando el HTML se abre desde un servidor estático, con dirección editable y credenciales administrativas solo en memoria. El acceso servido directamente por FastAPI mantiene el comportamiento previo.

El backend admite orígenes exactos de Live Server mediante `ADMIN_ALLOWED_ORIGINS`, con GET y cabecera Authorization. Se conservan la autenticación y las consultas de solo lectura. Se añadieron mensajes específicos para 404, 401, respuestas que no sean JSON y fallos de red/CORS. Verificación: 27 pruebas del backend, navegación habitual en Chrome y conexión real entre Live Server en 5500 y una instancia local de FastAPI con datos SQL simulados, incluyendo rechazo de contraseña incorrecta y recuperación posterior.

## 2026-11-11 — Identidad visual del panel y carga de recursos

El usuario pidió alinear el panel con la app y reportó que lo veía sin estilos. Se adoptó la paleta y los degradados de `theme.dart`, los controles redondeados y el icono existente de la app. El HTML, CSS y JS siguen separados. Las referencias absolutas a `/admin/assets/` no resolvían al abrir directamente el archivo: ahora los recursos usan rutas relativas y `/admin` redirige a `/admin/`. El servidor entrega MIME explícito para CSS/JS/PNG. El archivo local permite revisar el diseño y muestra un aviso para consultar datos desde el servidor; no intenta conectar a MySQL directamente.

Verificación: 26 pruebas del backend y comprobación en Chrome de estilos calculados, imagen cargada, búsqueda, relaciones, paginación, vista móvil y apertura local. Se usaron datos sintéticos para la revisión visual.

## 2026-11-11 — Ubicación del panel y sus rutas

**Acuerdo del usuario:** mantener el HTML, JavaScript y CSS separados dentro de `backend/admin/` y trasladar toda la API administrativa a `backend/app.py`. Se movieron los tres recursos, la autenticación administrativa y los endpoints HTTP; se retiró el módulo de rutas `backend/admin.py`. Las consultas SQL auxiliares conservan su responsabilidad en `backend/database/admin.py`.

**Motivo y alcance:** centralizar la API principal y dejar explícito que la página recibe las tablas y datos por respuestas JSON del servidor. Las URLs existentes, la protección de acceso y las consultas de solo lectura se mantienen. Esta decisión sustituye la ubicación inicial descrita abajo.

## 2026-11-11 — Explorador HTML administrativo

**Solicitud:** consultar tablas, datos y relaciones desde un panel con búsqueda. Se implementa dentro del backend existente, con interfaz en `backend/static/admin/`, rutas en `backend/admin.py` y consultas en `backend/database/admin.py`.

**Elecciones de implementación:** primera versión de solo lectura, autenticación HTTP Basic con credenciales administrativas independientes en el `.env`, búsqueda por tabla, paginación y relaciones obtenidas de claves foráneas. Las credenciales se generan solo cuando faltan. Se excluyen del resultado SQL los hashes de contraseña y campos de secretos; tampoco participan en búsquedas ni ordenación. Los registros se muestran como texto, sin interpretar HTML almacenado. Las consultas utilizan parámetros, validación de identificadores y transacciones de lectura. No se agregan dependencias de producción.

**Alcance y pendientes:** el panel consulta el estado real de Aiven; no implementa escrituras, búsqueda global ni relaciones no declaradas. El acceso remoto exige HTTPS. La política de campos protegidos debe revisarse si se agregan nuevos campos sensibles al esquema.

**Verificación:** 26 pruebas del backend aprobadas; consultas reales de solo lectura a las 10 tablas de Aiven; pruebas en Chrome con registros sintéticos para búsqueda, paginación, relaciones en ambas direcciones, representación segura de texto y diseño móvil. Las herramientas de prueba del navegador se instalaron únicamente en `.tools/`, sin dependencias nuevas de producción.

## 2026-11-11 — Consolidación de API y backend

**Acuerdo del usuario:** integrar el servicio separado `api/` en `backend/`, con `backend/app.py` como API principal y una sola configuración de entorno. El motivo es evitar implementaciones paralelas y asegurar que futuras colaboraciones reutilicen la estructura existente.

**Alcance:** registro y login se incorporaron a `app.py` junto al avatar. Modelos Pydantic se ubican en `backend/models/`, seguridad en `backend/core/`, acceso MySQL en `backend/database/`, diagnósticos en `backend/utils/`, pruebas en `backend/test/` y contratos en `backend/docs/`. La plantilla y dependencias se fusionaron; las credenciales existentes se conservaron. La copia del SQL de `api/BD_script/` era equivalente salvo saltos de línea: se conserva una sola fuente en `database/` de la raíz. Se retiró la carpeta `api/`.

**Decisiones técnicas:** imports absolutos `backend.*`; MySQL utiliza el PEM multilínea directamente en un contexto TLS con verificación del host, sin archivo permanente. Se desactiva autocommit para que commit/rollback del registro sean efectivos. La firma JWT se valida al emitir el token para que una configuración incompleta de autenticación no impida arrancar el servicio del avatar. Un único `/docs` describe las rutas unificadas.

**Pendientes:** conectar Flutter a registro/login; validar JWT en futuras rutas protegidas; implementar equipos, tareas y recompensas. Se conserva el contrato existente de registro y su generador aleatorio de IDs; su consulta previa no elimina una posible colisión concurrente. El registro existente tampoco crea todavía la fila de estadísticas. No se ejecutó el SQL ni se migraron datos con esta consolidación.

## 2026-11-12 — Autenticación JWT en tareas

**Acuerdo del usuario:** proteger las rutas de datos con el JWT ya emitido en el login y obtener `idUsu` exclusivamente del token, para impedir que un usuario cree o consulte tareas a nombre de otro.

**Alcance:** se añadió `verificar_token` en `backend/core/seguridad.py`, la dependencia `usuario_actual_id` en `backend/app.py`, y se protegió `POST /tareas` y `GET /tareas`. `tareaCreate` dejó de recibir `idUsu`. En Flutter, `TareasApiService` envía `Authorization: Bearer <token>` usando `UsuariosStore.token`.

**Decisiones técnicas:** el token contiene `sub` (idUsu como texto) y `exp`; `verificar_token` valida firma, algoritmo, expiración y presencia de `sub`/`exp`. `usuario_actual_id` exige un entero positivo. `GET /tareas` dejó de aceptar `?idUsu=`. Login y registro siguen públicos; `/avatar/suggest` conserva su token estático independiente.

**Verificación:** sin token → `401` en POST y GET; con token → `201`/`200`; el `idUsu` creado coincide con el `sub` del JWT; un `idUsu` ajeno en la consulta se ignora. `flutter analyze` y `flutter test` (31 pruebas) en verde.

**Pendientes:** probar la creación desde la app Flutter; manejar la expiración de sesión (`401`) redirigiendo al login.

## 2026-11-12 — Sincronización del completado de tareas

**Acuerdo del usuario:** sincronizar el ciclo de vida de una tarea (crear, completar y consultar) entre Flutter, FastAPI y MySQL, con la base de datos como fuente de verdad para usuarios autenticados.

**Alcance:** se añadió `PATCH /tareas/{idTarea}/completar` (protegido por JWT, verifica pertenencia, idempotente). En Flutter, `alternarCompletada` sincroniza el completado con el backend de forma pesimista, y `HistorialScreen` consulta `GET /tareas` con estado local de la pantalla.

**Decisiones técnicas:** el `UPDATE` incluye `idTarea` e `idUsu` en el `WHERE`. Para usuario real, una tarea completada no se puede desmarcar (no hay endpoint de "desmarcar"); la cuenta de práctica conserva el comportamiento local. Las estadísticas solo se procesan en la transición `false→true`, tras confirmar el servidor.

**Verificación:** 33 pruebas del backend (incluidas 5 del PATCH con mocks) y `flutter analyze`/`flutter test` en verde.

**Pendientes:** probar el flujo completo desde la app Flutter; decidir si se añade un endpoint para desmarcar tareas.

## 2026-11-12 — Nickname y email únicos en registro

**Acuerdo del usuario:** impedir que dos usuarios compartan `nickName` o `email`.

**Alcance:** el registro de `backend/app.py` captura `IntegrityError` de MySQL y responde `409`, identificando la restricción `UNIQUE` que falló por su nombre exacto (`Usuario_Nick_Uk` / `Usuario_Email_Uk`). En Flutter, `AuthApiService` mapea el `409` a «Este nombre de usuario ya está en uso. Intenta con otro.».

**Decisiones técnicas:** se identifica la restricción por su nombre en el mensaje del error (`nick_uk` / `email_uk`), sin coincidencias ambiguas. La base de datos sigue siendo la fuente de verdad mediante las restricciones `UNIQUE` del esquema.

**Verificación:** 33 pruebas del backend en verde; verificación manual con `IntegrityError` simulado → `409` para nickname y email. `flutter analyze` y `flutter test` en verde.

**Pendientes:** probar el registro duplicado desde la app Flutter con el backend en ejecución.
