# Decisiones sobre el avatar

## 2026-11-05 — Inclusión explícita de subcarpetas de assets

Al revisar un bloqueo al entrar a inicio, se detectó que `lib/assets/` por sí sola no incorpora imágenes guardadas en subcarpetas. Se añadieron entradas explícitas para `avatar/`, `background/`, `icons/` y `recursos/` en `pubspec.yaml`. Las rutas del código ya apuntan a esas carpetas. El usuario debe hacer un nuevo build/instalar de nuevo para que los assets se empaqueten con el manifiesto actualizado; hot reload no actualiza un paquete instalado.

## 2026-11-05 — Organización de recursos de avatar

Se agrupan los PNG de personajes en `my_daily_routine/lib/assets/avatar/` para separar las ilustraciones de avatar de fondos, iconos y otros recursos. Se trasladaron los avatares heredados y las variantes v1, v2 y femenina; no se modificaron sus contenidos ni se eliminaron originales. `pubspec.yaml` declara la carpeta de avatar de forma explícita; Flutter no incluye automáticamente subdirectorios al declarar solo la carpeta padre. `AppAssets` ahora apunta a las nuevas rutas de los personajes activos.

Pendiente: ninguno para el cambio de rutas.

## 2026-11-05 — Organización de recursos adicionales

A petición del usuario, `davo.png` e `icon_app.png` se trasladaron a `my_daily_routine/lib/assets/recursos/`. La referencia de Davo en inicio ahora usa `AppAssets.davo`; se añadió también `AppAssets.iconApp` para la ruta del icono. `pubspec.yaml` declara `lib/assets/recursos/` explícitamente. Los PNG no se modificaron.

## 2026-11-05 — Organización de fondos

A petición del usuario, los cuatro fondos de inicio se agrupan en `my_daily_routine/lib/assets/background/` y `AppAssets.homeBackgrounds` apunta a esas rutas. `pubspec.yaml` declara `lib/assets/background/` explícitamente; declarar la carpeta padre no basta para incluir subdirectorios. Los archivos de imagen no se alteraron.

## 2026-11-05 — Variante femenina seleccionable

El usuario pidió agregar al apartado de avatar un personaje femenino que siga la estructura del personaje existente y proporcionó `my_daily_routine/lib/assets/human_girl.png`.

- Se conserva el PNG original y se incorpora el personaje femenino como variante completa. Ambos recursos tienen lienzo transparente de 887 × 1774.
- En **Tu avatar** se puede elegir **Hombre** o **Mujer**. La selección se guarda con los colores y la preferencia de movimiento y aparece también en inicio.
- Las paletas y la animación existentes se reutilizan. El shader amplía la zona de cabello para recolorear el cabello largo de la nueva ilustración.
- La opción predeterminada sigue siendo Hombre para instalaciones y configuraciones existentes. Esta selección es independiente del género elegido en el formulario de registro; enlazarla a una cuenta queda pendiente hasta que exista una sesión persistente.
- No se reemplazan ni se alteran los recursos originales. La nueva imagen se consume desde la carpeta de assets ya declarada.

Archivos: `lib/assets/human_girl.png`, `lib/assets_paths.dart`, `lib/models/avatar_config.dart`, `lib/widgets/avatar/avatar_character.dart`, `lib/screens/avatar.dart` y `shaders/avatar_colors.frag`.

Verificación: formato y análisis de los Dart modificados completados; análisis sin incidencias. La imagen tiene canal alfa y coincide con el tamaño del avatar existente. No se ejecutaron pruebas ni se revisó en un dispositivo.

## 2026-11-04 — Personalización de colores y movimiento suave

El usuario pidió continuar con personalización y animaciones y eligió priorizar «Ambas: ropa y rasgos físicos».

### Funcionalidad implementada

- El botón **Avatar** de inicio abre **Tu avatar** (`/avatar`). Hay cinco opciones independientes por categoría: tono de piel, color de cabello, camiseta y pantalón. Se mantiene la figura v2 aprobada.
- El editor usa un borrador con vista previa. **Guardar cambios** persiste y aplica; volver descarta el borrador. **Restablecer** modifica solo el borrador hasta guardarlo. Un fallo al guardar muestra un mensaje y conserva la configuración aplicada.
- Inicio y miniatura comparten `AvatarStore`. Los colores se guardan localmente con `shared_preferences` (2.5.5 resuelta desde la caché local); Flutter no incluye un almacén multiplataforma equivalente. No hay envío de fotos ni llamadas API.
- La preferencia es del dispositivo, no de una cuenta: el repositorio aún no tiene una sesión de usuario persistente. Cuando se incorpore, habrá que asociar la configuración al usuario. Las tareas y demás almacenes mantienen su comportamiento previo.
- Un shader de Flutter recolorea el PNG al dibujarlo. Conserva transparencia, luces y sombras sin editar el recurso original. Sus zonas se basan en colores y posiciones del **PNG v2**; cambiar de recurso exige revisar las máscaras y las pruebas. Los ojos y zapatillas conservan su color; cabello y cejas comparten color.
- Movimiento de reposo: escala sutil anclada en los pies, ciclo de ida y vuelta de 5,6 segundos (hasta 0,4 % horizontal y 0,8 % vertical). **Probar reacción suave** añade un pulso breve en el editor. No se trata de respiración anatómica ni de animación por huesos.
- El movimiento se pausa por preferencia, accesibilidad (`disableAnimations`), `TickerMode` o app en segundo plano. Los controladores y shaders de cada vista se liberan al desmontarla; imagen y programa compilado se reutilizan durante el proceso.
- La posición y el espacio del avatar en inicio permanecen como estaban aprobados.

### Archivos y límites

`models/avatar_config.dart` define las opciones; `data/avatar_store.dart` carga y guarda; `widgets/avatar/avatar_character.dart` renderiza y anima; `shaders/avatar_colors.frag` aplica colores; `screens/avatar.dart` presenta el editor.

Todavía no hay capas intercambiables, selección libre de peinados, prendas con otra silueta, accesorios, parpadeo, saludo con la mano ni celebraciones conectadas a tareas. Esta implementación permite personalizar los dos personajes disponibles mientras esas piezas se preparan.

### Validación y cómo probar

Cinco pruebas Flutter pasan en `test/avatar_test.dart`: recuperación de preferencias en una instancia nueva, datos inválidos y fallo de escritura, pausa del movimiento, renderizado con regiones independientes/transparencia/ojos protegidos, y navegación del editor con descarte y guardado. La prueba de render genera `build/avatar-preview.png` como evidencia local, sin versionarlo. Se inspeccionó esa imagen y se corrigió una recoloración no deseada de los ojos. El flujo usa un almacén de prueba; no equivale a haber verificado el plugin en un teléfono físico.

Para probar en el emulador: detener y ejecutar de nuevo `flutter run` desde `my_daily_routine` (esta entrega añade un plugin nativo y un shader; hot reload por sí solo no basta). Abrir **Avatar**, elegir colores, probar el movimiento y guardar. Cerrar/reabrir la aplicación para comprobar la persistencia del dispositivo. La ejecución interactiva en el emulador del usuario sigue pendiente.

Referencias técnicas: [shaders de Flutter](https://docs.flutter.dev/ui/design/graphics/fragment-shaders) y [shared_preferences](https://pub.dev/packages/shared_preferences).

## 2026-11-04 — Posición y tamaño tras revisar la captura

El usuario pidió subir y ampliar ligeramente el personaje porque el botón de añadir tarea tapaba sus pies. Se cambia la alineación de `Alignment(0, 0.25)` a `Alignment(0, -0.30)` y el espacio máximo del avatar del 50 % al 58 % del ancho y alto de pantalla (un incremento relativo del 16 %). `BoxFit.contain` conserva la figura completa y sus proporciones.

La captura también mostraba desbordamientos verticales en ambas columnas laterales. Sus botones ahora calculan el tamaño usando la altura disponible mediante `LayoutBuilder`, descontando los espacios entre controles y conservando sus tamaños habituales cuando caben.

Formato y análisis de los dos archivos Dart modificados completados sin incidencias. No se comprobó visualmente en el emulador; queda pendiente confirmar el resultado del ajuste en el dispositivo del usuario.

## 2026-11-04 — Integración del avatar v2

El usuario solicitó implementar en la aplicación el avatar con el estilo de la referencia. Se generó un nuevo personaje original usando la imagen compartida únicamente como guía visual: proporciones juveniles más alargadas, formas suaves y sombreado discreto. El cabello castaño, la camiseta turquesa y los pantalones oscuros son elecciones del prototipo, no restricciones para futuros avatares.

- Recurso activo: `my_daily_routine/lib/assets/avatar_human_v2.png`, PNG de 887 × 1774 con transparencia, generado con la herramienta integrada de imágenes.
- `AppAssets.avatar` apunta a v2. Se conservan v1 y los recursos originales.
- La pantalla principal mantiene el personaje centrado horizontalmente, ligeramente por debajo del centro vertical, con el encuadre adaptable de `AvatarSlot` y sin deformar la imagen.
- La miniatura del saludo utiliza el mismo recurso, encuadrando su parte superior mediante `BoxFit.cover` y `Alignment.topCenter`. Así evita mostrar un personaje diferente y no necesita otra imagen generada.
- No se añaden dependencias ni conexión a OpenAI desde la aplicación.
- Esta entrega integra la apariencia estática. No implementa capas, animaciones, edición de rasgos ni efectos por estadísticas.

El prompt exacto se incluye en `avatar-prompts.md`. Las secciones inferiores conservan el historial de decisiones y describen el estado de entregas anteriores.

Verificación de v2: formato de los archivos Dart modificados y análisis de `assets_paths.dart`, `home.dart` y `home_scene.dart` sin incidencias. Se confirmó que el PNG tiene canal alfa y esquina transparente, y que su carpeta ya está declarada en `pubspec.yaml`. No se ejecutó la app en un dispositivo; la revisión visual interactiva sigue pendiente.

## 2026-11-04 — Refinamiento visual confirmado por el usuario

La referencia principal pasa a ser la imagen compartida en la conversación: personaje humano de cabello voluminoso, gafas, camiseta azul, mochila y pantalones claros en una habitación azul. Esta descripción identifica la referencia; esos elementos particulares no son requisitos del avatar. La imagen está en la conversación y no se ha guardado como archivo en el repositorio.

El usuario confirmó: «solo tomemos esto como referencia visual porfavor para que los avatares tengan ese estilo».

Se adopta su lenguaje gráfico: aspecto juvenil, cabeza ligeramente sobredimensionada, cuerpo más alargado y menos infantil que el concepto v1, contornos suaves, volúmenes simplificados y sombras discretas. Estos criterios se aplicarán a los futuros avatares para mantener coherencia visual.

El cabello, la piel, la ropa y los accesorios seguirán siendo variables. No se adopta la identidad del personaje, sus marcas, sus gafas, sus audífonos ni su mochila como elementos obligatorios. Las manos fuera de los bolsillos y los brazos separados siguen siendo una propuesta técnica para facilitar la animación, no una pose aprobada por el usuario.

Esta decisión refina la dirección inicial descrita abajo. El PNG v1 permanece como prototipo anterior; esta actualización documental no genera ni integra una nueva versión gráfica. La próxima revisión del recurso deberá aplicar el estilo aquí descrito. La integración con fotos e IA sigue pospuesta.

## 2026-11-04 — Dirección acordada

El usuario quiere un avatar humano con estilo de dibujo animado similar al lenguaje visual de Duolingo, situado en el centro de la pantalla principal. El cumplimiento de tareas aporta estadísticas que afectarán al avatar. La identidad gráfica debe ser propia.

Se adopta como dirección un personaje 2D de formas redondeadas, cabeza grande y cuerpo compacto. Se plantea construirlo por piezas para permitir personalización y reutilizar animaciones. El parecido con una foto mediante OpenAI queda expresamente pospuesto hasta que el avatar base esté listo.

### Primera entrega: concepto visual

- Recurso: `my_daily_routine/lib/assets/avatar_human_v1.png`.
- Generado con la herramienta integrada de generación de imágenes, sin conectar la aplicación a ninguna API.
- La piel, el cabello corto, la ropa turquesa y los pantalones oscuros son elecciones provisionales para explorar el diseño; no son preferencias definitivas del usuario ni representan su apariencia.
- PNG transparente de cuerpo completo. Se conserva el recurso anterior `avatar.png`.
- `AppAssets.avatar` apunta al nuevo concepto y `AvatarSlot` lo muestra sobre el fondo existente, centrado horizontalmente y ligeramente por debajo del centro vertical para respetar la cabecera.
- Se reduce el ancho reservado al 50 % de la pantalla. La altura máxima sigue siendo el 50 % y `BoxFit.contain` mantiene las proporciones.
- Se conserva por ahora la miniatura anterior del saludo: el nuevo recurso es un cuerpo completo, no un retrato preparado para ese espacio.

### Alcance real

Este prototipo es una imagen única y estática. No tiene capas editables, parpadeo, respiración, saludo, celebraciones, recompensas ni conexión con estadísticas. Su finalidad es revisar primero estilo, proporciones y presencia en la pantalla real. No se añade Rive ni otra dependencia hasta definir qué animaciones y piezas necesita el diseño.

### Próximas etapas propuestas

1. Revisar el concepto con el usuario y ajustar rostro, proporciones y ropa.
2. Preparar piezas con un lienzo, anclajes y orden de dibujo compartidos: cabello posterior, cuerpo/ropa, cabeza, rasgos, cabello frontal y accesorios.
3. Incorporar reposo, saludo y celebración respetando las preferencias de movimiento reducido.
4. Definir con el usuario cómo cada estadística modifica la evolución visual y conectar los eventos de tareas sin duplicar la lógica de datos.
5. Abordar la personalización a partir de fotos. Evaluar entonces si la IA configura rasgos disponibles o genera recursos compatibles. Una imagen generada no es automáticamente un personaje por capas ni una animación; no prometer parecido exacto con un catálogo limitado.

La apariencia elegida por el usuario, la evolución permanente y las reacciones temporales deben poder cambiar de forma independiente. Los umbrales, recompensas y efectos concretos aún no están acordados.

## Cómo revisar el prototipo

Desde `my_daily_routine`, ejecutar `flutter run` en un dispositivo configurado. Revisar la pantalla de inicio, alternar los cuatro fondos y comprobar que el personaje conserve sus proporciones y que los botones sigan siendo accesibles. Revisar también un teléfono estrecho. La revisión visual interactiva queda pendiente si no hay un dispositivo disponible.

Los prompts de generación y refinamiento se guardan en `avatar-prompts.md`.

## Verificación de esta entrega

- Formato aplicado a los tres archivos Dart modificados.
- Análisis de esos tres archivos con el ejecutable Dart del SDK local: sin incidencias. El lanzador habitual de Flutter/Dart no produjo salida, por lo que se usó directamente el ejecutable del SDK.
- PNG confirmado en formato de 32 bits con canal alfa y muestras externas completamente transparentes.
- No se ejecutó la aplicación en un dispositivo: queda pendiente comprobar visualmente la composición con los controles y todos los fondos. No se afirma que exista una prueba visual interactiva ni animaciones implementadas.
