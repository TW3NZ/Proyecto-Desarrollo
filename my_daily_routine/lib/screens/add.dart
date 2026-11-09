import 'package:flutter/material.dart';

import '../data/tareas_store.dart';
import '../data/id_temporal_store.dart';
import '../data/usuarios_store.dart';
import '../models/tarea_modelo.dart';
import '../theme.dart';
import '../utils/snackbar_utils.dart';
import '../widgets/anadir_tarea/campo_texto_tarea.dart';
import '../widgets/anadir_tarea/etiqueta_seccion.dart';
import '../widgets/anadir_tarea/selector_categorias.dart';
import '../widgets/anadir_tarea/selector_prioridad.dart';
import '../widgets/common/cabecera_app.dart';
import '../widgets/common/primary_button.dart';

/// Pantalla "Nueva tarea".
///
/// Al crear una tarea, la guarda en [TareasStore] y regresa a la pantalla anterior.
class AddScreen extends StatefulWidget {
  const AddScreen({super.key});

  @override
  State<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> {
  static const _maxTitulo = 100;
  static const _maxDescripcion = 200;

  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();

  final Set<CategoriaTarea> _categorias = {};
  PrioridadTarea _prioridad = PrioridadTarea.media;
  DateTime? _fechaFinalizacion;

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  void _alternarCategoria(CategoriaTarea categoria) {
    setState(() {
      if (!_categorias.remove(categoria)) _categorias.add(categoria);
    });
  }

  Future<void> _seleccionarFechaFinalizacion() async {
    final hoy = DateUtils.dateOnly(DateTime.now());
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaFinalizacion ?? hoy,
      firstDate: hoy,
      lastDate: DateTime(hoy.year + 10),
      helpText: 'Selecciona la fecha de finalización',
      cancelText: 'Cancelar',
      confirmText: 'Elegir',
    );

    if (fecha != null && mounted) {
      setState(() => _fechaFinalizacion = DateUtils.dateOnly(fecha));
    }
  }

  String _formatearFecha(DateTime fecha) =>
      '${fecha.day.toString().padLeft(2, '0')}/'
      '${fecha.month.toString().padLeft(2, '0')}/'
      '${fecha.year}';

  void _crearTarea() {
    final titulo = _tituloController.text.trim();

    if (titulo.isEmpty) {
      showAppSnackBar(context, message: 'Escribe qué tienes que hacer');
      return;
    }
    if (_categorias.isEmpty) {
      showAppSnackBar(context, message: 'Elige al menos una categoría');
      return;
    }

    final tarea = NuevaTarea(
      id: IdTemporalStore.generar(),
      usuarioId:
          UsuariosStore.usuarioActual?.id ?? UsuariosStore.idUsuarioPractica,
      titulo: titulo,
      categorias: Set.unmodifiable(_categorias),
      prioridad: _prioridad,
      descripcion: _descripcionController.text.trim(),
      fechaFinalizacion: _fechaFinalizacion,
    );

    TareasStore.instancia.agregarTarea(tarea);
    showAppSnackBar(context, message: 'Tarea creada');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: Column(
          children: [
            CabeceraApp(
              titulo: 'Nueva tarea',
              alVolver: () => Navigator.maybePop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ---- Qué tienes que hacer ----
                    const EtiquetaSeccion(
                      icono: Icons.edit_note_rounded,
                      texto: '¿Qué tienes que hacer?',
                    ),
                    const SizedBox(height: 10),
                    CampoTextoTarea(
                      controlador: _tituloController,
                      pista: 'Ej. Estudiar para el parcial',
                      maxCaracteres: _maxTitulo,
                      accionTeclado: TextInputAction.next,
                    ),
                    const SizedBox(height: 14),

                    // ---- Categoría (una o varias) ----
                    const EtiquetaSeccion(
                      icono: Icons.folder_rounded,
                      texto: 'Categoría',
                      nota: '(una o varias)',
                    ),
                    const SizedBox(height: 10),
                    SelectorCategorias(
                      seleccionadas: _categorias,
                      alAlternar: _alternarCategoria,
                    ),
                    const SizedBox(height: 22),

                    // ---- Prioridad ----
                    const EtiquetaSeccion(
                      icono: Icons.flag_rounded,
                      texto: 'Prioridad',
                    ),
                    const SizedBox(height: 10),
                    SelectorPrioridad(
                      seleccionada: _prioridad,
                      alCambiar: (p) => setState(() => _prioridad = p),
                    ),
                    const SizedBox(height: 22),

                    // ---- Fecha de finalización ----
                    const EtiquetaSeccion(
                      icono: Icons.event_available_rounded,
                      texto: 'Fecha de finalización',
                      nota: '(opcional)',
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _seleccionarFechaFinalizacion,
                            icon: const Icon(Icons.calendar_month_rounded),
                            label: Text(
                              _fechaFinalizacion == null
                                  ? 'Elegir fecha'
                                  : _formatearFecha(_fechaFinalizacion!),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              backgroundColor: AppColors.fieldFill,
                              side: const BorderSide(
                                color: AppColors.fieldBorder,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        if (_fechaFinalizacion != null) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: 'Quitar fecha',
                            onPressed: () =>
                                setState(() => _fechaFinalizacion = null),
                            icon: const Icon(Icons.close_rounded),
                            color: AppColors.textMuted,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 22),

                    // ---- Descripción ----
                    const EtiquetaSeccion(
                      icono: Icons.notes_rounded,
                      texto: 'Descripción',
                      nota: '(opcional)',
                    ),
                    const SizedBox(height: 10),
                    CampoTextoTarea(
                      controlador: _descripcionController,
                      pista: 'Añade una nota sobre esta tarea...',
                      maxCaracteres: _maxDescripcion,
                      lineasMinimas: 3,
                      lineasMaximas: 5,
                    ),
                  ],
                ),
              ),
            ),

            // ---- Botón fijo abajo ----
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                child: PrimaryButton(
                  text: 'Crear tarea',
                  onPressed: _crearTarea,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
