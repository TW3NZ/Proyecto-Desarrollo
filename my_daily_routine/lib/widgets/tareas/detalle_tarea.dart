import 'package:flutter/material.dart';
import '../../models/tarea_modelo.dart';
import '../../theme.dart';

void mostrarDetalleTarea(
  BuildContext context,
  NuevaTarea tarea,
) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(28),
      ),
    ),
    builder: (context) {
      final fecha = tarea.fecha;

      final fechaTexto =
          '${fecha.day.toString().padLeft(2, '0')}/'
          '${fecha.month.toString().padLeft(2, '0')}/'
          '${fecha.year}';

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            22,
            4,
            22,
            24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                tarea.titulo,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 18),

              _DetalleFila(
                icono: Icons.notes_rounded,
                titulo: 'Descripción',
                valor: tarea.descripcion.isEmpty
                    ? 'Sin descripción'
                    : tarea.descripcion,
              ),

              const SizedBox(height: 13),

              _DetalleFila(
                icono: Icons.calendar_today_rounded,
                titulo: 'Fecha',
                valor: fechaTexto,
              ),

              const SizedBox(height: 13),

              _DetalleFila(
                icono: Icons.flag_rounded,
                titulo: 'Prioridad',
                valor: tarea.prioridad.etiqueta,
              ),

              const SizedBox(height: 13),

              _DetalleFila(
                icono: Icons.folder_rounded,
                titulo: 'Categoría',
                valor: tarea.categorias.isEmpty
                    ? 'Sin categoría'
                    : tarea.categorias
                        .map(
                          (categoria) =>
                              categoria.etiqueta,
                        )
                        .join(', '),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _DetalleFila extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String valor;

  const _DetalleFila({
    required this.icono,
    required this.titulo,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Icon(
          icono,
          color: AppColors.primary,
          size: 21,
        ),

        const SizedBox(width: 11),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                valor,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}