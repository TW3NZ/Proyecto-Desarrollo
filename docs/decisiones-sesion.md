# Decisiones sobre sesión

## 2026-11-05 — Cerrar sesión desde inicio

El usuario pidió un control de cierre de sesión debajo de la cápsula motivacional, del mismo tamaño que el botón para cambiar el fondo. Se reutiliza `CircleMenuButton` con tamaño 44 y el icono de salida; al tocarlo, se elimina la ruta de inicio y se abre el login.

Alcance: navegación dentro de la autenticación local actual. No hay sesión remota ni credenciales persistentes que invalidar o limpiar.

## 2026-11-05 — Campo reservado para ID de usuario

A petición del usuario, `Usuario` incorpora el campo opcional `id`. Se deja nullable y sin generación automática para conservar compatibilidad con cuentas existentes y no presentar como persistente un identificador que todavía no se almacena en una base de datos.

## 2026-11-05 — Retirar accesos sociales del login

A petición del usuario, se quitaron del login el divisor «O CONTINÚA CON» y los botones de Google y Apple. La autenticación social no está implementada; el acceso disponible sigue siendo correo o nombre de usuario y contraseña.

## 2026-11-05 — Rediseño visual del login

El usuario pidió replicar la captura compartida. Se reorganiza el login con fondo azul pálido, formas suaves, ilustración del ave en la parte superior, marca de check, tarjeta blanca redondeada, campos amplios y botón degradado. Se conservan el acceso con usuario/correo y contraseña y el enlace para crear cuenta; el icono de ojo ahora alterna la visibilidad de la contraseña. El usuario añadió `lib/assets/recursos/cabecera_login.png`, que contiene la cabecera de la referencia; `AppAssets.cabeceraLogin` la muestra a ancho completo y el formulario continúa sobre un panel blanco. `icon_app.png` permanece sin cambios. Pendiente revisar el resultado en dispositivo para confirmar encuadre y desplazamiento con el teclado.
