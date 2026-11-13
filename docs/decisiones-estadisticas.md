# Decisiones sobre estadísticas

## 2026-11-13 — Persistencia remota por cuenta

Por solicitud del usuario, las cuentas reales recuperan estadísticas de MySQL.
El backend calcula y persiste puntos desde tareas personales completadas (5/10/15
según prioridad, repartidos entre categorías, límite 100). Recalcular y bloquear
la cuenta dentro de la transacción evita duplicación y recupera el historial.
Se mantienen fracciones con DECIMAL(8,4); las preferencias del aura se guardan en
PerfilUsuario. Es una elección de implementación que conserva la regla actual;
las recompensas colaborativas siguen pendientes. Véase el
[contrato de perfil](../backend/docs/perfil.md) para migración y limitaciones.

## 2026-11-09 — Estadísticas asociadas a cada usuario

El usuario pidió que cada conjunto de estadísticas pertenezca a una cuenta. `Estadisticas` se define en `my_daily_routine/lib/models/estadisticas.dart` y contiene `usuarioId`, los valores de Inteligencia, Finanzas, Salud y Disciplina, y las preferencias que determinan cuáles participan en el aura.

`EstadisticasStore` mantiene un conjunto independiente por ID de usuario. La autenticación local establece la cuenta actual y el cierre de sesión la limpia. Los valores siguen en memoria; no se implementó persistencia ni una tabla SQL.

Pendiente: persistir estos datos en la futura base de datos. La actualización de estadísticas al completar tareas de equipo no se incorpora en esta decisión; el flujo actual continúa procesando tareas personales.
