import 'package:flutter/material.dart';

import '../../models/avatar_config.dart';
import 'avatar_character.dart';
import 'avatar_color_picker.dart';

class AvatarFaceSelector extends StatelessWidget {
  final AvatarConfig config;
  final ValueChanged<AvatarConfig> onChanged;
  const AvatarFaceSelector({
    super.key,
    required this.config,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Rostro',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
      Container(
        height: 210,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFE3EAFF),
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.antiAlias,
        child: OverflowBox(
          alignment: Alignment.topCenter,
          minWidth: 480,
          maxWidth: 480,
          minHeight: 960,
          maxHeight: 960,
          child: AvatarCharacter(config: config, portrait: true),
        ),
      ),
      _options('Ojos', [
        for (final value in AvatarEyes.values)
          ChoiceChip(
            key: ValueKey('eyes-${value.name}'),
            label: Text(value.label),
            selected: config.eyes == value,
            onSelected: (_) => onChanged(config.copyWith(eyes: value)),
          ),
      ]),
      const SizedBox(height: 16),
      const Text(
        'Color de ojos',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      AvatarCustomColors(
        selected: config.eyeColor,
        initial: AvatarConfig.isCustomColor(config.eyeColor)
            ? AvatarConfig.customColor(config.eyeColor)
            : const Color(0xFF62402A),
        onSelected: (value) => onChanged(config.copyWith(eyeColor: value)),
      ),
      TextButton(
        onPressed: () => onChanged(config.copyWith(eyeColor: 'original')),
        child: const Text('Color de ojos original'),
      ),
      _options('Nariz', [
        for (final value in AvatarNose.values)
          ChoiceChip(
            key: ValueKey('nose-${value.name}'),
            label: Text(value.label),
            selected: config.nose == value,
            onSelected: (_) => onChanged(config.copyWith(nose: value)),
          ),
      ]),
      _options('Boca', [
        for (final value in AvatarMouth.values)
          ChoiceChip(
            key: ValueKey('mouth-${value.name}'),
            label: Text(value.label),
            selected: config.mouth == value,
            onSelected: (_) => onChanged(config.copyWith(mouth: value)),
          ),
      ]),
    ],
  );

  Widget _options(String label, List<Widget> children) => Padding(
    padding: const EdgeInsets.only(top: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Wrap(spacing: 8, runSpacing: 8, children: children),
      ],
    ),
  );
}
