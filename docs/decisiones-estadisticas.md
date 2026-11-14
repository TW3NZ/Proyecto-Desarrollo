# Decisiones sobre estadísticas

## 2026-11-14 — Inicio en 100 y peso según pendientes

**Acuerdos del usuario:** todas las estadísticas de una cuenta nueva empiezan en
100; incumplir tareas debe bajarlas; completar una debe pesar más cuando hay pocas
pendientes. Confirmó que solo penalizan las tareas que superan su fecha límite;
sin fecha no hay penalización.

**Elecciones iniciales de implementación, ajustables:**

```text
Recuperación por categoría = 30 × W / (N × K)
Penalización por categoría = 10 × W / K
Nuevo valor = limitar(valor + recuperación − penalización, 0, 100)
```

- `W`: prioridad baja 0,8; media 1; alta 1,2.
- `N`: tareas personales pendientes del usuario justo antes de completar,
  incluida la tarea actual. Incluye las pendientes futuras y sin fecha; excluye
  completadas, tareas ajenas y de proyecto. Se guarda el N usado en el evento.
- `K`: número de categorías distintas de esa tarea. Educación suma inteligencia.
- Con prioridad media y una categoría: 1 pendiente → 30 puntos; 2 → 15;
  5 → 6; 10 → 3. En varias categorías se reparte esa cantidad.
- El incremento visible se limita al espacio disponible hasta 100. No se guardan
  puntos excedentes para compensar penalizaciones futuras.
- Penalización **una sola vez por tarea vencida**, no diaria ni por abrir la app:
  8/10/12 puntos totales según prioridad. Se reparte entre sus categorías.
- La fecha límite sigue vigente todo ese día, en horario de Colombia (UTC−5).
  Se considera vencida cuando `fechaFinalizacion < hoy`. No hay penalización
  durante el día límite, sin fecha ni por tareas que ya estaban completadas.
- Completar una tarea vencida primero aplica su penalización pendiente y después
  su recuperación. No elimina el historial del incumplimiento.

### Persistencia y compatibilidad

Se sustituye el recálculo histórico de la versión anterior por saldos y eventos
duraderos (`EventoPuntuacion`), con una clave única por tarea/tipo. La cuenta se
bloquea en una transacción antes de puntuar o crear tareas; completar y actualizar
estadísticas se confirman juntos. Reintentos y lecturas no duplican movimientos.
Los eventos guardan el cambio efectivo tras limitarlo entre 0 y 100 y versión 2.

Las cuentas existentes conservan sus saldos: no se reinician globalmente a 100.
Si falta una fila de estadísticas se inicializa en 100. Las tareas completadas
antes de esta versión no reciben una segunda recompensa. Las pendientes vencidas
existentes reciben su penalización única al sincronizar con la nueva versión.
La penalización se materializa al consultar estadísticas o completar una tarea,
no mediante un proceso diario independiente. Sin abrir la app, se aplicará en la
siguiente sincronización. La cuenta de práctica simula la regla en memoria.

La migración `002_puntuacion_dinamica.sql` ya se aplicó a Aiven y se verificó con
una transacción de prueba revertida. El código aún debe desplegarse en Render;
el APK publicado anteriormente no se recompiló durante este cambio. Las rutas y
la respuesta de estadísticas se conservan, por lo que las cuentas reales del APK
actual recibirán los nuevos valores cuando se actualice el backend.

Pendientes: decidir reparto colaborativo; ajustar los coeficientes tras probar el
equilibrio. No se implementó puntuación por equipos ni se cambiaron expresiones.

La sección de 2026-11-13 describe la versión anterior y queda sustituida en cuanto
a cálculo de puntuaciones por esta decisión.

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
