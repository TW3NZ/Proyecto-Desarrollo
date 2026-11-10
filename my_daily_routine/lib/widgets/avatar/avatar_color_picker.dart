import 'package:flutter/material.dart';

import '../../models/avatar_config.dart';
import '../../theme.dart';

/// Shared RGB color editor. Selection is only committed on Apply.
Future<String?> pickAvatarColor(BuildContext context, Color initial) =>
    showDialog<String>(
      context: context,
      builder: (_) => _ColorDialog(initial: initial),
    );

class _ColorDialog extends StatefulWidget {
  final Color initial;
  const _ColorDialog({required this.initial});
  @override
  State<_ColorDialog> createState() => _ColorDialogState();
}

class _ColorDialogState extends State<_ColorDialog> {
  late HSVColor _color = HSVColor.fromColor(widget.initial);
  late final _hex = TextEditingController(text: _value);
  String? _error;
  String get _value =>
      '#${(_color.toColor().toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  void _change(HSVColor next) => setState(() {
    _color = next;
    _hex.text = _value;
    _error = null;
  });
  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Elige cualquier color'),
    content: SizedBox(
      width: 320,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 64,
              decoration: BoxDecoration(
                color: _color.toColor(),
                border: Border.all(color: AppColors.fieldBorder),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _hex,
              maxLength: 7,
              decoration: InputDecoration(
                labelText: 'Código hexadecimal',
                hintText: '#4169E1',
                errorText: _error,
              ),
              onChanged: (value) {
                setState(() {
                  if (AvatarConfig.isCustomColor(value)) {
                    _color = HSVColor.fromColor(
                      AvatarConfig.customColor(value),
                    );
                    _error = null;
                  } else {
                    _error = 'Usa # y seis dígitos hexadecimales.';
                  }
                });
              },
            ),
            const Text('Tono'),
            Slider(
              value: _color.hue,
              max: 360,
              semanticFormatterCallback: (v) => 'Tono ${v.round()}',
              onChanged: (v) => _change(_color.withHue(v)),
            ),
            const Text('Saturación'),
            Slider(
              value: _color.saturation,
              onChanged: (v) => _change(_color.withSaturation(v)),
            ),
            const Text('Brillo'),
            Slider(
              value: _color.value,
              onChanged: (v) => _change(_color.withValue(v)),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: AvatarConfig.isCustomColor(_hex.text)
            ? () => Navigator.pop(context, _hex.text.toUpperCase())
            : null,
        child: const Text('Aplicar color'),
      ),
    ],
  );
}

class AvatarCustomColors extends StatelessWidget {
  final String selected;
  final Color initial;
  final ValueChanged<String> onSelected;
  const AvatarCustomColors({
    super.key,
    required this.selected,
    required this.initial,
    required this.onSelected,
  });
  static const colors = <String, String>{
    '#FFFFFF': 'Blanco',
    '#171717': 'Negro',
    '#808080': 'Gris',
    '#62402A': 'Café',
    '#E53935': 'Rojo',
    '#FF7043': 'Naranja',
    '#FFC107': 'Ámbar',
    '#FFEB3B': 'Amarillo',
    '#8BC34A': 'Lima',
    '#2E7D32': 'Verde',
    '#009688': 'Turquesa',
    '#00BCD4': 'Cian',
    '#42A5F5': 'Celeste',
    '#1565C0': 'Azul',
    '#4527A0': 'Índigo',
    '#8E24AA': 'Violeta',
    '#EC407A': 'Rosa',
    '#F8BBD0': 'Rosa pastel',
    '#D7CCC8': 'Beige',
    '#80CBC4': 'Menta',
  };
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          for (final item in colors.entries)
            Semantics(
              selected: selected == item.key,
              child: IconButton(
                tooltip: item.value,
                onPressed: () => onSelected(item.key),
                icon: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AvatarConfig.customColor(item.key),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected == item.key
                          ? AppColors.primary
                          : AppColors.fieldBorder,
                      width: selected == item.key ? 3 : 1,
                    ),
                  ),
                  child: selected == item.key
                      ? Icon(
                          Icons.check,
                          size: 18,
                          color:
                              AvatarConfig.customColor(item.key)
                                      .computeLuminance() >
                                  0.4
                              ? Colors.black
                              : Colors.white,
                        )
                      : null,
                ),
              ),
            ),
        ],
      ),
      OutlinedButton.icon(
        icon: const Icon(Icons.color_lens_outlined),
        label: Text(
          AvatarConfig.isCustomColor(selected)
              ? 'Personalizado: $selected'
              : 'Más colores',
        ),
        onPressed: () async {
          final value = await pickAvatarColor(context, initial);
          if (value != null && context.mounted) onSelected(value);
        },
      ),
    ],
  );
}
