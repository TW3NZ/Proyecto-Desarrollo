import 'package:flutter/material.dart';

import '../../models/avatar_config.dart';
import '../../theme.dart';

class AvatarBodyControls extends StatelessWidget {
  final AvatarConfig config;
  final ValueChanged<AvatarConfig> onChanged;
  static int _widthPercent(double value) =>
      ((value - AvatarConfig.minBodyWidth) /
              (AvatarConfig.maxBodyWidth - AvatarConfig.minBodyWidth) *
              100)
          .round();
  const AvatarBodyControls({
    super.key,
    required this.config,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.fieldBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Proporciones',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Ajusta tu silueta. La altura máxima mantiene el espacio del avatar en el inicio.',
          style: TextStyle(color: AppColors.textMuted),
        ),
        const SizedBox(height: 16),
        const Text('Complexión', style: TextStyle(fontWeight: FontWeight.w700)),
        Slider(
          key: const ValueKey('avatar-body-width'),
          value: AvatarConfig.validWidth(config.bodyWidth),
          min: AvatarConfig.minBodyWidth,
          max: AvatarConfig.maxBodyWidth,
          divisions: 70,
          activeColor: AppColors.primary,
          label: '${_widthPercent(AvatarConfig.validWidth(config.bodyWidth))}%',
          semanticFormatterCallback: (v) =>
              'Complexión: ${_widthPercent(v)} de 100',
          onChanged: (v) => onChanged(config.copyWith(bodyWidth: v)),
        ),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text('Más delgado'), Text('Más ancho')],
        ),
        const SizedBox(height: 16),
        const Text('Altura', style: TextStyle(fontWeight: FontWeight.w700)),
        Slider(
          key: const ValueKey('avatar-body-height'),
          value: AvatarConfig.validHeight(config.bodyHeight),
          min: 0.8,
          max: 1.0,
          divisions: 20,
          activeColor: AppColors.primary,
          label:
              '${((AvatarConfig.validHeight(config.bodyHeight) - 0.8) / 0.2 * 100).round()}%',
          semanticFormatterCallback: (v) =>
              'Altura: ${((v - 0.8) / 0.2 * 100).round()} de 100',
          onChanged: (v) => onChanged(config.copyWith(bodyHeight: v)),
        ),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text('Más bajo'), Text('Más alto')],
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () =>
              onChanged(config.copyWith(bodyWidth: 1, bodyHeight: 1)),
          child: const Text('Restablecer proporciones'),
        ),
      ],
    ),
  );
}
