import 'package:flutter/material.dart';

import '../data/tareas_store.dart';
import '../theme.dart';
import '../widgets/common/cabecera_app.dart';
import '../widgets/tareas/barra_progreso_tareas.dart';
import '../widgets/tareas/resumen_periodo.dart';
import '../widgets/tareas/tarjeta_tarea.dart';

class TareaScreen extends StatelessWidget {
  const TareaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            CabeceraApp(
              titulo: 'Resumen de tareas',
              alVolver: () => Navigator.maybePop(context),
            ),
            const Expanded(
              child: _ResumenContenido(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumenContenido extends StatelessWidget {
  const _ResumenContenido();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: TareasStore.instancia,
      builder: (context, _) {
        final tareas = TareasStore.instancia.tareas;
        final ahora = DateTime.now();

        final tareasHoy = tareas
            .where((tarea) => _esHoy(tarea.fecha, ahora))
            .toList();

        final tareasSemana = tareas
            .where((tarea) => _esEstaSemana(tarea.fecha, ahora))
            .toList();

        final tareasMes = tareas
            .where((tarea) => _esEsteMes(tarea.fecha, ahora))
            .toList();

        final completadas = tareas
            .where((tarea) => tarea.completada)
            .length;

        final progreso = tareas.isEmpty
            ? 0.0
            : completadas / tareas.length;

        return ListView(
          padding: const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            28,
          ),
          children: [
            BarraProgresoTareas(
              completadas: completadas,
              total: tareas.length,
              progreso: progreso,
            ),

            const SizedBox(height: 22),

            const Text(
              'Tareas',
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: ResumenPeriodo(
                    titulo: 'Hoy',
                    cantidad: tareasHoy.length,
                    icono: Icons.today_rounded,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: ResumenPeriodo(
                    titulo: 'Semana',
                    cantidad: tareasSemana.length,
                    icono: Icons.date_range_rounded,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: ResumenPeriodo(
                    titulo: 'Mes',
                    cantidad: tareasMes.length,
                    icono: Icons.calendar_month_rounded,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 26),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Todas las tareas',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                Text(
                  '${tareas.length}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            if (tareas.isEmpty)
              const _SinTareas()
            else
              ...tareas.map(
                (tarea) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TarjetaTarea(
                    tarea: tarea,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SinTareas extends StatelessWidget {
  const _SinTareas();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 30,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.fieldBorder,
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.task_alt_rounded,
            color: AppColors.textHint,
            size: 42,
          ),

          SizedBox(height: 10),

          Text(
            'Todavía no tienes tareas',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),

          SizedBox(height: 4),

          Text(
            'Añade una tarea para verla aquí.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

bool _esHoy(
  DateTime fecha,
  DateTime ahora,
) {
  return fecha.year == ahora.year &&
      fecha.month == ahora.month &&
      fecha.day == ahora.day;
}

bool _esEstaSemana(
  DateTime fecha,
  DateTime ahora,
) {
  final inicioSemana = DateTime(
    ahora.year,
    ahora.month,
    ahora.day,
  ).subtract(
    Duration(days: ahora.weekday - 1),
  );

  final finSemana = inicioSemana.add(
    const Duration(days: 7),
  );

  return !fecha.isBefore(inicioSemana) &&
      fecha.isBefore(finSemana);
}

bool _esEsteMes(
  DateTime fecha,
  DateTime ahora,
) {
  return fecha.year == ahora.year &&
      fecha.month == ahora.month;
}