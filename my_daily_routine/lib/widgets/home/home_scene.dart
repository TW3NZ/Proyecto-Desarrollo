import 'package:flutter/material.dart';

import '../../data/avatar_store.dart';
import '../../data/estadisticas_store.dart';
import '../../models/avatar_expression.dart';
import '../avatar/avatar_character.dart';

// La "escena" del Home: fondo + espacio del avatar.

/// Fondo a pantalla completa. Muestra la imagen número [index] de [paths] y
/// hace un fundido suave cuando cambia. Si la lista está vacía o la imagen no
/// carga, muestra un degradado azul de respaldo.
class HomeBackground extends StatelessWidget {
  final List<String> paths;
  final int index;

  const HomeBackground({super.key, required this.paths, required this.index});

  Widget _placeholder() => const DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF9DB8FF), Color(0xFF3F5FE0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    ),
    child: SizedBox.expand(),
  );

  @override
  Widget build(BuildContext context) {
    final Widget child = paths.isEmpty
        ? _placeholder()
        : Image.asset(
            paths[index % paths.length],
            key: ValueKey(index),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, _, _) => _placeholder(),
          );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      child: child,
    );
  }
}

/// Avatar con colores configurables y movimiento suave de reposo.
/// Mantiene el tamaño y la posición aprobados para la pantalla principal.
class AvatarSlot extends StatelessWidget {
  const AvatarSlot({super.key});

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final width = screen.width * 0.58;
    final height = screen.height * 0.58;

    return SizedBox(
      width: width,
      height: height,
      child: ListenableBuilder(
        listenable: Listenable.merge([
          AvatarStore.instancia,
          EstadisticasStore.instancia,
        ]),
        builder: (context, _) {
          final config = AvatarStore.instancia.config;
          final stats = EstadisticasStore.instancia.actual;
          final expression = AvatarExpression.fromProgress(
            stats.general,
            hasActiveStats:
                stats.inteligenciaActiva ||
                stats.finanzasActiva ||
                stats.saludActiva ||
                stats.disciplinaActiva,
          );
          return Tooltip(
            message:
                '${expression.label} · Progreso general ${stats.general.round()}/100',
            child: AvatarMotion(
              enabled: config.motion,
              child: AvatarCharacter(config: config, expression: expression),
            ),
          );
        },
      ),
    );
  }
}
