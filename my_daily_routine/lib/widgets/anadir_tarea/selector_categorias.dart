import 'package:flutter/material.dart';
import '../../models/tarea_modelo.dart';
import '../../theme.dart';

/// Las 4 categorías en cuadrícula de 2x2. Se pueden elegir varias a la vez.
class SelectorCategorias extends StatelessWidget {
  final Set<CategoriaTarea> seleccionadas;
  final ValueChanged<CategoriaTarea> alAlternar;

  const SelectorCategorias({
    super.key,
    required this.seleccionadas,
    required this.alAlternar,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const separacion = 10.0;
        final anchoFicha = (constraints.maxWidth - separacion) / 2;

        return Wrap(
          spacing: separacion,
          runSpacing: separacion,
          children: [
            for (final categoria in CategoriaTarea.values)
              SizedBox(
                width: anchoFicha,
                child: _FichaCategoria(
                  categoria: categoria,
                  seleccionada: seleccionadas.contains(categoria),
                  alTocar: () => alAlternar(categoria),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _FichaCategoria extends StatelessWidget {
  final CategoriaTarea categoria;
  final bool seleccionada;
  final VoidCallback alTocar;

  const _FichaCategoria({
    required this.categoria,
    required this.seleccionada,
    required this.alTocar,
  });

  @override
  Widget build(BuildContext context) {
    final radio = BorderRadius.circular(20);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 56,
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: seleccionada
                        ? Colors.white.withValues(alpha: 0.25)
                        : const Color(0xFFD6E2FB),
                  ),
                  child: Icon(
                    categoria.icono,
                    size: 18,
                    color: seleccionada ? Colors.white : AppColors.primaryDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    categoria.etiqueta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color:
                          seleccionada ? Colors.white : AppColors.primaryDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: seleccionada ? 1 : 0,
                  child: const Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
