import 'package:flutter/material.dart';
import '../../theme.dart';

// Todo lo "redondo" del Home vive aquí porque comparte el mismo estilo:
//   AssetOrIcon      -> imagen por ruta o ícono de respaldo
//   GlassCircle      -> círculo azul base (borde claro + sombra)
//   CircleMenuButton -> botón con ícono y etiqueta
//   StatBubble       -> burbuja con título, valor y barra de progreso

/// Muestra la imagen de [asset] si hay ruta; si no (o si falla al cargar),
/// muestra un ícono de Material de respaldo.
class AssetOrIcon extends StatelessWidget {
  final String? asset;
  final IconData icon;
  final double size;
  final Color color;

  const AssetOrIcon({
    super.key,
    required this.icon,
    required this.size,
    this.asset,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = Icon(icon, size: size, color: color);
    if (asset == null) return fallback;
    return Image.asset(
      asset!,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}

/// Círculo azul con borde claro y sombra: base de los botones redondos.
class GlassCircle extends StatelessWidget {
  final double size;
  final Widget child;
  final VoidCallback? onTap;
  final bool glow;
  final double borderWidth;

  const GlassCircle({
    super.key,
    required this.size,
    required this.child,
    this.onTap,
    this.glow = false,
    this.borderWidth = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppGradients.logo,
        border: Border.all(
          color: Colors.white.withOpacity(0.6),
          width: borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withOpacity(0.45),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
          if (glow)
            BoxShadow(
              color: Colors.white.withOpacity(0.35),
              blurRadius: 22,
              spreadRadius: 4,
            ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Center(child: child),
        ),
      ),
    );
  }
}

/// Botón redondo del Home (Tareas Diarias, Objetivos, Regalo, Personalizar,
/// notificaciones, cambiar fondo...). Ícono arriba y etiqueta opcional abajo.
class CircleMenuButton extends StatelessWidget {
  final String? label;
  final IconData icon;

  /// Ruta de la imagen del ícono. Si es null se usa [icon].
  final String? iconAsset;
  final double size;
  final VoidCallback? onTap;

  const CircleMenuButton({
    super.key,
    required this.icon,
    this.label,
    this.iconAsset,
    this.size = 72,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasLabel = label != null;

    return GlassCircle(
      size: size,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AssetOrIcon(
                asset: iconAsset,
                icon: icon,
                size: hasLabel ? size * 0.36 : size * 0.5,
              ),
              if (hasLabel) ...[
                const SizedBox(height: 2),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: size * 0.8),
                  child: Text(
                    label!,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: (size * 0.15).clamp(9.0, 12.0),
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Burbuja de estadística (Nivel de aura, Inteligencia, Tareas realizadas):
/// ícono, título, valor y barra de progreso opcional.
class StatBubble extends StatelessWidget {
  final String title;
  final String value;

  /// Progreso de 0.0 a 1.0. Si es null no se dibuja la barra.
  final double? progress;
  final IconData icon;

  /// Ruta de la imagen del ícono. Si es null se usa [icon].
  final String? iconAsset;
  final double size;
  final VoidCallback? onTap;

  const StatBubble({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.progress,
    this.iconAsset,
    this.size = 90,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCircle(
      size: size,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AssetOrIcon(asset: iconAsset, icon: icon, size: size * 0.26),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (progress != null) ...[
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: SizedBox(
                    width: size * 0.58,
                    height: 5,
                    child: LinearProgressIndicator(
                      value: progress!.clamp(0.0, 1.0),
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation(Color(0xFF8FE3FF)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
