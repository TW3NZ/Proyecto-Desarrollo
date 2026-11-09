# Decisiones sobre identificadores

## 2026-11-09 — IDs enteros temporales hasta integrar FastAPI

El usuario pidió estandarizar los IDs de entidades y sus referencias como `int`, en preparación para MySQL, y confirmó que FastAPI generará los IDs definitivos. Mientras la app siga operando localmente, Flutter asigna IDs negativos con un contador monotónico central. El ID `-1` queda reservado para la cuenta de práctica; los demás IDs temporales comienzan en `-2` y decrecen, evitando colisiones aleatorias y separándose de los IDs definitivos positivos esperados del servidor.

Alcance: identidad de usuario, equipo, proyecto, miembro, tarea, actividad y estadísticas, incluidos los mapas que usan esos IDs como claves. Los IDs string de opciones visuales, como las paletas del avatar, no son claves de entidades y permanecen como `String`.

Pendiente: al integrar FastAPI, sustituir IDs temporales por los IDs devueltos por el servidor y persistir las entidades. No se implementaron SQL ni llamadas de red.
