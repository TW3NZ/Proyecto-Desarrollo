# Reglas del proyecto My Daily Rutine

Estas instrucciones aplican a todo el repositorio. Leerlas antes de modificarlo.

## Acuerdos de producto

- La aplicación Flutter relaciona el cumplimiento de tareas con estadísticas y la evolución de un avatar.
- El avatar principal debe ser humano, de cuerpo completo y protagonista en el centro de la pantalla de inicio, con espacio para los controles laterales.
- Usar como referencia visual principal la imagen compartida por el usuario: avatar humano juvenil, cabeza algo grande, cuerpo más alargado que el primer prototipo, formas suaves, silueta clara y sombras discretas. Esta referencia concreta refina la inspiración inicial en Duolingo; mantener identidad propia.
- Aplicar ese lenguaje visual a todos los avatares, sin fijar el cabello, tono de piel, ropa, gafas, audífonos, mochila, marcas ni pose del personaje de referencia. El usuario confirmó que solo se toma su estilo de dibujo.
- La dirección acordada es un avatar personalizable por piezas. La primera entrega es un concepto PNG para revisar el diseño; no confundirlo con un sistema de capas terminado.
- Posponer la conexión a OpenAI y la creación de avatares a partir de fotos hasta que el avatar base esté listo y el usuario retome esa etapa. No añadir ahora llamadas API, carga de fotos ni credenciales.
- Separar conceptualmente apariencia elegida, evolución permanente y reacciones temporales. Los detalles de recompensas y cambios por estadísticas todavía están por definir.
- El usuario priorizó tanto ropa como rasgos físicos. La primera personalización implementada cambia colores de piel, cabello, camiseta y pantalón; no describirla como cambio de peinado o de forma de prendas.
- Conservar la posición elevada y el tamaño del avatar aprobados. Mantener sus animaciones sutiles y respetar movimiento reducido y la preferencia de desactivarlas.

## Continuidad y documentación

- Consultar `docs/decisiones-avatar.md` antes de trabajar en el avatar.
- Registrar decisiones relevantes con fecha, motivo, alcance y pendientes. Distinguir acuerdos del usuario de propuestas y elecciones provisionales de implementación.
- Actualizar este archivo cuando el usuario establezca o cambie una regla duradera. Sus nuevas instrucciones prevalecen sobre acuerdos anteriores.
- Comunicar avances y resultados en español, indicando qué se implementó y qué sigue pendiente.

## Trabajo en el repositorio

- Revisar el estado de Git y conservar cambios existentes ajenos a la tarea.
- Mantener las responsabilidades de pantallas, widgets y datos separadas; reutilizar la estructura Flutter existente.
- Guardar recursos consumidos por la app dentro del proyecto. Versionar nuevos diseños sin eliminar sus originales.
- No introducir dependencias para funciones que Flutter ya resuelva de forma suficiente.
- Ejecutar formato y análisis sobre los archivos Dart modificados; realizar verificaciones proporcionales al cambio. Informar cuando una comprobación no pueda ejecutarse.
- No presentar diseños, animaciones o funcionalidades futuras como ya implementados.
