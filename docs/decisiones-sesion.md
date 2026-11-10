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
## 2026-11-09 — Credenciales visibles para acceso de práctica

El usuario pidió poder ingresar sin registrarse cada vez y encontrar las credenciales en el README. Se comprobó que `UsuariosStore` ya inicializa una cuenta fija (`admin`, contraseña `12345678`, correo alternativo `admin@mydailyroutine.local`, ID temporal -1). Se reutiliza esa cuenta y se documenta en ambos README, sin duplicar usuarios ni cambiar la autenticación existente. El acceso fijo no añade persistencia a cuentas registradas, tareas o estadísticas. La prueba existente `login_navigation_test.dart` verifica la navegación directa al inicio de la cuenta de práctica.

Verificación: las dos pruebas de navegación de login pasaron, incluido el acceso directo con la cuenta de práctica.
