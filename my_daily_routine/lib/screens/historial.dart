import 'package:flutter/material.dart';

import '../assets_paths.dart';
import '../data/tareas_store.dart';
import '../routes.dart';
import '../theme.dart';
import '../widgets/common/cabecera_app.dart';
import '../widgets/home/round_buttons.dart';

class HistorialScreen extends StatelessWidget {
  const HistorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          CabeceraApp(
            titulo: 'Objetivos completados',
            alVolver: () => Navigator.maybePop(context),
          ),

          Expanded(
            child: AnimatedBuilder(
              animation: TareasStore.instancia,
              builder: (context, _) {
                final tareasCompletadas = TareasStore
                    .instancia
                    .tareas
                    .where((tarea) => tarea.completada)
                    .toList();

                return Stack(
                  children: [
                    if (tareasCompletadas.isEmpty)
                      const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.task_alt_rounded,
                              size: 52,
                              color: AppColors.textHint,
                            ),

                            SizedBox(height: 12),

                            Text(
                              'Aún no has completado tareas',
                              style: TextStyle(
                                color: AppColors.textDark,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),

                            SizedBox(height: 5),

                            Text(
                              'Las tareas que completes aparecerán aquí.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView(
                        padding: const EdgeInsets.fromLTRB(
                          20,
                          20,
                          20,
                          100,
                        ),
                        children: [
                          Text(
                            '${tareasCompletadas.length} '
                            '${tareasCompletadas.length == 1 ? 'tarea completada' : 'tareas completadas'}',
                            style: const TextStyle(
                              color: AppColors.textDark,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),

                          const SizedBox(height: 14),

                          ...tareasCompletadas.map(
                            (tarea) => _TareaCompletadaCard(
                              titulo: tarea.titulo,
                              descripcion: tarea.descripcion,
                              prioridad: tarea.prioridad.etiqueta,
                            ),
                          ),
                        ],
                      ),

                    Positioned(
                      right: 24,
                      bottom: 28,
                      child: AddTaskButton(
                        iconAsset: AppAssets.iconAnadirTarea,
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.add,
                        ),
                        label: '',
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TareaCompletadaCard extends StatelessWidget {
  final String titulo;
  final String descripcion;
  final String prioridad;

  const _TareaCompletadaCard({
    required this.titulo,
    required this.descripcion,
    required this.prioridad,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.fieldBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(
                alpha: 0.12,
              ),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),

                if (descripcion.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    descripcion,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],

                const SizedBox(height: 6),

                Text(
                  'Prioridad: $prioridad',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}