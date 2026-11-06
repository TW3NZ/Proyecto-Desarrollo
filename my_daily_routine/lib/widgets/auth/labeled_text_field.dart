import 'package:flutter/material.dart';

import '../../theme.dart';

/// Campo de texto con insignia circular + etiqueta arriba.
class LabeledTextField extends StatelessWidget {
  final String label;
  final IconData icon;
  final String hint;
  final bool obscure;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final TextInputType? keyboardType;
  final TextEditingController? controller;

  const LabeledTextField({
    super.key,
    required this.label,
    required this.icon,
    required this.hint,
    this.obscure = false,
    this.suffixIcon,
    this.onSuffixTap,
    this.keyboardType,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Color(0xFFBCD4FF), width: 1.4),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: Color(0xFFD6E2FB),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 17, color: AppColors.primaryDark),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 18, color: AppColors.textDark),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 17),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 14,
            ),
            suffixIcon: suffixIcon == null
                ? null
                : IconButton(
                    tooltip: obscure
                        ? 'Mostrar contraseña'
                        : 'Ocultar contraseña',
                    onPressed: onSuffixTap,
                    icon: Icon(
                      suffixIcon,
                      color: const Color(0xFF6B7EA6),
                      size: 25,
                    ),
                  ),
            border: border,
            enabledBorder: border,
            focusedBorder: border.copyWith(
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
