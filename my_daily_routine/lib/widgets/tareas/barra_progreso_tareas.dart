import 'package:flutter/material.dart';

import '../../theme.dart';

class BarraProgresoTareas extends StatelessWidget {
  final int completadas;
  final int total;
  final double progreso;

  const BarraProgresoTareas({
    super.key,
    required this.completadas,
    required this.total,
    required this.progreso,
  });

  @override
  Widget build(BuildContext context) {
    final porcentaje = (progreso * 100).round();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(
              alpha: 0.20,
            ),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progreso de tareas',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),

              Text(
                '$porcentaje%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            '$completadas de $total tareas completadas',
            style: TextStyle(
              color: Colors.white.withValues(
                alpha: 0.86,
              ),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 14),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progreso,
              minHeight: 11,
              backgroundColor:
                  Colors.white.withValues(alpha: 0.22),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(
                Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}