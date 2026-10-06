import 'package:flutter/material.dart';
import '../../theme.dart';

/// Tarjeta blanca con una acción principal de la pantalla Teams
/// ("Crear team", "Unirse a team"): círculo azul con ícono a la izquierda,
/// título y descripción, y un botoncito redondo a la derecha.
class TarjetaAccionTeam extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String descripcion;

  /// Ícono del botoncito de la derecha (por ejemplo "+" o una llave).
  final IconData iconoAccion;
  final Color colorIconoAccion;
  final VoidCallback? alTocar;

  const TarjetaAccionTeam({
    super.key,
    required this.icono,
    required this.titulo,
    required this.descripcion,
    required this.iconoAccion,
    this.colorIconoAccion = AppColors.primary,
    this.alTocar,
  });

  @override
  Widget build(BuildContext context) {
    final radio = BorderRadius.circular(26);

    return Container(
      decoration: BoxDecoration(
        borderRadius: radio,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: radio,
        child: InkWell(
          borderRadius: radio,
          onTap: alTocar,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppGradients.logo,
                  ),
                  child: Icon(icono, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        titulo,
                        style: const TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        descripcion,
                        style: const TextStyle(
                          color: Color(0xFF4A66C8),
                          fontSize: 14,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFE6ECFB),
                  ),
                  child: Icon(iconoAccion, color: colorIconoAccion, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
