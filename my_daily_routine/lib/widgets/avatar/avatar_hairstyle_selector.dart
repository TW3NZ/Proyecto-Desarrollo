import 'package:flutter/material.dart';

import '../../models/avatar_config.dart';
import '../../theme.dart';
import 'avatar_character.dart';

class AvatarHairstyleSelector extends StatelessWidget {
  final AvatarConfig config;
  final ValueChanged<AvatarHairstyle> onSelected;

  const AvatarHairstyleSelector({
    super.key,
    required this.config,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Peinado',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final hairstyle in AvatarHairstyle.values)
            Semantics(
              selected: config.hairstyle == hairstyle,
              button: true,
              label: 'Peinado ${hairstyle.label}',
              child: SizedBox(
                width: 106,
                child: Material(
                  color: config.hairstyle == hairstyle
                      ? const Color(0xFFE3EAFF)
                      : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: config.hairstyle == hairstyle
                          ? AppColors.primary
                          : AppColors.fieldBorder,
                      width: config.hairstyle == hairstyle ? 2 : 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    key: ValueKey('hairstyle-${hairstyle.name}'),
                    onTap: () => onSelected(hairstyle),
                    child: ExcludeSemantics(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: 84,
                              width: 84,
                              child: ClipRect(
                                child: OverflowBox(
                                  alignment: Alignment.topCenter,
                                  minWidth: 168,
                                  maxWidth: 168,
                                  minHeight: 336,
                                  maxHeight: 336,
                                  child: Image.asset(
                                    AvatarResources.assetFor(
                                      config.characterType,
                                      hairstyle,
                                    ),
                                    fit: BoxFit.contain,
                                    excludeFromSemantics: true,
                                    errorBuilder: (_, _, _) => const Icon(
                                      Icons.person_outline,
                                      size: 64,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              hairstyle.label,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Icon(
                              config.hairstyle == hairstyle
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              size: 18,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ],
  );
}
