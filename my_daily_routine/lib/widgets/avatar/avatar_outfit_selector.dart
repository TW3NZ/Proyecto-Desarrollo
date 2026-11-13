import 'package:flutter/material.dart';

import '../../models/avatar_config.dart';
import '../../theme.dart';
import 'avatar_character.dart';

/// Selector de vestuario. Muestra solo las prendas disponibles para el
/// personaje elegido; "Ninguno" enseña el personaje base y cada prenda
/// enseña su propia imagen.
class AvatarOutfitSelector extends StatelessWidget {
  final AvatarConfig config;
  final ValueChanged<AvatarOutfit> onSelected;

  const AvatarOutfitSelector({
    super.key,
    required this.config,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Vestuario',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final outfit in AvatarOutfit.values)
            if (outfit.disponiblePara(config.characterType))
              _TarjetaOutfit(
                config: config,
                outfit: outfit,
                selected: config.outfit == outfit,
                onTap: () => onSelected(outfit),
              ),
        ],
      ),
    ],
  );
}

class _TarjetaOutfit extends StatelessWidget {
  final AvatarConfig config;
  final AvatarOutfit outfit;
  final bool selected;
  final VoidCallback onTap;

  const _TarjetaOutfit({
    required this.config,
    required this.outfit,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final basePath = AvatarResources.assetFor(
      config.characterType,
      config.hairstyle,
    );

    return Semantics(
      selected: selected,
      button: true,
      label: 'Vestuario ${outfit.label}',
      child: SizedBox(
        width: 106,
        child: Material(
          color: selected ? const Color(0xFFE3EAFF) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: selected ? AppColors.primary : AppColors.fieldBorder,
              width: selected ? 2 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: ValueKey('outfit-${outfit.name}'),
            onTap: onTap,
            child: ExcludeSemantics(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 84,
                      width: 84,
                      child: _miniatura(basePath),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      outfit.label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Icon(
                      selected ? Icons.check_circle : Icons.circle_outlined,
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
    );
  }

  Widget _miniatura(String basePath) {
    final asset = outfit.assetPath;
    if (asset == null) {
      return ClipRect(
        child: OverflowBox(
          alignment: Alignment.topCenter,
          minWidth: 168,
          maxWidth: 168,
          minHeight: 336,
          maxHeight: 336,
          child: Image.asset(
            basePath,
            fit: BoxFit.contain,
            excludeFromSemantics: true,
            errorBuilder: (_, _, _) => const Icon(
              Icons.person_outline,
              size: 64,
            ),
          ),
        ),
      );
    }
    return Image.asset(
      asset,
      fit: BoxFit.cover,
      alignment: const Alignment(0, -0.25),
      excludeFromSemantics: true,
      errorBuilder: (_, _, _) => const Icon(
        Icons.checkroom_outlined,
        size: 64,
      ),
    );
  }
}
