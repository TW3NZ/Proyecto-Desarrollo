import 'package:flutter/material.dart';
import '../../theme.dart';

/// Fila sobre la lista de teams: "TUS TEAMS ACTIVOS" a la izquierda y un
/// contador ("1 activo", "3 activos") a la derecha.
class EncabezadoTeamsActivos extends StatelessWidget {
  final int cantidad;

  const EncabezadoTeamsActivos({super.key, required this.cantidad});

  @override
  Widget build(BuildContext context) {
    final textoCantidad = cantidad == 1 ? '1 activo' : '$cantidad activos';

    return Row(
      children: [
        const Expanded(
          child: Text(
            'TUS TEAMS ACTIVOS',
            style: TextStyle(
              color: Color(0xFF4A66C8),
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFE6ECFB),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            textoCantidad,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
