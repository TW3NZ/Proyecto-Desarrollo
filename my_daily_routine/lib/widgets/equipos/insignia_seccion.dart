import 'package:flutter/material.dart';
import '../../theme.dart';

/// Píldora blanca con ícono y texto corto (por ejemplo "Sección Teams").
class InsigniaSeccion extends StatelessWidget {
  final IconData icono;
  final String texto;

  const InsigniaSeccion({
    super.key,
    required this.icono,
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 18, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            texto,
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
