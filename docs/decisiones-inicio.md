# Decisiones sobre la pantalla de inicio

## 2026-11-12 — Quinto fondo de inicio

A petición del usuario, se incorpora `background5.png` a la rotación de fondos de la pantalla principal. Se añadió a `AppAssets.homeBackgrounds`; `pubspec.yaml` ya declara la carpeta `lib/assets/background/`, por lo que el nuevo asset queda empaquetado. El botón «Cambiar fondo» rota ahora por cinco fondos. Se conservan el encuadre (`BoxFit.cover`) y la transición suave existentes para mantener la coherencia visual.

## 2026-11-05 — Reubicar el acceso a Avatar

A petición del usuario, se elimina el botón de regalo de la columna izquierda y se coloca en ese espacio el botón Avatar, que antes estaba al final de la columna. Avatar queda con una sola ubicación y conserva su navegación a la pantalla de personalización.
