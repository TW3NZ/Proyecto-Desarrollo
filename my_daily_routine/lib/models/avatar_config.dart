import 'package:flutter/material.dart';

enum AvatarPart { skin, hair, shirt, trousers }

@immutable
class AvatarColorOption {
  final String id;
  final String label;
  final Color color;

  const AvatarColorOption(this.id, this.label, this.color);
}

/// Paletas limitadas al personaje v2. "original" mantiene sus píxeles intactos.
const avatarPalettes = <AvatarPart, List<AvatarColorOption>>{
  AvatarPart.skin: [
    AvatarColorOption('original', 'Original', Color(0xFFF2A469)),
    AvatarColorOption('light', 'Claro', Color(0xFFF5CBA7)),
    AvatarColorOption('golden', 'Dorado', Color(0xFFD99A62)),
    AvatarColorOption('brown', 'Moreno', Color(0xFFAC704B)),
    AvatarColorOption('deep', 'Oscuro', Color(0xFF71462F)),
  ],
  AvatarPart.hair: [
    AvatarColorOption('original', 'Castaño', Color(0xFF784A32)),
    AvatarColorOption('black', 'Negro', Color(0xFF29252A)),
    AvatarColorOption('blond', 'Rubio', Color(0xFFC29A56)),
    AvatarColorOption('copper', 'Cobrizo', Color(0xFF9C4C2C)),
    AvatarColorOption('silver', 'Plateado', Color(0xFF9296A2)),
  ],
  AvatarPart.shirt: [
    AvatarColorOption('original', 'Turquesa', Color(0xFF426B6B)),
    AvatarColorOption('blue', 'Azul', Color(0xFF315FD0)),
    AvatarColorOption('plum', 'Ciruela', Color(0xFF81528F)),
    AvatarColorOption('coral', 'Coral', Color(0xFFD87559)),
    AvatarColorOption('cream', 'Crema', Color(0xFFD7CDBA)),
  ],
  AvatarPart.trousers: [
    AvatarColorOption('original', 'Marino', Color(0xFF30364C)),
    AvatarColorOption('charcoal', 'Grafito', Color(0xFF333338)),
    AvatarColorOption('sand', 'Arena', Color(0xFFB8A386)),
    AvatarColorOption('olive', 'Oliva', Color(0xFF666D4E)),
    AvatarColorOption('denim', 'Denim', Color(0xFF486B95)),
  ],
};

@immutable
class AvatarConfig {
  final String skin;
  final String hair;
  final String shirt;
  final String trousers;
  final bool motion;

  const AvatarConfig({
    this.skin = 'original',
    this.hair = 'original',
    this.shirt = 'original',
    this.trousers = 'original',
    this.motion = true,
  });

  String selection(AvatarPart part) => switch (part) {
    AvatarPart.skin => skin,
    AvatarPart.hair => hair,
    AvatarPart.shirt => shirt,
    AvatarPart.trousers => trousers,
  };

  AvatarColorOption option(AvatarPart part) => avatarPalettes[part]!.firstWhere(
    (item) => item.id == selection(part),
    orElse: () => avatarPalettes[part]!.first,
  );

  AvatarConfig withColor(AvatarPart part, String id) {
    if (!avatarPalettes[part]!.any((item) => item.id == id)) return this;
    return AvatarConfig(
      skin: part == AvatarPart.skin ? id : skin,
      hair: part == AvatarPart.hair ? id : hair,
      shirt: part == AvatarPart.shirt ? id : shirt,
      trousers: part == AvatarPart.trousers ? id : trousers,
      motion: motion,
    );
  }

  AvatarConfig withMotion(bool enabled) => AvatarConfig(
    skin: skin,
    hair: hair,
    shirt: shirt,
    trousers: trousers,
    motion: enabled,
  );

  Map<String, Object> toJson() => {
    'version': 1,
    'skin': skin,
    'hair': hair,
    'shirt': shirt,
    'trousers': trousers,
    'motion': motion,
  };

  factory AvatarConfig.fromJson(Map<String, dynamic> json) {
    var result = const AvatarConfig();
    for (final part in AvatarPart.values) {
      final id = json[part.name];
      if (id is String) result = result.withColor(part, id);
    }
    return result.withMotion(
      json['motion'] is bool ? json['motion'] as bool : true,
    );
  }
}
