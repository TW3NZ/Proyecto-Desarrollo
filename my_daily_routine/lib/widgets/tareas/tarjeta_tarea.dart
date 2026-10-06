import 'package:flutter/material.dart';

import '../../data/tareas_store.dart';
import '../../models/tarea_modelo.dart';
import '../../theme.dart';
import 'detalle_tarea.dart';

class TarjetaTarea extends StatelessWidget {
  final NuevaTarea tarea;

  const TarjetaTarea({
    super.key,
    required this.tarea,
  });

  @override
  Widget build(BuildContext context) {
    final colorPrioridad = switch (tarea.prioridad) {
      PrioridadTarea.alta =>
        const Color(0xFFE05252),
      PrioridadTarea.media =>
        const Color(0xFFE49A28),
      PrioridadTarea.baja =>
        const Color(0xFF4C9A72),
    };

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.fieldBorder,
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: tarea.completada,
            activeColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            onChanged: (_) {
              TareasStore.instancia
                  .alternarCompletada(tarea);
            },
          ),

          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                mostrarDetalleTarea(
                  context,
                  tarea,
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      tarea.titulo,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        color: tarea.completada
                            ? AppColors.textMuted
                            : AppColors.textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        decoration: tarea.completada
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Row(
                      children: [
                        Icon(
                          Icons.flag_rounded,
                          size: 15,
                          color: colorPrioridad,
                        ),

                        const SizedBox(width: 4),

                        Text(
                          tarea.prioridad.etiqueta,
                          style: TextStyle(
                            color: colorPrioridad,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        if (tarea.categorias.isNotEmpty) ...[
                          const SizedBox(width: 9),

                          const Icon(
                            Icons.folder_rounded,
                            size: 14,
                            color: AppColors.textHint,
                          ),

                          const SizedBox(width: 3),

                          Expanded(
                            child: Text(
                              tarea.categorias
                                  .map(
                                    (categoria) =>
                                        categoria.etiqueta,
                                  )
                                  .join(', '),
                              maxLines: 1,
                              overflow:
                                  TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          IconButton(
            tooltip: 'Ver información',
            icon: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
              size: 27,
            ),
            onPressed: () {
              mostrarDetalleTarea(
                context,
                tarea,
              );
            },
          ),
        ],
      ),
    );
  }
}