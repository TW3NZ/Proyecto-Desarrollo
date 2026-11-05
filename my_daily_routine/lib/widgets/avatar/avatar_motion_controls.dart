import 'package:flutter/material.dart';

class AvatarMotionControls extends StatelessWidget {
  final bool motionEnabled;
  final bool reducedMotion;
  final ValueChanged<bool> onMotionChanged;
  final VoidCallback onTryReaction;

  const AvatarMotionControls({
    super.key,
    required this.motionEnabled,
    required this.reducedMotion,
    required this.onMotionChanged,
    required this.onTryReaction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Movimiento suave'),
          subtitle: Text(
            reducedMotion
                ? 'Pausado por la opción de movimiento reducido del dispositivo.'
                : 'Un movimiento sutil de reposo.',
          ),
          value: motionEnabled,
          onChanged: onMotionChanged,
        ),
        OutlinedButton.icon(
          onPressed: motionEnabled && !reducedMotion ? onTryReaction : null,
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Probar reacción suave'),
        ),
      ],
    );
  }
}
