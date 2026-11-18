# Decisiones sobre sesión

## 2026-11-05 — Cerrar sesión desde inicio

El usuario pidió un control de cierre de sesión debajo de la cápsula motivacional, del mismo tamaño que el botón para cambiar el fondo. Se reutiliza `CircleMenuButton` con tamaño 44 y el icono de salida; al tocarlo, se elimina la ruta de inicio y se abre el login.

Alcance: navegación dentro de la autenticación local actual. No hay sesión remota ni credenciales persistentes que invalidar o limpiar.

## 2026-11-05 — Campo reservado para ID de usuario (revisado el 2026-11-09)

A petición del usuario, `Usuario` incorpora un `id` obligatorio de tipo `int`. Hasta integrar FastAPI, la app asigna IDs negativos temporales en memoria; FastAPI generará los IDs estables definitivos. La decisión anterior de mantenerlo nullable quedó reemplazada el 2026-11-09 al preparar los modelos para una futura base de datos.

## 2026-11-05 — Retirar accesos sociales del login

A petición del usuario, se quitaron del login el divisor «O CONTINÚA CON» y los botones de Google y Apple. La autenticación social no está implementada; el acceso disponible sigue siendo correo o nombre de usuario y contraseña.

## 2026-11-05 — Rediseño visual del login

El usuario pidió replicar la captura compartida. Se reorganiza el login con fondo azul pálido, formas suaves, ilustración del ave en la parte superior, marca de check, tarjeta blanca redondeada, campos amplios y botón degradado. Se conservan el acceso con usuario/correo y contraseña y el enlace para crear cuenta; el icono de ojo ahora alterna la visibilidad de la contraseña. El usuario añadió `lib/assets/recursos/cabecera_login.png`, que contiene la cabecera de la referencia; `AppAssets.cabeceraLogin` la muestra a ancho completo y el formulario continúa sobre un panel blanco. `icon_app.png` permanece sin cambios. Pendiente revisar el resultado en dispositivo para confirmar encuadre y desplazamiento con el teclado.

## 2026-11-17 — Cuenta de práctica descontinuada para la versión 1.0

A petición del usuario, se retira por completo la cuenta de práctica que se usaba en desarrollo (`admin` con contraseña numérica de ocho dígitos) del código y de la documentación, antes de publicar la versión 1.0. El objetivo es que la entrega final no distribuya credenciales de prueba ni datos de una cuenta de demostración.

**Alcance:** se eliminaron las constantes y el usuario de demostración, la rama de login local y `UsuariosStore.autenticar`. El inicio de sesión usa únicamente `POST /auth/login/user` contra FastAPI. Se conserva `idUsuarioPractica = -1` como centinela de "sin sesión" para no modificar las comprobaciones `id <= 0` de las pantallas. No se modificaron el backend, la base de datos, las variables de entorno ni el sistema de autenticación.

**Efectos:** para probar la app hay que registrar una cuenta real contra el backend (Render o local). La interfaz heredada de equipos locales y el marcado de tareas desde el widget quedan sin uso, porque dependían de una sesión local sin cuenta. Las pruebas de navegación y de expresiones usan ahora una API simulada. Se actualizaron el README principal, las guías de ejecución y las reglas del repositorio.

## 2026-11-09 — Credenciales visibles para acceso de práctica (descontinuado)

El usuario pidió poder ingresar sin registrarse cada vez y encontrar las credenciales en el README. Se comprobó que `UsuariosStore` ya inicializaba una cuenta fija (`admin`, contraseña numérica de ocho dígitos, un correo alternativo de demostración, ID temporal -1). Se reutilizó esa cuenta y se documentó en ambos README, sin duplicar usuarios ni cambiar la autenticación existente. El acceso fijo no añadía persistencia a cuentas registradas, tareas o estadísticas. La prueba existente `login_navigation_test.dart` verificaba la navegación directa al inicio de la cuenta de práctica.

Verificación: las dos pruebas de navegación de login pasaron, incluido el acceso directo con la cuenta de práctica.

**Estado:** esta cuenta fue descontinuada y retirada en la versión 1.0. Véase la decisión del 2026-11-17.
