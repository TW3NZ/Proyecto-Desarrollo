import 'package:flutter/material.dart';

import '../../models/avatar_config.dart';
import 'avatar_color_picker.dart';

class AvatarPaletteSection extends StatelessWidget {
  final AvatarPart part;
  final String selectedId;
  final ValueChanged<String> onSelected;

  const AvatarPaletteSection({
    super.key,
    required this.part,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final title = switch (part) {
      AvatarPart.skin => 'Tono de piel',
      AvatarPart.hair => 'Color de cabello',
      AvatarPart.shirt => 'Camiseta',
      AvatarPart.trousers => 'Pantalón',
    };

    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in avatarPalettes[part]!)
                ChoiceChip(
                  label: Text(option.label),
                  avatar: CircleAvatar(
                    backgroundColor: option.color,
                    radius: 10,
                  ),
                  selected: selectedId == option.id,
                  onSelected: (_) => onSelected(option.id),
                ),
            ],
          ),
          if (part == AvatarPart.shirt || part == AvatarPart.trousers)
            AvatarCustomColors(
              selected: selectedId,
              initial: const AvatarConfig()
                  .withColor(part, selectedId)
                  .option(part)
                  .color,
              onSelected: onSelected,
            ),
        ],
      ),
    );
  }
}
