# Reglas del proyecto My Daily Rutine

Estas instrucciones aplican a todo el repositorio. Leerlas antes de modificarlo.

## Acuerdos de producto

- La aplicación Flutter relaciona el cumplimiento de tareas con estadísticas y la evolución de un avatar.
- Cada registro de estadísticas pertenece a un usuario mediante `usuarioId`; sus valores y preferencias son independientes por cuenta.
- Los IDs de entidades y sus referencias son enteros. Los IDs negativos son temporales de Flutter en memoria; los definitivos los entrega FastAPI.
- `Equipo` representa el espacio de trabajo y sus miembros; `Proyecto` es una entidad propia y cada proyecto pertenece a un equipo mediante `equipoId`. Las tareas de proyecto se relacionan con `proyectoId`.
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

## Continuidad y documentación

- Consultar `docs/decisiones-avatar.md` antes de trabajar en el avatar.
- Registrar decisiones relevantes con fecha, motivo, alcance y pendientes. Distinguir acuerdos del usuario de propuestas y elecciones provisionales de implementación.
- Actualizar este archivo cuando el usuario establezca o cambie una regla duradera. Sus nuevas instrucciones prevalecen sobre acuerdos anteriores.
- Comunicar avances y resultados en español, indicando qué se implementó y qué sigue pendiente.

## Trabajo en el repositorio

- Mantener `app.py`, `requirements.txt` y los archivos `.env` del servicio en la raíz de `backend/`. Agrupar las pruebas en `backend/test/` y las utilidades en `backend/utils/`. Documentar los comandos de ejecución y prueba en el emulador en `backend/README.md`.

- Revisar el estado de Git y conservar cambios existentes ajenos a la tarea.
- Mantener las responsabilidades de pantallas, widgets y datos separadas; reutilizar la estructura Flutter existente.
- Guardar recursos consumidos por la app dentro del proyecto. Versionar nuevos diseños sin eliminar sus originales.
- No introducir dependencias para funciones que Flutter ya resuelva de forma suficiente.
- Ejecutar formato y análisis sobre los archivos Dart modificados; realizar verificaciones proporcionales al cambio. Informar cuando una comprobación no pueda ejecutarse.
- No presentar diseños, animaciones o funcionalidades futuras como ya implementados.
