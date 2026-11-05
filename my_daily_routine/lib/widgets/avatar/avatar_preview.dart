import 'package:flutter/material.dart';

import '../../models/avatar_config.dart';
import 'avatar_character.dart';

class AvatarPreview extends StatelessWidget {
  final double height;
  final AvatarConfig config;
  final int reaction;

  const AvatarPreview({
    super.key,
    required this.height,
    required this.config,
    required this.reaction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE3EAFF),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: AvatarMotion(
          enabled: config.motion,
          reaction: reaction,
          child: AvatarCharacter(config: config),
        ),
      ),
    );
  }
}
