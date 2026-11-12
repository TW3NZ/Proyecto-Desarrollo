import 'package:flutter/material.dart';

import '../data/tareas_store.dart';
import '../data/id_temporal_store.dart';
import '../data/usuarios_store.dart';
import '../models/tarea_modelo.dart';
import '../services/tareas_api_service.dart';
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
  final _tareasApi = TareasApiService();
  bool _enviando = false;

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

  Future<void> _crearTarea() async {
    if (_enviando) return;
    final titulo = _tituloController.text.trim();

    if (titulo.isEmpty) {
      showAppSnackBar(context, message: 'Escribe qué tienes que hacer');
      return;
    }
    if (_categorias.isEmpty) {
      showAppSnackBar(context, message: 'Elige al menos una categoría');
      return;
    }

    final usuarioId =
        UsuariosStore.usuarioActual?.id ?? UsuariosStore.idUsuarioPractica;

    // Cuenta de práctica: comportamiento local previo, con ID temporal.
    if (usuarioId <= 0) {
      TareasStore.instancia.agregarTarea(
        _construirTarea(
          id: IdTemporalStore.generar(),
          usuarioId: usuarioId,
          titulo: titulo,
        ),
      );
      showAppSnackBar(context, message: 'Tarea creada');
      Navigator.pop(context);
      return;
    }

    final token = UsuariosStore.token;
    if (token == null || token.isEmpty) {
      showAppSnackBar(
        context,
        message: 'No hay sesión activa. Inicia sesión de nuevo.',
      );
      return;
    }

    setState(() => _enviando = true);
    try {
      final idTarea = await _tareasApi.crearTarea(
        _cuerpoDeTarea(titulo: titulo),
        token: token,
      );
      if (!mounted) return;
      TareasStore.instancia.agregarTarea(
        _construirTarea(id: idTarea, usuarioId: usuarioId, titulo: titulo),
      );
      showAppSnackBar(context, message: 'Tarea creada');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        message: e is TareasApiException
            ? e.message
            : 'No se pudo crear la tarea. Inténtalo de nuevo.',
      );
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  NuevaTarea _construirTarea({
    required int id,
    required int usuarioId,
    required String titulo,
  }) {
    return NuevaTarea(
      id: id,
      usuarioId: usuarioId,
      titulo: titulo,
      categorias: Set.unmodifiable(_categorias),
      prioridad: _prioridad,
      descripcion: _descripcionController.text.trim(),
      fechaFinalizacion: _fechaFinalizacion,
    );
  }

  Map<String, dynamic> _cuerpoDeTarea({
    required String titulo,
  }) {
    final descripcion = _descripcionController.text.trim();
    return {
      'Titulo': titulo,
      'idResponsable': null,
      'idProyecto': null,
      'Prioridad': _prioridad.etiqueta,
      'Descripcion': descripcion.isEmpty ? null : descripcion,
      'Fecha': _formatoFechaApi(DateTime.now()),
      'Fecha_Fin': _fechaFinalizacion == null
          ? null
          : _formatoFechaApi(_fechaFinalizacion!),
      'Completada': false,
      'categorias': _categorias.map((c) => c.idCategoria).toList(),
    };
  }

  String _formatoFechaApi(DateTime fecha) =>
      '${fecha.year.toString().padLeft(4, '0')}-'
      '${fecha.month.toString().padLeft(2, '0')}-'
      '${fecha.day.toString().padLeft(2, '0')}';

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
                  text: _enviando ? 'Creando tarea…' : 'Crear tarea',
                  onPressed: _enviando ? null : () => _crearTarea(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
