import 'package:flutter/material.dart';
import '../../theme.dart';

/// Campo de texto redondeado con contador de caracteres abajo a la derecha
/// (se usa para el título y para la descripción).
class CampoTextoTarea extends StatelessWidget {
  final TextEditingController controlador;
  final String pista;
  final int maxCaracteres;
  final int lineasMinimas;
  final int lineasMaximas;
  final TextInputAction? accionTeclado;
  final ValueChanged<String>? alCambiar;

  const CampoTextoTarea({
    super.key,
    required this.controlador,
    required this.pista,
    required this.maxCaracteres,
    this.lineasMinimas = 1,
    this.lineasMaximas = 1,
    this.accionTeclado,
    this.alCambiar,
  });

  @override
  Widget build(BuildContext context) {
    final borde = OutlineInputBorder(
      borderRadius: BorderRadius.circular(22),
      borderSide: const BorderSide(color: AppColors.fieldBorder),
    );

    return TextField(
      controller: controlador,
      maxLength: maxCaracteres,
      minLines: lineasMinimas,
      maxLines: lineasMaximas,
      textInputAction: accionTeclado,
      textCapitalization: TextCapitalization.sentences,
      onChanged: alCambiar,
      style: const TextStyle(
        color: AppColors.textDark,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      buildCounter: (
        context, {
        required int currentLength,
        required bool isFocused,
        required int? maxLength,
      }) =>
          Align(
        alignment: Alignment.centerRight,
        child: Text(
          '$currentLength/$maxLength',
          style: const TextStyle(color: AppColors.textHint, fontSize: 12),
        ),
      ),
      decoration: InputDecoration(
        hintText: pista,
        hintStyle: const TextStyle(color: AppColors.textHint),
        filled: true,
        fillColor: AppColors.fieldFill,
        contentPadding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
        border: borde,
        enabledBorder: borde,
        focusedBorder: borde.copyWith(
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}
