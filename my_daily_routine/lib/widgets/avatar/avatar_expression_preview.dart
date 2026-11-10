import 'package:flutter/material.dart';

import '../../models/avatar_config.dart';
import '../../models/avatar_expression.dart';
import '../../theme.dart';
import 'avatar_character.dart';

class AvatarExpressionPreview extends StatefulWidget {
  final AvatarConfig config;
  const AvatarExpressionPreview({super.key, required this.config});
  @override
  State<AvatarExpressionPreview> createState() =>
      _AvatarExpressionPreviewState();
}

class _AvatarExpressionPreviewState extends State<AvatarExpressionPreview> {
  AvatarExpression _expression = AvatarExpression.neutral;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text(
        'Expresiones',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 8),
      const Text(
        'Prueba cómo reacciona tu avatar. En el inicio, la expresión se elige automáticamente según tu progreso general. Esta vista no cambia tus estadísticas ni tu apariencia guardada.',
        style: TextStyle(color: AppColors.textMuted),
      ),
      const SizedBox(height: 12),
      Container(
        height: 210,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFFE3EAFF),
          borderRadius: BorderRadius.circular(20),
        ),
        child: OverflowBox(
          alignment: Alignment.topCenter,
          minWidth: 480,
          maxWidth: 480,
          minHeight: 960,
          maxHeight: 960,
          child: AvatarCharacter(
            config: widget.config,
            portrait: true,
            expression: _expression,
          ),
        ),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final expression in AvatarExpression.values)
            ChoiceChip(
              label: Text(expression.label),
              selected: expression == _expression,
              onSelected: (_) => setState(() => _expression = expression),
            ),
        ],
      ),
      const SizedBox(height: 8),
      const Text(
        '0–24: cansado · 25–49: aburrido · 50–74: tranquilo · 75–100: alegre',
        style: TextStyle(color: AppColors.textMuted, fontSize: 12),
      ),
    ],
  );
}
