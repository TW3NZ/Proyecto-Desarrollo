# My Daily Routine

Aplicación móvil Flutter para organizar tareas, seguir su cumplimiento y consultar estadísticas. Incluye flujos locales y un servicio FastAPI para sugerir atributos del avatar desde una foto. Todavía no hay persistencia general de cuentas y tareas.

**Versión del paquete:** `0.1.0+1`

**Aplicación:** Flutter / Dart

**Tecnologías del repositorio:** Dart, Flutter y Python

## Credenciales de prueba: ingresar sin registrarse

En la pantalla de inicio de sesión escribe:

| Campo | Valor |
| --- | --- |
| Correo o nombre de usuario | `admin` |
| Contraseña | `12345678` |

También puedes usar `admin@mydailyroutine.local` como identificador, con la misma contraseña. Pulsa **Iniciar sesión** para entrar directamente a la pantalla principal.

Esta cuenta local de práctica ya viene incluida y está disponible cada vez que se inicia la aplicación, incluso después de cerrarla o reiniciarla. No requiere registro previo ni conexión a un servidor. Es una cuenta de desarrollo, no una cuenta de producción.

El acceso fijo no guarda las tareas o estadísticas entre reinicios: esos datos siguen en memoria. Las cuentas creadas manualmente durante el registro también se pierden cuando se reinicia el proceso.

## Funciones actuales

- **Inicio de sesión y registro:** pantalla con la cabecera ilustrada de referencia y acceso con correo o nombre de usuario y contraseña. Incluye una cuenta local de práctica: `admin` / `12345678`. Las cuentas creadas durante el registro solo existen mientras la aplicación sigue en ejecución.
- **Inicio:** muestra el avatar, alterna cuatro fondos, presenta estadísticas y permite acceder a tareas, personalización del avatar y Teams. Incluye cierre de sesión hacia el login.
- **Tareas:** permite crear tareas con categoría, prioridad, descripción y fecha de finalización opcional. Las tarjetas muestran la fecha cuando se asigna y la resaltan si ya pasó y la tarea sigue pendiente.
- **Estadísticas e historial:** completar tareas suma puntos a las categorías asociadas según su prioridad; el resumen muestra progreso y conteos por fecha de creación (hoy, semana y mes).
- **Avatar:** permite elegir entre los personajes Hombre y Mujer, cambiar los colores de piel, cabello, camiseta y pantalón, y ajustar el movimiento suave. La configuración se guarda localmente en el dispositivo.
- **Teams:** permite crear equipos y revisar los equipos de la sesión actual. La sección incluye un espacio vacío para el ID del usuario; todavía no se genera ni se asigna uno.
- **Widget de tareas para Android:** muestra tareas y progreso; tocar una tarea abre la app para actualizar su estado. La configuración y el uso se describen en [my_daily_routine/README.md](my_daily_routine/README.md).

## Límites actuales

- Las cuentas, tareas, estadísticas y equipos se guardan en memoria. Se pierden cuando el proceso de la app se reinicia. La configuración del avatar sí se conserva localmente mediante `shared_preferences`.
- No hay autenticación remota, recuperación de contraseña funcional ni acceso con Google o Apple.
- La selección actual del avatar cambia colores sobre ilustraciones completas. Todavía no hay prendas intercambiables por capas, cambios de silueta de ropa ni evolución visual conectada a las estadísticas.
- La fecha de finalización de una tarea puede asignarse al crearla; aún no se puede editar después.
- La opción **Unirse a team** y la asignación de ID de usuario están pendientes.
- El análisis de fotos requiere configurar y ejecutar el servicio de OpenAI; no se activa solo por instalar la app. Consulta [la guía de configuración](docs/avatar-foto.md).

### Propuesta para futuras prendas

Se propone preparar una base del personaje que permanezca cubierta por una prenda opaca neutra y dibujar la ropa elegida en capas transparentes alineadas al mismo lienzo. El avatar no se mostraría sin ropa. Esta propuesta todavía debe definirse y no está implementada; el primer paso recomendado es revisar un concepto de camiseta y pantalón antes de integrar un sistema de capas.

## Ejecutar el proyecto

Desde la carpeta Flutter:

```bash
cd my_daily_routine
flutter pub get
flutter run
```

El widget nativo está disponible solo en Android. Para incluir imágenes de las subcarpetas, `pubspec.yaml` declara cada carpeta de recursos explícitamente.

## Estructura principal

- `my_daily_routine/lib/screens/`: pantallas.
- `my_daily_routine/lib/widgets/`: componentes reutilizables.
- `my_daily_routine/lib/models/`: modelos de datos.
- `my_daily_routine/lib/data/`: almacenes locales y temporales.
- `my_daily_routine/lib/assets/`: avatares, fondos, iconos y otros recursos.
- `my_daily_routine/shaders/`: shader de colores del avatar.
- `docs/`: decisiones y límites del proyecto.

## Documentación

- [Reglas del repositorio](AGENTS.md)
- [Decisiones y estado del avatar](docs/decisiones-avatar.md)
- [Decisiones sobre tareas](docs/decisiones-tareas.md)
- [Decisiones sobre sesión](docs/decisiones-sesion.md)
- [Decisiones sobre Teams](docs/decisiones-teams.md)
- [Decisiones del widget Android](docs/decisiones-widget-tareas.md)
- [Prompts del concepto visual del avatar](docs/avatar-prompts.md)
