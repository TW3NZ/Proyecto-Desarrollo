import 'package:flutter/material.dart';

import '../../theme.dart';

class ResumenPeriodo extends StatelessWidget {
  final String titulo;
  final int cantidad;
  final IconData icono;

  const ResumenPeriodo({
    super.key,
    required this.titulo,
    required this.cantidad,
    required this.icono,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: AppColors.fieldBorder,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icono,
            color: AppColors.primary,
            size: 22,
          ),

          const SizedBox(height: 7),

          Text(
            '$cantidad',
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            titulo,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}