import 'package:flutter/material.dart';

enum AvatarPart { skin, hair, shirt, trousers }

enum AvatarCharacterType { hombre, mujer }

enum AvatarEyes {
  original('Originales'),
  almond('Almendrados'),
  round('Redondos');

  final String label;
  const AvatarEyes(this.label);
}

enum AvatarNose {
  original('Original'),
  straight('Recta'),
  round('Redondeada');

  final String label;
  const AvatarNose(this.label);
}

enum AvatarMouth {
  original('Original'),
  smile('Sonrisa amplia'),
  neutral('Neutral');

  final String label;
  const AvatarMouth(this.label);
}

enum AvatarHairstyle {
  original('Original'),
  corto('Corto'),
  rizado('Rizado'),
  recogido('Recogido');

  final String label;
  const AvatarHairstyle(this.label);
}

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
  final AvatarCharacterType characterType;
  final AvatarHairstyle hairstyle;
  final AvatarEyes eyes;
  final AvatarNose nose;
  final AvatarMouth mouth;
  final bool motion;

  const AvatarConfig({
    this.skin = 'original',
    this.hair = 'original',
    this.shirt = 'original',
    this.trousers = 'original',
    this.characterType = AvatarCharacterType.hombre,
    this.hairstyle = AvatarHairstyle.original,
    this.eyes = AvatarEyes.original,
    this.nose = AvatarNose.original,
    this.mouth = AvatarMouth.original,
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

  AvatarConfig copyWith({
    String? skin,
    String? hair,
    String? shirt,
    String? trousers,
    AvatarCharacterType? characterType,
    AvatarHairstyle? hairstyle,
    AvatarEyes? eyes,
    AvatarNose? nose,
    AvatarMouth? mouth,
    bool? motion,
  }) => AvatarConfig(
    skin: skin ?? this.skin,
    hair: hair ?? this.hair,
    shirt: shirt ?? this.shirt,
    trousers: trousers ?? this.trousers,
    characterType: characterType ?? this.characterType,
    hairstyle: hairstyle ?? this.hairstyle,
    eyes: eyes ?? this.eyes,
    nose: nose ?? this.nose,
    mouth: mouth ?? this.mouth,
    motion: motion ?? this.motion,
  );

  AvatarConfig withColor(AvatarPart part, String id) {
    if (!avatarPalettes[part]!.any((item) => item.id == id)) return this;
    return switch (part) {
      AvatarPart.skin => copyWith(skin: id),
      AvatarPart.hair => copyWith(hair: id),
      AvatarPart.shirt => copyWith(shirt: id),
      AvatarPart.trousers => copyWith(trousers: id),
    };
  }

  AvatarConfig withCharacterType(AvatarCharacterType value) =>
      copyWith(characterType: value);
  AvatarConfig withMotion(bool value) => copyWith(motion: value);
  AvatarConfig withHairstyle(AvatarHairstyle value) =>
      copyWith(hairstyle: value);
  Map<String, Object> toJson() => {
    'version': 1,
    'skin': skin,
    'hair': hair,
    'shirt': shirt,
    'trousers': trousers,
    'characterType': characterType.name,
    'hairstyle': hairstyle.name,
    'eyes': eyes.name,
    'nose': nose.name,
    'mouth': mouth.name,
    'motion': motion,
  };

  factory AvatarConfig.fromJson(Map<String, dynamic> json) {
    var result = const AvatarConfig();
    for (final part in AvatarPart.values) {
      final id = json[part.name];
      if (id is String) result = result.withColor(part, id);
    }
    final characterType = AvatarCharacterType.values.firstWhere(
      (value) => value.name == json['characterType'],
      orElse: () => AvatarCharacterType.hombre,
    );
    return result
        .withCharacterType(characterType)
        .withHairstyle(
          AvatarHairstyle.values.firstWhere(
            (value) => value.name == json['hairstyle'],
            orElse: () => AvatarHairstyle.original,
          ),
        )
        .withMotion(json['motion'] is bool ? json['motion'] as bool : true)
        .copyWith(
          eyes: AvatarEyes.values.firstWhere(
            (e) => e.name == json['eyes'],
            orElse: () => AvatarEyes.original,
          ),
          nose: AvatarNose.values.firstWhere(
            (e) => e.name == json['nose'],
            orElse: () => AvatarNose.original,
          ),
          mouth: AvatarMouth.values.firstWhere(
            (e) => e.name == json['mouth'],
            orElse: () => AvatarMouth.original,
          ),
        );
  }
}
