# Reglas del proyecto My Daily Rutine

Estas instrucciones aplican a todo el repositorio. Leerlas antes de modificarlo.

## Protocolo de inicio de tarea (obligatorio)

Antes de realizar cualquier tarea, análisis, modificación, implementación, depuración o refactorización:

1. Localizar y leer todos los archivos `AGENTS.md` aplicables al proyecto.
2. Leer nuevamente sus instrucciones al comenzar cada nueva tarea.
3. Respetar estrictamente las reglas, restricciones, arquitectura y convenciones establecidas.
4. Si se trabaja dentro de un subdirectorio, comprobar si existen instrucciones `AGENTS.md` adicionales que apliquen a esa ubicación.
5. Si las instrucciones no están claras o existen contradicciones, detenerse y consultar al usuario antes de continuar.
6. No ignorar estas instrucciones por considerar que una tarea es sencilla o pequeña.

## Acuerdos de producto

- La aplicación Flutter relaciona el cumplimiento de tareas con estadísticas y la evolución de un avatar.
- Cada registro de estadísticas pertenece a un usuario mediante `usuarioId`; sus valores y preferencias son independientes por cuenta.
- Las cuentas nuevas comienzan con inteligencia, finanzas, salud y disciplina en 100. Solo las tareas pendientes con fecha límite vencida penalizan; las que no tienen fecha no penalizan. La recuperación al completar debe ser mayor con pocas tareas pendientes y menor con muchas. Los coeficientes iniciales y la penalización única por tarea son elecciones de implementación documentadas en `docs/decisiones-estadisticas.md`; no recalcular recompensas pasadas al cambiar la lista de tareas.
- Desde el 2026-11-13, las cuentas reales guardan tareas y su finalización, estadísticas y apariencia del avatar en MySQL mediante la API y el JWT. El teléfono conserva solo estado en memoria y una instantánea de lectura del widget; la cuenta de práctica conserva su comportamiento local. No asignar automáticamente la antigua apariencia global del dispositivo a una cuenta. Las expresiones se derivan de estadísticas y no se guardan como estado separado.
- Los IDs de entidades y sus referencias son enteros. Los IDs negativos son temporales de Flutter en memoria; los definitivos los entrega FastAPI.
- `Equipo` representa el espacio de trabajo y sus miembros; `Proyecto` es una entidad propia y cada proyecto pertenece a un equipo mediante `equipoId`. Las tareas de proyecto se relacionan con `proyectoId`.
- Los equipos deben poder formarse seleccionando usuarios, y cada proyecto puede incluir un subconjunto de sus miembros. Todo participante de un proyecto debe pertenecer al equipo de ese proyecto; pertenecer únicamente a otro equipo no permite asociarlo. Validar esta regla también en el backend y la base de datos.
- Las recompensas colaborativas se entregan al completar cada tarea. El usuario confirmó el 2026-11-14 que el líder selecciona los asignados por tarea, la tarea termina cuando todos marcan su parte y cada asignado recibe los puntos completos, sin dividirlos entre personas. Los miembros no asignados no reciben esa recompensa. Unirse a equipos usa un código alfanumérico en mayúsculas (8 caracteres en esta implementación). Consultar `docs/decisiones-teams.md` y `docs/analisis-base-datos-equipos.md`; no permitir que un usuario marque la parte de otro ni duplicar puntos al reintentar.
- El avatar principal debe ser humano, de cuerpo completo y protagonista en el centro de la pantalla de inicio, con espacio para los controles laterales.
- Usar como referencia visual principal la imagen compartida por el usuario: avatar humano juvenil, cabeza algo grande, cuerpo más alargado que el primer prototipo, formas suaves, silueta clara y sombras discretas. Esta referencia concreta refina la inspiración inicial en Duolingo; mantener identidad propia.
- Aplicar ese lenguaje visual a todos los avatares, sin fijar el cabello, tono de piel, ropa, gafas, audífonos, mochila, marcas ni pose del personaje de referencia. El usuario confirmó que solo se toma su estilo de dibujo.
- La dirección acordada es un avatar personalizable por piezas. La primera entrega es un concepto PNG para revisar el diseño; no confundirlo con un sistema de capas terminado.
- El usuario autorizó el 2026-11-09 la foto como entrada a OpenAI para elegir atributos del catálogo existente. Mantener la clave de OpenAI exclusivamente en el backend, solicitar el envío mediante una acción explícita y mostrar una propuesta editable antes de guardar. No generar nuevas ilustraciones ni inferir identidad o género; conservar el personaje elegido y los atributos no visibles. No guardar fotos en el servidor ni incluirlas en registros.
- Separar conceptualmente apariencia elegida, evolución permanente y reacciones temporales. Los detalles de recompensas y cambios por estadísticas todavía están por definir.
- El usuario autorizó expresiones automáticas según el desempeño. Son reacciones temporales del rostro, separadas de los rasgos y colores guardados. Respetar movimiento reducido y la preferencia de animaciones; derivarlas de las estadísticas del usuario actual. Documentar los umbrales como elecciones provisionales, no como acuerdos definitivos ni interpretaciones de su estado de salud.
- El usuario priorizó tanto ropa como rasgos físicos. La primera personalización implementada cambia colores de piel, cabello, camiseta y pantalón; no describirla como cambio de peinado o de forma de prendas.
- Desde la entrega de peinados hay cuatro opciones seleccionables para ambos personajes: Original, Corto, Rizado y Recogido. El peinado es independiente del color del cabello y debe conservarse al cambiar colores o personaje. Por ahora son variantes PNG completas; no presentarlas como capas intercambiables ni como edición de la forma de las prendas.
- Ojos, nariz y boca son selecciones independientes para ambos personajes. Conservarlas al cambiar peinado, colores, personaje o movimiento. Los rasgos originales son el valor compatible con preferencias antiguas. Son variantes visuales estáticas; no describirlas como animaciones faciales.
- La ropa admite colores RGB personalizados; el color de ojos es independiente de su forma. Las cejas siguen el color del cabello. Conservar estos colores al cambiar otros atributos. Mantener la descarga del APK de prueba en la primera línea del README principal y documentar su compilación en `scripts/README.md`; nunca incluir claves de OpenAI en un APK.
- Conservar la posición elevada y el tamaño del avatar aprobados. Mantener sus animaciones sutiles y respetar movimiento reducido y la preferencia de desactivarlas.
- La personalización incluye deslizantes manuales de complexión y altura. Conservarlos al cambiar otros atributos o aplicar una propuesta de foto. La altura aprobada es el máximo; las proporciones se guardan con la apariencia, sin relacionarlas con salud, peso real ni estadísticas. Los valores originales deben mantener el aspecto anterior.
- Las categorías de tarea son un conjunto fijo de cuatro: Educación (id 1), Finanzas (id 2), Salud (id 3) y Disciplina (id 4). No se crean categorías nuevas desde la API ni desde la app.
- Una tarea puede ser personal (sin `idProyecto` ni `idResponsable`) o de proyecto. La regla "todo participante de un proyecto debe pertenecer a su equipo" solo aplica a las tareas de proyecto.
- Toda tarea tiene al menos una categoría; el endpoint de creación lo exige (`min_length=1`).
- Para usuarios reales, una tarea completada no se puede desmarcar mientras no exista un endpoint que sincronice esa operación; la cuenta de práctica conserva el desmarcado local.
- Para usuarios reales, completar una tarea requiere confirmación previa (modal), porque la acción no se puede deshacer; la cuenta de práctica completa sin confirmación.

## Continuidad y documentación

- Desde el 2026-11-13 el APK de prueba público se guarda en la raíz como `my-daily-rutine-android-arm64.apk` y se enlaza para descarga desde la primera línea del README. Compilarlo con las URLs públicas de Render y usar el JWT del usuario para fotos; no incluir el token compartido ni secretos del backend. Las compilaciones privadas permanecen ignoradas en `artifacts/`.

- El panel HTML abierto con Live Server usa una URL fija de Render y muestra únicamente usuario y contraseña administrativos (2026-11-13). Reutilizar `ADMIN_USER` y `ADMIN_PASSWORD` del entorno del servidor; no duplicar variables ni pedir al usuario la URL en el formulario.

- Consultar `docs/decisiones-avatar.md` antes de trabajar en el avatar.
- Registrar decisiones relevantes con fecha, motivo, alcance y pendientes. Distinguir acuerdos del usuario de propuestas y elecciones provisionales de implementación.
- Actualizar este archivo cuando el usuario establezca o cambie una regla duradera. Sus nuevas instrucciones prevalecen sobre acuerdos anteriores.
- Comunicar avances y resultados en español, indicando qué se implementó y qué sigue pendiente.

## Trabajo en el repositorio

- Todo el código de API y backend debe vivir exclusivamente en `backend/`. No crear servicios paralelos en `api/`, `API/` u otra carpeta. `backend/app.py` es el único punto de entrada FastAPI y reúne las rutas de usuarios, autenticación y avatar; reutilizar sus módulos auxiliares antes de crear otros.
- El despliegue en Render se configura mediante **New → Web Service**, por elección del usuario (2026-11-13). Mantener los comandos y variables en `backend/docs/render.md`, con Root Directory vacío para resolver imports `backend.*`; el panel administrativo permanece local y se deshabilita en Render mediante `ADMIN_ENABLED=false`.
- Mapa del repositorio: `my_daily_routine/` es el frontend Flutter; `backend/` es el servidor Python; `backend/database/` contiene conexión y consultas Python de MySQL; `database/` en la raíz contiene el esquema SQL y las instrucciones de inicialización/conexión (no otro servidor). `backend/models/` contiene modelos Pydantic; `backend/core/` la seguridad/JWT; `backend/utils/` utilidades y diagnósticos; `backend/test/` pruebas; `backend/docs/` contratos de la API; `docs/` decisiones del proyecto; `scripts/` compilación y `artifacts/` entregables.
- En las rutas protegidas de datos, `idUsu` se obtiene exclusivamente del JWT (`sub`), nunca de un campo enviado por el cliente.
- Usar un único `backend/.env`, su plantilla `backend/.env.example` y `backend/requirements.txt` para OpenAI, Aiven y autenticación. Iniciar desde la raíz con `python -m uvicorn backend.app:app`; usar imports absolutos `backend.*`. No duplicar el SQL de `database/` dentro del backend.
- El panel HTML administrativo vive en `backend/admin/`, con `index.html`, `admin.js` y `admin.css` separados. Toda su API HTTP, autenticación y entrega de archivos se definen directamente en `backend/app.py`; no crear otro `admin.py` para las rutas. Las consultas SQL auxiliares permanecen en `backend/database/admin.py`. El JavaScript consulta la API JSON del mismo servidor para mostrar tablas y registros. Su primera versión es de consulta, protegida por credenciales administrativas independientes; no exponer contraseñas, hashes ni secretos. Las relaciones se obtienen de las claves foráneas de MySQL.
- Mantener `app.py`, `requirements.txt` y los archivos `.env` del servicio en la raíz de `backend/`. Agrupar las pruebas en `backend/test/` y las utilidades en `backend/utils/`. Documentar los comandos de ejecución y prueba en el emulador en `backend/README.md`.
- Mantener el certificado CA de Aiven completo dentro de `DB_SSL_CA` en `backend/.env`, como PEM multilínea entre comillas, por preferencia del usuario. No exigir una ruta persistente a otro archivo; los clientes que necesiten un archivo pueden usar una copia temporal eliminada al terminar. Mantener las credenciales exclusivamente en el backend y verificar TLS.
- El usuario autorizó acceso automático al panel desde el mismo equipo: no pedir contraseñas en localhost ni enviarlas al HTML/JS. El backend lee el `.env` para acceder a Aiven. Limitar la excepción a loopback, host local y origen local permitido, sin proxies; conservar autenticación para conexiones no locales. Esta regla sustituye el requisito inicial de credenciales para cada acceso al panel.
- El 2026-11-13 el usuario solicitó que el HTML administrativo consulte Render. Live Server apunta a `https://my-daily-rutine.onrender.com`; el backend remoto requiere `ADMIN_ENABLED=true`, credenciales administrativas y orígenes CORS explícitos. Esto sustituye la decisión inicial de mantener el panel deshabilitado en Render. Conservar autorización solo en memoria del navegador; no incrustar secretos ni ampliar la excepción de acceso local al servidor remoto.

- Revisar el estado de Git y conservar cambios existentes ajenos a la tarea.
- Mantener las responsabilidades de pantallas, widgets y datos separadas; reutilizar la estructura Flutter existente.
- Guardar recursos consumidos por la app dentro del proyecto. Versionar nuevos diseños sin eliminar sus originales.
- No introducir dependencias para funciones que Flutter ya resuelva de forma suficiente.
- Ejecutar formato y análisis sobre los archivos Dart modificados; realizar verificaciones proporcionales al cambio. Informar cuando una comprobación no pueda ejecutarse.
- No presentar diseños, animaciones o funcionalidades futuras como ya implementados.
