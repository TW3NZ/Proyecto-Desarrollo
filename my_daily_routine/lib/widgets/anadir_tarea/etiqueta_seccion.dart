import 'package:flutter/material.dart';
import '../../theme.dart';

/// Insignia circular con ícono + título de sección, con una nota opcional
/// al lado (por ejemplo "(opcional)").
class EtiquetaSeccion extends StatelessWidget {
  final IconData icono;
  final String texto;

  /// Texto pequeño junto al título, por ejemplo "(opcional)".
  final String? nota;

  const EtiquetaSeccion({
    super.key,
    required this.icono,
    required this.texto,
    this.nota,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppGradients.logo,
            border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icono, size: 19, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text.rich(
            TextSpan(
              text: texto,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
              children: [
                if (nota != null)
                  TextSpan(
                    text: '  $nota',
                    style: const TextStyle(
                      color: AppColors.textHint,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
