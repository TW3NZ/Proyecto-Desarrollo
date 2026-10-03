import 'package:flutter/material.dart';
import '../theme.dart';

/// Enlace de texto pequeño, azul y en negrita.
class TextLink extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;

  const TextLink({super.key, required this.text, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
