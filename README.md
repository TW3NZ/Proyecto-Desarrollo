[Descargar APK de prueba para Android ARM64](https://github.com/TW3NZ/Proyecto-Desarrollo/raw/refs/heads/master/my-daily-rutine-android-arm64.apk) · [Cómo compilar el APK](scripts/README.md)

# My Daily Routine — v1.0

**Proyecto de desarrollo de software desarrollado por Miguel Rodríguez y Levis Ortiz.**

My Daily Routine es una aplicación móvil para organizar tareas personales y de equipo, medir su cumplimiento y reflejar el progreso en un avatar personalizable. Busca resolver un problema cotidiano: los pendientes, las fechas límite y el trabajo compartido suelen quedar dispersos y sin una retroalimentación clara. La aplicación reúne tareas, estadísticas por categoría, equipos con proyectos y un avatar que reacciona al avance de la cuenta.

> El APK incluido corresponde a la versión `1.0.0+4`, compilada para Android ARM64 con la firma original de la compilación 2. El enlace se actualiza al publicar el APK y `app-update.json` juntos. La compilación 3 usa otra firma; consulta [compatibilidad de actualizaciones](docs/actualizaciones-android.md).

---

## Funcionalidades actuales

### Cuentas y sesión
- Registro con nombre, apellido, nombre de usuario, correo, contraseña y género; la fecha de creación la asigna la app y la contraseña se guarda con hash Argon2 en el servidor.
- Inicio de sesión con correo o nombre de usuario. El backend entrega un JWT que la app guarda en almacenamiento seguro y reutiliza al abrirse.
- Cierre de sesión, restauración de la sesión guardada y limpieza automática si el token vence o no coincide con el perfil.
- Tutorial breve después del primer registro.
- No se ofrece una cuenta de demostración: cada persona crea su propia cuenta contra el backend.

### Tareas
- Creación de tareas personales con título, categoría, prioridad, descripción y fecha límite opcional.
- Cuatro categorías fijas: Educación, Finanzas, Salud y Disciplina.
- Tarjetas con la fecha límite resaltada cuando ya pasó y la tarea sigue pendiente.
- Para cuentas reales, completar una tarea pide confirmación y no se puede deshacer; no hay edición ni borrado de tareas.

### Estadísticas
- Cuatro valores por cuenta —inteligencia, finanzas, salud y disciplina— que empiezan en 100 y se limitan entre 0 y 100.
- Completar una tarea recupera puntos según su prioridad y el número de tareas pendientes; cuantas menos pendientes, mayor recuperación.
- Las tareas vencidas penalizan una sola vez (8, 10 o 12 puntos según prioridad). Las tareas sin fecha no penalizan.
- Historial de tareas completadas y resumen de progreso por categoría.

### Avatar
- Dos personajes (Hombre y Mujer) con cuatro peinados, ojos, nariz y boca seleccionables de forma independiente.
- Colores para piel, cabello, camiseta y pantalón, incluido color RGB personalizado para la ropa; las cejas siguen el color del cabello.
- Deslizantes de complexión y altura, preferencia de movimiento y expresión derivada del progreso (cansancio, aburrimiento, tranquilidad o alegría).
- La apariencia se guarda por cuenta en MySQL y se conserva al cambiar de personaje o de atributos.
- **Crear desde una foto:** la imagen se envía solo tras una autorización explícita, OpenAI propone atributos del catálogo existente y la persona revisa y edita la propuesta antes de guardarla. El servidor no almacena las fotos.

### Equipos y proyectos
- Creación de equipos e ingreso mediante un código alfanumérico de 8 caracteres en mayúsculas.
- Cada equipo tiene proyectos; los equipos nuevos incluyen un proyecto General y el líder puede crear otros.
- El líder asigna tareas a varios miembros del mismo equipo. Cada asignado marca su parte con confirmación y la tarea se completa cuando todos terminan.
- Cada asignado recibe los puntos completos de la tarea, sin dividirlos entre personas.
- Actualización manual al entrar o deslizar hacia abajo; no hay notificaciones ni sincronización en tiempo real.

### Widget de Android
- Muestra pendientes, porcentaje completado, barra de progreso y una lista desplazable con la prioridad de cada tarea.
- Tocar una fila abre la aplicación. La lista se actualiza con la instantánea de lectura que publica la app.

### Actualizaciones en Android
- En compilaciones release de Android, la app consulta si hay un APK nuevo publicado en el repositorio y ofrece descargarlo.
- La descarga verifica tamaño, SHA-256, paquete, versión y firma; la instalación siempre la confirma Android y nunca es silenciosa.

---

## Arquitectura

```text
Flutter (Android / iOS)
   │  HTTPS + JWT
   ▼
FastAPI en Render  ──────►  MySQL en Aiven
   │
   └──────────────►  OpenAI (propuesta de avatar desde una foto)
```

| Componente | Ubicación | Responsabilidad |
| --- | --- | --- |
| App Flutter | `my_daily_routine/` | Pantallas, estado en memoria, almacenamiento seguro del JWT y widget Android |
| Widget y actualizador | `my_daily_routine/android/` | Widget nativo Kotlin (HomeWidget) y descarga/instalación del APK |
| API FastAPI | `backend/app.py` | Registro, login, tareas, estadísticas, equipos, perfil del avatar y servicio de fotos |
| Seguridad | `backend/core/` | Hash Argon2 y verificación del JWT |
| Modelos | `backend/models/` | Validación con Pydantic |
| Acceso a datos | `backend/database/` | Consultas MySQL con TLS y consultas del panel administrativo |
| Base de datos | `database/` | Esquema SQL y migraciones |
| Panel administrativo | `backend/admin/` | Consulta de tablas y relaciones para administración |
| Pruebas | `backend/test/`, `my_daily_routine/test/` | Pruebas de API y de la app |
| Documentación | `docs/`, `backend/docs/` | Decisiones del proyecto y contratos de la API |
| Compilación | `scripts/` | Generación del APK y del manifiesto de actualización |

El backend es un único servicio FastAPI. Las rutas protegidas obtienen el `idUsu` exclusivamente del JWT (`sub`); nunca de un dato enviado por el cliente. MySQL guarda usuarios, tareas, estadísticas, eventos de puntuación, equipos, proyectos, participaciones y la apariencia del avatar.

---

## Tecnologías

- **Flutter / Dart** para la aplicación móvil.
- **FastAPI / Python 3.12+** para la API.
- **MySQL en Aiven** con TLS como base de datos.
- **JWT (HS256) y Argon2** para autenticación.
- **OpenAI Responses API** con salida estructurada para la propuesta de avatar desde una foto.
- **Kotlin** para el widget y el actualizador de Android.
- **Render** para el backend desplegado.
- **GitHub** para el repositorio y la distribución del APK.

La app se verificó con Flutter 3.47.2 y Dart 3.13.2.

---

## Requisitos

Para ejecutar la aplicación móvil:

- Flutter 3.x estable y Dart 3.x.
- Android Studio con Android SDK y un emulador o un teléfono con depuración USB.
- En macOS, Xcode si se desea ejecutar en el simulador de iOS.
- Git y conexión a Internet.

Para ejecutar el backend en local (alternativa de desarrollo):

- Python 3.12 o superior.
- Acceso a una base MySQL compatible (el proyecto usa Aiven) y, si se usa la función de fotos, una clave de OpenAI.

---

## Instalación y ejecución con el backend de Render

El backend de producción está en `https://my-daily-rutine.onrender.com`. La app se conecta a esa URL; no hace falta ejecutar nada en local.

### 1. Clonar e instalar dependencias

```bash
git clone https://github.com/TW3NZ/Proyecto-Desarrollo.git
cd Proyecto-Desarrollo/my_daily_routine
flutter pub get
```

### 2. Crear el archivo de configuración de Flutter

Crea `.tools/avatar-flutter.json` en la raíz del repositorio. La carpeta `.tools/` está ignorada por Git:

```json
{
  "API_URL": "https://my-daily-rutine.onrender.com",
  "AVATAR_API_URL": "https://my-daily-rutine.onrender.com"
}
```

- `API_URL` configura registro, login, tareas, estadísticas y equipos.
- `AVATAR_API_URL` configura el servicio de fotos del avatar.
- No se necesitan `AVATAR_API_TOKEN` ni claves de OpenAI: tras el login, la app usa el JWT de la cuenta. La clave de OpenAI permanece exclusivamente en el servidor.

Si ya existe el archivo, consérvalo. Cualquier cambio en estos valores requiere detener y volver a iniciar la app; el hot reload no los actualiza.

### 3. Ejecutar la app

**Desde VS Code:** abre la raíz del repositorio, ejecuta **Developer: Reload Window** y usa el perfil **My Daily Rutine - Avatar con fotos**. Los ajustes del workspace agregan el archivo de configuración automáticamente.

**Desde la terminal:**

```bash
cd my_daily_routine
flutter devices
flutter run --dart-define-from-file=../.tools/avatar-flutter.json -d ID_DEL_DISPOSITIVO
```

También se puede prescindir del archivo:

```bash
flutter run \
  --dart-define=API_URL=https://my-daily-rutine.onrender.com \
  --dart-define=AVATAR_API_URL=https://my-daily-rutine.onrender.com
```

### 4. Crear la cuenta e iniciar sesión

Registra una cuenta desde la pantalla **Crear usuario** y después inicia sesión. El registro escribe en MySQL a través de Render; no existe una cuenta de prueba incluida.

### 5. Comprobar la conexión

```bash
curl https://my-daily-rutine.onrender.com/health
```

Debe responder `{"status":"ok"}`. Si el servicio de Render estuvo inactivo, la primera petición puede tardar más que las siguientes; el login tiene un tiempo de espera de 15 segundos, así que conviene abrir `/health` antes de iniciar sesión.

---

## Documentación de la API

- **Swagger interactivo:** `https://my-daily-rutine.onrender.com/docs`
- **Esquema OpenAPI:** `https://my-daily-rutine.onrender.com/openapi.json`
- **Contratos y ejemplos en el repositorio:**
  - [Usuarios y login](backend/docs/usuarios.md)
  - [Tareas](backend/docs/tareas.md)
  - [Perfil, estadísticas y avatar](backend/docs/perfil.md)
  - [Equipos y proyectos](backend/docs/equipos.md)
  - [Panel administrativo](backend/docs/admin.md)
  - [Despliegue en Render](backend/docs/render.md)

---

## Versión 1.0

La versión 1.0 es la primera entrega oficial de My Daily Routine. Reúne las funcionalidades terminadas y disponibles en este repositorio; no incluye funciones futuras como prendas por capas, evolución permanente del avatar o notificaciones en tiempo real.

**Alcance funcional**

- Registro e inicio de sesión con JWT sobre un backend desplegado.
- Tareas personales y tareas de equipo con categorías, prioridad y fecha límite.
- Estadísticas por cuenta con recuperación y penalización documentadas en [decisiones de estadísticas](docs/decisiones-estadisticas.md).
- Avatar personalizable por piezas y colores, con expresiones automáticas y propuesta desde una foto.
- Equipos con código de invitación, proyectos, asignación múltiple y recompensas individuales completas.
- Widget de tareas para Android y actualización del APK desde la propia app.

**Características principales**

- Pantallas de inicio, tareas, estadísticas, avatar, equipos e historial, además de login, registro y tutorial.
- Persistencia real por cuenta en MySQL: tareas, estadísticas, eventos de puntuación y apariencia.
- Interfaz en español, con avatar protagonista y controles laterales en el inicio.

**Integración Flutter · FastAPI**

1. Flutter envía las credenciales a `POST /auth/login/user` o crea la cuenta con `POST /usuarios`.
2. FastAPI valida con Pydantic, consulta MySQL y devuelve un JWT.
3. Flutter guarda el JWT en almacenamiento seguro y lo envía como `Authorization: Bearer` en cada ruta protegida.
4. El backend obtiene el usuario del `sub` del token y aplica las reglas de negocio (puntuación, pertenencia a equipos, partes de tareas y avatar).
5. Las respuestas se reflejan en pantalla; la app no guarda una copia de las tareas reales más allá de la instantánea del widget.

**Conexión con Render**

- El backend se despliega como **Web Service** en Render y escucha sobre HTTPS.
- La app recibe las URLs del API mediante `--dart-define` en tiempo de compilación.
- La base de datos y la clave de OpenAI viven en las variables de entorno de Render, nunca en el teléfono.
- El servicio expone `/health` para comprobar disponibilidad y `/docs` para la documentación interactiva.

**Tecnologías de la versión**

Flutter y Dart, FastAPI y Python, MySQL en Aiven, JWT y Argon2, OpenAI Responses API, Kotlin para Android, Render y GitHub.

---

## Autores

**Desarrolladores:**
- Miguel Rodríguez
- Levis Ortiz

Ambos concibieron y desarrollaron el proyecto. Los créditos de la aplicación y de esta documentación corresponden a los dos.

---

## Límites conocidos

- Android e iOS son las únicas plataformas del proyecto; no hay compilación web ni de escritorio.
- El widget está disponible solo en Android y la distribución pública es ARM64.
- No hay recuperación de contraseña, acceso con Google o Apple, ni notificaciones.
- Las tareas no se pueden editar ni borrar después de crearlas, y la fecha límite solo se elige al crearlas.
- Una tarea completada no se puede desmarcar en una cuenta real.
- Los equipos no permiten expulsar miembros, transferir el liderazgo, rotar el código de invitación ni reabrir tareas; la actualización es manual.
- El avatar usa variantes completas, no un sistema de capas; no hay prendas intercambiables ni evolución permanente.
- El análisis de fotos depende de la cuota de OpenAI y del catálogo disponible; el parecido es aproximado.
- Las actualizaciones de Android se instalan manualmente y usan la clave de firma de prueba del proyecto, no una firma de Play Store.
- El panel administrativo es una herramienta de consulta para el equipo; no forma parte de la app móvil.

---

## Documentación del proyecto

- [Reglas del repositorio](AGENTS.md)
- [Integración de autenticación Flutter · FastAPI · MySQL](my_daily_routine/docs/INTEGRACION_API_AUTENTICACION.md)
- [Decisiones del avatar](docs/decisiones-avatar.md)
- [Decisiones de estadísticas](docs/decisiones-estadisticas.md)
- [Decisiones de tareas](docs/decisiones-tareas.md)
- [Decisiones de sesión](docs/decisiones-sesion.md)
- [Decisiones de Teams](docs/decisiones-teams.md)
- [Decisiones del widget Android](docs/decisiones-widget-tareas.md)
- [Actualizaciones Android](docs/actualizaciones-android.md)
- [Avatar desde una foto](docs/avatar-foto.md)
- [Backend: instalación y pruebas](backend/README.md)

**Licencia:** el repositorio aún no declara una licencia de uso.
