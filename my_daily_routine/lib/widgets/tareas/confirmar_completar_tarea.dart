import 'package:flutter/material.dart';

import '../../data/tareas_store.dart';
import '../../models/tarea_modelo.dart';
import '../../services/tareas_api_service.dart';
import '../../theme.dart';

/// Muestra el modal de confirmación para completar una tarea.
///
/// Solo se cierra cuando el usuario cancela o cuando el backend confirma el
/// completado. Si el PATCH falla, permanece abierto mostrando el error.
Future<void> mostrarConfirmarCompletar(
  BuildContext context,
  NuevaTarea tarea,
) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ConfirmarCompletarDialog(tarea: tarea),
  );
}

class _ConfirmarCompletarDialog extends StatefulWidget {
  final NuevaTarea tarea;
  const _ConfirmarCompletarDialog({required this.tarea});

  @override
  State<_ConfirmarCompletarDialog> createState() =>
      _ConfirmarCompletarDialogState();
}

class _ConfirmarCompletarDialogState extends State<_ConfirmarCompletarDialog> {
  bool _cargando = false;
  String? _error;

  Future<void> _confirmar() async {
    if (_cargando) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      await TareasStore.instancia.alternarCompletada(widget.tarea);
      if (!mounted) return;
      Navigator.pop(context);
    } on TareasApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = 'No se pudo completar la tarea. Inténtalo de nuevo.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.logo),
      ),
      title: const Text(
        '¿Completaste esta tarea?',
        style: TextStyle(
          color: AppColors.textDark,
          fontSize: 19,
          fontWeight: FontWeight.w800,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Confirma que realmente realizaste esta actividad.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '“${widget.tarea.titulo}”',
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Una vez confirmada, no podrás desmarcarla.',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(
                color: Color(0xFFE05252),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _cargando ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
          ),
          onPressed: _cargando ? null : _confirmar,
          child: _cargando
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Sí, completar tarea'),
        ),
      ],
    );
  }
}
