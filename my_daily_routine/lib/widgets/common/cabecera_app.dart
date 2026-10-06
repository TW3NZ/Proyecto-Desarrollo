import 'package:flutter/material.dart';
import '../../theme.dart';
import '../home/round_buttons.dart';

/// Cabecera reutilizable para pantallas con título, botón de volver y acción opcional.
class CabeceraApp extends StatelessWidget {
  final String titulo;
  final VoidCallback? alVolver;
  final Widget? accionDerecha;

  const CabeceraApp({
    super.key,
    required this.titulo,
    this.alVolver,
    this.accionDerecha,
  });

  @override
  Widget build(BuildContext context) {
    final margenSuperior = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, margenSuperior + 12, 16, 20),
      decoration: BoxDecoration(
        gradient: AppGradients.logo,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(34)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          if (alVolver != null)
            GlassCircle(
              size: 46,
              onTap: alVolver,
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 24,
              ),
            )
          else
            const SizedBox(width: 46),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              titulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (accionDerecha != null) ...[
            const SizedBox(width: 12),
            accionDerecha!,
          ],
        ],
      ),
    );
  }
}
