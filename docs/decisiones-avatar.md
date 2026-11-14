# Decisiones sobre el avatar

## 2026-11-13 — APK descargable sin token compartido

Para publicar el APK conectado a Render, el servicio de fotos admite el JWT
de una sesión real. Flutter lo utiliza después de iniciar sesión; la compilación
pública no contiene el token compartido del servicio ni claves de OpenAI.
El token de desarrollo anterior sigue siendo compatible con compilaciones privadas.

## 2026-11-12 — Vestuario superpuesto al personaje

A petición del usuario, se añade un sistema de prendas que se dibujan sobre el avatar. La primera prenda es **Developer skin** (camiseta de estilo GitHub), disponible solo para el personaje hombre porque su silueta encaja únicamente con el torso masculino.

- **Recursos:** `my_daily_routine/lib/assets/items/` (declarada explícitamente en `pubspec.yaml`). Cada prenda es un PNG transparente con el **mismo lienzo de 887 × 1774** y el cuerpo en la misma posición que los avatares base, para superponerse píxel a píxel.
- **Modelo:** enum `AvatarOutfit` (`ninguno`, `developerSkin`) con `label`, `assetPath` y `soloHombre`; `AvatarConfig` incorpora `outfit`, serializado por nombre y retrocompatible (`ninguno` por defecto). `withOutfit` rechaza prendas de hombre para mujer y `withCharacterType` revierte a `ninguno` al cambiar a mujer.
- **Render:** la prenda se carga aparte (caché por outfit) y se dibuja con `canvas.drawImage` **después** del shader, en el mismo `CustomPaint`; queda alineada y cubre camiseta/pantalón sin alterar el rostro.
- **Editor:** nueva sección **Vestuario** en `Tu avatar`, con tarjetas por prenda; «Ninguno» muestra el personaje base y cada prenda muestra su propia imagen. El selector filtra las prendas según el personaje.
- **Coherencia visual:** se mantienen el lienzo y la pose de los personajes actuales; las prendas no introducen siluetas ni encuadres nuevos.

**Límite v1:** la prenda no sigue la deformación de los deslizantes de complexión/altura (queda alineada con las proporciones por defecto). `flutter analyze` y `flutter test` en verde.

## 2026-11-10 — Boca cansada y mechón derecho

El usuario detectó una sonrisa residual en Cansado y un mechón del peinado original que no recibía el color. La boca de la referencia neutra conservaba las comisuras levantadas: para cansancio se refleja verticalmente solo su región interior, con transición gradual y límites por personaje para no muestrear el borde de la mejilla. No se modifica la boca elegida ni los demás estados.

La máscara rectangular que protegía el rostro excluía también el mechón derecho. Se reemplaza esa exclusión general por las regiones concretas de ojos, nariz y boca. Se conserva el filtro de color y altura para proteger ropa y piel.

Se revisó visualmente la lámina de expresiones de ambos personajes y se añadieron regresiones para distinguir la boca cansada de la boca de aburrimiento y teñir el mechón derecho del peinado original con plateado, rubio y negro conservando los ojos. Once pruebas de expresiones, peinados y rostro pasan; formato y análisis de los tests sin incidencias.

## 2026-11-10 — Expresiones vinculadas al progreso

El usuario pidió que el avatar refleje el desempeño: ánimo positivo con estadísticas altas y cansancio o aburrimiento con valores bajos. Se implementan cuatro reacciones temporales en el inicio, separadas de `AvatarConfig`. Se actualizan al notificarse cambios del almacén de estadísticas y se calculan con el progreso general de la cuenta actual.

**Umbrales provisionales de implementación:** menos de 25, cansado; de 25 a menos de 50, aburrido; de 50 a menos de 75, tranquilo; desde 75, alegre. Si no hay categorías activas, se muestra tranquilo. Las cuentas nuevas con progreso cero se muestran cansadas. Esto representa un estado del juego, no salud o emociones reales del usuario. El promedio sigue la configuración existente de categorías activas, por lo que cambiar esas preferencias también puede cambiar la expresión.

El shader estrecha suavemente los ojos para cansancio/aburrimiento y mezcla la boca neutra o sonriente de los recursos existentes. Tranquilo conserva los rasgos elegidos. No se sobrescribe la apariencia ni se generan imágenes nuevas. La transición dura 450 ms y se desactiva si el usuario deshabilita movimiento o el sistema solicita movimiento reducido. El editor incorpora **Expresiones** para previsualizar las cuatro sin modificar estadísticas ni guardar una expresión forzada.

Se corrigió además la asignación de puntos: `procesarTareaCompletada` ahora usa `tarea.usuarioId`, en vez de la cuenta abierta, para no atribuir progreso ajeno al avatar actual. No se cambia el sistema de puntos, vencimientos ni recompensas.

**Límites:** las estadísticas actuales acumulan puntos y no decaen por inactividad; por tanto, no existe todavía cansancio progresivo por dejar tareas pendientes. Las tareas/estadísticas siguen en memoria y se reinician con el proceso. Los gestos usan deformación y mezcla de los recursos actuales, no un sistema de animación facial por huesos.

**Validación:** 24 pruebas del avatar pasan, incluidas cuatro de expresiones: umbrales, actualización del inicio al ganar puntos, aislamiento por usuario y renderizado de ambos personajes. Se revisó `build/avatar-expressions-preview.png`: ojos más cerrados en cansancio, gesto intermedio de aburrimiento y sonrisa amplia en alegría. Las variantes solo alteran el rostro y conservan la configuración guardada. La revisión interactiva en el teléfono sigue pendiente.

Se recompiló y verificó el APK release ARM64 de prueba con las expresiones, actualizando `artifacts/my-daily-rutine-android-arm64.apk` (aproximadamente 49.4 MB), enlazado en la primera línea del README. Conserva firma de desarrollo y no incluye credenciales del servicio de fotos.

## 2026-11-10 — Colores libres, ojos y cejas

El usuario pidió ampliar los colores de la ropa, añadir color de ojos, confirmar el vínculo de cejas/cabello y preparar un APK descargable con instrucciones. Se conservan los IDs anteriores y se admiten colores `#RRGGBB` para camiseta y pantalón. El editor ofrece veinte muestras adicionales y un diálogo de tono/saturación/brillo con entrada hexadecimal; aplica solo al confirmar. No añade tipos de prendas ni un suéter nuevo.

`eyeColor` se guarda independientemente de la forma de ojos, con `original` como valor compatible. El shader tiñe los píxeles marrones del iris en las regiones de ojos, protegiendo blancos y reflejos; el color final conserva sombreado y no es necesariamente el RGB plano elegido. Se explicita una máscara de cejas para corregir zonas excluidas por la protección del rostro y vincularlas al cabello. Las máscaras se calibran para las ilustraciones actuales, no son segmentación anatómica general.

La propuesta desde una foto mantiene el color de ojos manual y sigue usando el catálogo previo para los colores sugeridos de ropa; el selector libre es una función de edición manual. Se añadieron pruebas de persistencia RGB, validación hexadecimal y cambios de píxeles de ojos/cejas en ambos personajes. Se adapta la prueba de guardar al desplazamiento del editor ampliado.

Compilación reproducible: `scripts/build-apk.ps1` y [guía del APK](../scripts/README.md). El APK compartible no lleva credenciales ni activa por sí solo el servicio de fotos. Los builds con token local tienen un nombre privado ignorado por Git. La firma release del proyecto sigue siendo de desarrollo, pendiente de firma propia para publicación formal.

Verificación: veinte pruebas de avatar pasan (incluido el editor tras ajustar su desplazamiento), análisis Dart sin incidencias y compilación release ARM64 completada. Artefacto de aproximadamente 49.4 MB en `artifacts/my-daily-rutine-android-arm64.apk`. El script PowerShell pasa validación sintáctica; la compilación en esta máquina se ejecutó directamente con Flutter. Falta instalar y revisar este APK en un teléfono físico.

## 2026-11-10 — Encuadre de rostro y mayor anchura máxima

El usuario detectó que al reducir la altura desaparecía la cara en el editor de rostro. Ese recorte usaba el renderizado de cuerpo completo, que desplazaba la cabeza al reducir la altura. Se activa `portrait: true` en `AvatarFaceSelector`, de forma que el encuadre facial ignore las proporciones corporales y conserve los rasgos elegidos sin modificar el avatar guardado.

También pidió ampliar el extremo ancho un 20–30 % y mantener el delgado. El límite del parámetro pasa de 1.2 a 1.5 (25 % de aumento del parámetro), conservando mínimo 0.8, original 1.0 y todos los valores guardados. El cambio visual no equivale a un porcentaje exacto en píxeles, porque el shader deforma de forma acotada. Se actualizan rango, divisiones y etiquetas del deslizador. Las pruebas comparan el renderizado del editor de rostro antes y después de reducir altura para ambos personajes y comprueban que el nuevo extremo es visualmente más ancho que el anterior.

## 2026-11-10 — Deslizantes de complexión y altura

El usuario pidió controlar el ancho y alto del personaje. Se añaden dos deslizantes en **Tu avatar → Proporciones**, con vista previa mediante el renderizador existente, guardado local y restablecimiento independiente de los demás atributos. Los campos `bodyWidth` y `bodyHeight` se conservan al cambiar personaje, colores, peinado, rostro, movimiento y al aplicar una propuesta de foto. Las preferencias antiguas reciben valores originales (1.0); entradas inválidas o no finitas se normalizan.

Elección provisional: complexión de 0.8 a 1.2 mediante deformación horizontal acotada del cuerpo, con transición suave bajo la cabeza y extremos del lienzo fijos. Altura de 0.8 a 1.0, donde 1.0 conserva el tamaño aprobado del inicio. La altura reduce verticalmente el dibujo anclado a la base, incluida la cabeza; no es un modelo anatómico ni una medida en centímetros. Las vistas de retrato permanecen sin deformar para no alterar sus recortes. El shader aplica primero la transformación de coordenadas y después los rasgos/colores, manteniendo su alineación. No se añaden dependencias, imágenes ni inferencia de proporciones por OpenAI.

Se prueban persistencia, compatibilidad, conservación al aplicar foto y diferencias reales de ancho y alto al renderizar ambos personajes. La revisión estética de todas las combinaciones y dispositivos queda pendiente; los límites se pueden ajustar tras esa revisión.

## 2026-11-10 — Estilo visual de la pantalla de foto

El usuario pidió adaptar esta pantalla al lenguaje de la app. Se reutilizan `CabeceraApp`, los colores y degradados de `theme.dart`, con tarjetas blancas redondeadas, sombras discretas y tres pasos: elegir foto, analizar y revisar propuesta. El estado inicial incluye un espacio ilustrado con icono; la foto seleccionada conserva sus proporciones. Los botones muestran estados habilitado/deshabilitado diferenciados, y privacidad, configuración y errores tienen bloques propios. Las acciones pueden ajustarse en varias filas y el contenido respeta el área segura inferior.

Se conserva la lógica de cámara, envío explícito, propuesta y guardado. No se añadieron dependencias ni llamadas nuevas al backend. Las cuatro pruebas del flujo pasan tras adaptar el desplazamiento a los botones del nuevo diseño; formato y análisis Dart sin incidencias. Pendiente la revisión visual interactiva en el emulador del usuario.

## 2026-11-10 — Configuración también al depurar directamente `main.dart`

El usuario confirmó que iniciar Debug desde `main.dart` seguía omitiendo la configuración. Los perfiles de lanzamiento no cubrían ese inicio implícito. Se configuró `dart.flutterRunAdditionalArgs` en ambos workspaces (raíz y carpeta Flutter), con el archivo local relativo al directorio del proyecto Flutter. Se retiró el argumento duplicado de los perfiles explícitos. Se verificó en la extensión Dart instalada que este ajuste se añade a los lanzamientos Flutter; no se cambió código Dart ni credenciales. La comprobación interactiva del editor y el emulador sigue pendiente.

## 2026-11-10 — Inicio desde VS Code con configuración de fotos

Ante el botón de análisis deshabilitado, se revisó que depende de la configuración compilada de Flutter o de una operación pendiente, no del estado del servidor. No había perfiles de inicio del editor que cargaran el JSON local. Se añadieron perfiles `My Daily Rutine - Avatar con fotos` para abrir el repositorio completo o solo la carpeta Flutter. No incluyen credenciales: referencian `.tools/avatar-flutter.json`. Se añadió un aviso junto al botón cuando falta configuración para hacer visible el motivo después de seleccionar una foto. La sesión instalada debe detenerse y volver a iniciarse con el perfil; este cambio no reconfigura automáticamente una app que ya esté abierta.

## 2026-11-10 — Organización del backend y guía del emulador

Por solicitud del usuario, `app.py`, `requirements.txt`, `.env` y `.env.example` permanecen en la raíz de `backend/`; las pruebas se agrupan en `backend/test/` y la configuración y diagnóstico en `backend/utils/`. Se ajustaron importaciones y rutas relativas para conservar la carga del mismo `.env` y del recurso de prueba. El comando actual de diagnóstico es `python -m backend.utils.check_connection`; la referencia anterior en esta bitácora corresponde al comando usado antes de reorganizar.

Se añadió [backend/README.md](../backend/README.md) con instalación, ejecución del servidor, configuración de Flutter, prueba en emulador Android y diagnóstico. La regla de organización se incorporó a `AGENTS.md`. Las ocho pruebas del backend pasan tras el cambio; no se repitió la llamada pagada a OpenAI ni se probó la cámara en esta reorganización.

## 2026-11-10 — Carga de `.env` y conexión real comprobada

El usuario creó `backend/.env` y pidió comprobar el envío y respuesta de OpenAI. Se detectó que el backend no cargaba archivos de entorno y que el proceso heredaba una clave distinta a la del proyecto. Se añadió `python-dotenv`: el archivo `backend/.env` tiene prioridad sobre el entorno del proceso; `.env` de raíz sirve como respaldo. No se modificaron ni mostraron las claves del usuario.

Se ejecutó `python -m backend.check_connection` con la clave del archivo: petición real a OpenAI, pasando por `/avatar/suggest` en FastAPI en proceso, usando la ilustración existente `avatar_human_v2.png`. Resultado HTTP 200, `status=ok`, atributos válidos del catálogo (todos `original` para esa ilustración). Esto verifica credenciales y contrato de respuesta; no demuestra parecido con una foto real ni conectividad desde un dispositivo.

Se preparó `.tools/avatar-flutter.json` local e ignorado por Git con la URL del emulador Android y el token del servicio, sin clave de OpenAI. La app debe reiniciarse con ese archivo y el servidor debe estar ejecutándose. Se añadieron pruebas de carga desde otro directorio, prioridad de archivo y respaldo del entorno; los ocho tests del backend pasan. No se modificó Dart ni fue necesario repetir sus pruebas. Sigue pendiente cámara/red y revisión del parecido en dispositivo.

## 2026-11-09 — Foto para sugerir atributos del catálogo

**Acuerdo del usuario:** retomar ahora la conexión a OpenAI para que una foto determine los valores más parecidos entre los atributos disponibles. Esto sustituye el aplazamiento registrado en las entradas históricas. No se solicitó generar una nueva ilustración.

**Implementación elegida:** Flutter permite cámara/galería, revisión de foto y envío explícito. Un servicio FastAPI nuevo valida y recodifica la imagen en memoria; Responses API devuelve una estructura restringida al catálogo. `gpt-4.1-mini` es una elección inicial configurable, no un requisito de producto. La clave queda en el entorno del servidor. Se añadieron `image_picker` y `http` porque Flutter no proporciona captura nativa ni un cliente HTTP multiplataforma de alto nivel equivalente.

La propuesta se previsualiza y se aplica al borrador con aceptación expresa; el botón de guardar existente confirma la persistencia. Se conservan personaje, movimiento y valores no visibles. No se infiere género ni identidad. Se gestionan errores de conexión, permisos, tamaño/formato, rechazo y fotos con varios rostros o sin rostro. No se alteran posición, escala ni animaciones del avatar principal.

**Límites y pendientes:** el catálogo limitado no garantiza parecido exacto; los descriptores de cada rasgo son aproximaciones del diseño actual. El servicio es un prototipo local separado del futuro backend de cuentas. Antes de desplegarlo necesita autenticación real por usuario y controles de consumo. No hay persistencia de fotos en servidor; la caché de cámara pertenece al plugin/sistema. Falta validación manual de cámara y resultados reales en dispositivo. Configuración y pruebas: [avatar-foto.md](avatar-foto.md).

**Verificación:** cinco pruebas del backend y cuatro nuevas pruebas Flutter pasan con OpenAI/cámara simulados; las doce pruebas existentes del avatar también pasan. Cubren autorización, imágenes inválidas y grandes, recodificación, contrato Responses, ausencia de clave/rechazo, catálogo válido, conservación de ajustes, envío explícito y aceptación de propuesta. Formato y análisis de los archivos Dart de esta entrega sin incidencias. No se realizó una llamada real a OpenAI ni captura en dispositivo. El entorno de pruebas Python muestra un aviso de deprecación de Starlette sobre su adaptador de pruebas HTTPX; no afecta a las cinco pruebas.

## 2026-11-09 — Ojos, nariz y boca independientes

El usuario pidió ampliar los tipos de ojos, nariz y boca para hombre y mujer. Se añade **Rostro** al editor, con vista ampliada y tres selectores independientes:

- Ojos: Originales, Almendrados, Redondos.
- Nariz: Original, Recta, Redondeada.
- Boca: Original, Sonrisa amplia, Neutral.

Esta selección inicial de estilos es una decisión de implementación. Se puede combinar cada rasgo con los demás, con cualquiera de los peinados y con las paletas existentes. Son 27 combinaciones de rasgos por personaje antes de contar peinados y colores. No son expresiones animadas ni reacciones automáticas a estadísticas.

### Recursos y composición

Se generaron cuatro PNG de referencia con `image_gen` integrado: `my_daily_routine/lib/assets/avatar/faces/{hombre,mujer}_{a,b}.png`. Cada uno conserva lienzo transparente de 887 × 1774. El conjunto A contiene ojos almendrados, nariz recta y sonrisa amplia; B contiene ojos redondos, nariz redondeada y boca neutral. Los prompts exactos están en `avatar-rostro-prompts.md`.

El renderizador toma únicamente la zona de cada rasgo del recurso elegido y la combina sobre la imagen del peinado actual. **No sustituye la cara completa al seleccionar una boca o una nariz.** Las máscaras normalizadas del shader incluyen bordes suavizados y están ajustadas a los personajes actuales. Después se aplica el tono de piel; ojos y boca están protegidos del tinte del cabello. La pose, ropa y cabello vienen del recurso de peinado; el tamaño y posición del avatar se mantienen.

Se conservan los originales. Las referencias de rostro se comparten en caché por personaje, sin duplicarlas por cada combinación. La carpeta de recursos se declara explícitamente en `pubspec.yaml`. No se añadieron dependencias ni una conexión API desde la app.

Límite: las máscaras están calibradas para estas ilustraciones y no equivalen a un modelo vectorial o un sistema de huesos. Una futura ilustración con posiciones faciales diferentes requiere revisar sus coordenadas. Los rasgos de las referencias se mezclan con el sombreado de la base; no se promete identidad de píxeles entre las imágenes generadas.

### Estado y compatibilidad

`AvatarConfig` incorpora `eyes`, `nose` y `mouth`, serializados por nombre. `copyWith` centraliza las copias para que ningún cambio de color, peinado, personaje o movimiento borre los rasgos. Campos ausentes o desconocidos vuelven a Original. El editor conserva su flujo de borrador, guardar, descartar y restablecer; la preferencia local existente incluye los tres campos nuevos. La persistencia no se migra a cuentas en esta entrega.

### Verificación

Las doce pruebas de `avatar_test.dart`, `avatar_hairstyles_test.dart` y `avatar_face_test.dart` pasan. Las nuevas pruebas verifican recuperación de preferencias, valores antiguos/desconocidos, independencia de las zonas al cambiar cada rasgo en ambos personajes, selectores en 320 píxeles de ancho y renderizado de combinaciones. Se revisó `build/avatar-faces-preview.png`: Original, conjunto A, conjunto B y mezcla con piel oscura/cabello plateado, para ambos personajes con peinado recogido. Las pruebas de zonas usan el peinado rizado; no representan una inspección visual exhaustiva de todas las combinaciones posibles.

Formato y análisis de los archivos modificados sin incidencias. No se ejecutó la aplicación en el emulador del usuario. Para cargar los recursos y el shader actualizado, detener y volver a ejecutar `flutter run`; abrir **Avatar → Rostro** y guardar los cambios.

## 2026-11-09 — Peinados seleccionables

El usuario solicitó crear variedad de peinados y poder seleccionarlos. Se implementan **Original, Corto, Rizado y Recogido** para los dos personajes existentes. Los tres estilos nuevos son una selección inicial de implementación; el catálogo puede ampliarse.

### Recursos y alcance

- Se generaron seis PNG nuevos con la herramienta integrada de imágenes, usando cada personaje original como referencia de edición. Todos conservan lienzo de 887 × 1774 y transparencia. Los originales no se sobrescribieron.
- Archivos: `my_daily_routine/lib/assets/avatar/hairstyles/{hombre,mujer}_{corto,rizado,recogido}.png`. Esta carpeta se declara explícitamente en `pubspec.yaml`.
- Se usan variantes completas para evitar superponer cabello nuevo sobre cabello que ya está dibujado en el PNG. No hay aún una base sin cabello ni capas de cabello independientes. Puede haber pequeñas diferencias de dibujo entre variantes generadas; la pose, vestuario y encuadre se mantienen visualmente consistentes.
- Las paletas y el movimiento suave existentes se reutilizan. Se conserva el tamaño y la ubicación aprobados en inicio. La generación se hizo durante el desarrollo; no se conectó la aplicación a una API.
- Los prompts exactos y la correspondencia con cada archivo están en `avatar-peinados-prompts.md`.

### Selección, carga y persistencia

- **Tu avatar → Peinado** presenta tarjetas con miniaturas, nombre y marca de selección. Las tarjetas se reorganizan con `Wrap` en pantallas estrechas.
- `AvatarConfig.hairstyle` es un enum serializado por nombre, independiente del color de cabello. Los métodos de cambio de color, personaje y movimiento preservan el peinado.
- Configuraciones antiguas sin `hairstyle` y valores desconocidos usan `original`. Se mantiene la clave de preferencias existente y se añade el campo de forma compatible.
- La caché de imágenes se identifica por personaje y peinado para evitar reutilizar la ilustración incorrecta. Cada vista conserva su instancia del shader; se repinta también si cambia la imagen.
- El editor precarga el recurso seleccionado antes de aplicar el borrador; muestra progreso y evita guardar durante la carga. Ante un fallo conserva el borrador previo y permite intentarlo de nuevo.
- Guardar aplica y persiste la selección; volver la descarta. Restablecer prepara el personaje y peinado originales en el borrador. El mecanismo local de persistencia existente no cambia en esta entrega.

### Validación

- Ocho pruebas pasan al ejecutar `flutter test --no-pub test/avatar_test.dart test/avatar_hairstyles_test.dart`.
- Cobertura: migración de preferencias anteriores/desconocidas, guardado y recuperación del peinado con los colores, conservarlo al cambiar personaje, selección/descartar/guardar en el editor, carga de las ocho combinaciones de personaje y peinado, transparencia y recoloración del cabello sin afectar muestras de ojos y camiseta, y disposición del selector en 320 píxeles de ancho.
- Se revisaron visualmente los seis recursos generados y la captura de pruebas `build/hairstyles-selector.png`. La captura usa la tipografía de pruebas de Flutter; sirve para comprobar las miniaturas y la distribución, no la tipografía final.
- Formato y análisis de los archivos Dart modificados sin incidencias. No se ejecutó la aplicación en el emulador del usuario.

Para probar: detener y volver a ejecutar `flutter run` para incluir la nueva carpeta de recursos; abrir **Avatar**, elegir personaje y peinado y pulsar **Guardar cambios**.

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
# 2026-11-13 — Apariencia persistida por cuenta

El usuario pidió guardar rasgos y personalización en MySQL. Las cuentas reales
cargan y guardan el catálogo completo mediante `/usuarios/me/avatar`, identificado
por JWT. La cuenta de práctica conserva preferencias locales. La apariencia
anterior global del dispositivo no se asigna automáticamente a ninguna cuenta;
cada usuario guarda su selección. Las expresiones siguen derivadas de estadísticas.
Detalles y pruebas en [perfil](../backend/docs/perfil.md). No se modificaron PNG,
colores, proporciones aprobadas ni el catálogo de estilos.
