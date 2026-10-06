import 'package:flutter/material.dart';
import '../../models/tarea_modelo.dart';
import '../../theme.dart';

/// Selector de prioridad: tres opciones, solo una activa.
class SelectorPrioridad extends StatelessWidget {
  final PrioridadTarea seleccionada;
  final ValueChanged<PrioridadTarea> alCambiar;

  const SelectorPrioridad({
    super.key,
    required this.seleccionada,
    required this.alCambiar,
  });

  @override
  Widget build(BuildContext context) {
    const valores = PrioridadTarea.values;

    return Row(
      children: [
        for (var i = 0; i < valores.length; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : 8),
              child: _OpcionPrioridad(
                prioridad: valores[i],
                seleccionada: valores[i] == seleccionada,
                alTocar: () => alCambiar(valores[i]),
              ),
            ),
          ),
      ],
    );
  }
}

class _OpcionPrioridad extends StatelessWidget {
  final PrioridadTarea prioridad;
  final bool seleccionada;
  final VoidCallback alTocar;

  const _OpcionPrioridad({
    required this.prioridad,
    required this.seleccionada,
    required this.alTocar,
  });

  @override
  Widget build(BuildContext context) {
    final radio = BorderRadius.circular(24);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 48,
      decoration: BoxDecoration(
        gradient: seleccionada ? AppGradients.logo : null,
        color: seleccionada ? null : AppColors.fieldFill,
        borderRadius: radio,
        border: Border.all(
          color: seleccionada
              ? Colors.white.withValues(alpha: 0.7)
              : AppColors.fieldBorder,
          width: 1.5,
        ),
        boxShadow: seleccionada
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radio,
          onTap: alTocar,
          child: Center(
            child: Text(
              prioridad.etiqueta,
              style: TextStyle(
                color: seleccionada ? Colors.white : AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
