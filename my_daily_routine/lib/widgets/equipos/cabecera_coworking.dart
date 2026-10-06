import 'package:flutter/material.dart';
import '../../assets_paths.dart';
import '../../theme.dart';
import '../home/round_buttons.dart';

/// Barra azul redondeada de la pantalla Teams: flecha para volver, título
/// y campana de notificaciones con un puntito.
class CabeceraCoworking extends StatelessWidget {
  final String titulo;
  final VoidCallback? alVolver;
  final VoidCallback? alTocarNotificaciones;

  const CabeceraCoworking({
    super.key,
    this.titulo = 'Coworking',
    this.alVolver,
    this.alTocarNotificaciones,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 78,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            // Fondo con degradado
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: AppGradients.primary),
              ),
            ),

            // Círculo decorativo translúcido de la esquina superior derecha
            Positioned(
              top: -4,
              right: -34,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.14),
                ),
              ),
            ),

            // Contenido
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _BotonTranslucido(
                    alTocar: alVolver,
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _BotonTranslucido(
                    alTocar: alTocarNotificaciones,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const AssetOrIcon(
                          asset: AppAssets.iconNotificaciones,
                          icon: Icons.notifications_rounded,
                          size: 24,
                        ),
                        Positioned(
                          top: -1,
                          right: -2,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF7AA2FF),
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Círculo blanco translúcido que usan la flecha y la campana.
class _BotonTranslucido extends StatelessWidget {
  final Widget child;
  final VoidCallback? alTocar;

  const _BotonTranslucido({required this.child, this.alTocar});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.22),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: alTocar,
        child: SizedBox(
          width: 40,
          height: 50,
          child: Center(child: child),
        ),
      ),
    );
  }
}
