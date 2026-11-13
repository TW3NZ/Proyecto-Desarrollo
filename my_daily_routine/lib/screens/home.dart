import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../assets_paths.dart';
import '../data/estadisticas_store.dart';
import '../data/avatar_store.dart';
import '../data/usuarios_store.dart';
import '../data/tareas_store.dart';
import '../routes.dart';
import '../theme.dart';
import '../utils/snackbar_utils.dart';
import '../widgets/home/home_bottom_bar.dart';
import '../widgets/home/home_scene.dart';
import '../widgets/home/round_buttons.dart';

import 'dart:async';
import 'dart:math';

import 'package:showcaseview/showcaseview.dart';

/// Pantalla principal. Es StatefulWidget solo para recordar qué fondo se está
/// mostrando (el botón de la esquina superior derecha los va alternando).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.mostrarTutorial = false});

  final bool mostrarTutorial;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _tareasKey = GlobalKey();
  final _avatarKey = GlobalKey();
  final _estadisticasKey = GlobalKey();
  final _anadirTareaKey = GlobalKey();
  final _teamsKey = GlobalKey();
  int _bgIndex = 0;
  String? _syncError;
  bool _syncing = false;

  Future<void> _sync() async {
    if (_syncing) return;
    setState(() {
      _syncing = true;
      _syncError = null;
    });
    try {
      await Future.wait([
        AvatarStore.instancia.load(),
        EstadisticasStore.instancia.load(),
        TareasStore.instancia.refresh(),
      ]);
    } catch (_) {
      if (mounted) {
        setState(() => _syncError = 'No se pudieron cargar todos tus datos.');
      }
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  String _estadisticaSeleccionada = 'Inteligencia';

  static const _frases = [
    '¡Vamos, tú puedes!',
    '¡Sigue así!',
    '¡Hoy es tu día!',
    '¡Tú puedes!',
    '¡Vamos!',
    '¡Adelante!',
    '¡Con ganas!',
    '¡Sin miedo!',
    '¡A por ello!',
    '¡Hoy sí!',
    '¡Tú marcas el ritmo!',
    '¡Sigue así!',
    '¡Ya casi!',
    '¡Paso a paso!',
    '¡Confía en ti!',
    '¡Eres capaz!',
    '¡Hazlo ahora!',
    '¡No pares!',
    '¡Tú puedes más!',
    '¡Vas genial!',
    '¡Mantén el ritmo!',
    '¡Hoy suma!',
    '¡Lo lograrás!',
    '¡Sigue avanzando!',
    '¡Cree en ti!',
    '¡A brillar!',
    '¡Un día más!',
    '¡Constancia!',
    '¡Hoy cuenta!',
    '¡Dale con ganas!',
    '¡Sigue firme!',
    '¡Tú eres capaz!',
    '¡Vamos por más!',
  ];

  late String _frase;
  Timer? _timerFrase;

  @override
  void initState() {
    super.initState();
    _frase = _frases[Random().nextInt(_frases.length)];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _sync();
    });
    ShowcaseView.register(skipIfTargetNotPresent: true);
    if (widget.mostrarTutorial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ShowcaseView.get().startShowCase([
          _tareasKey,
          _avatarKey,
          _estadisticasKey,
          _anadirTareaKey,
          _teamsKey,
        ], delay: const Duration(milliseconds: 500));
      });
    }
    _timerFrase = Timer.periodic(
      const Duration(minutes: 2),
      (_) => _cambiarFrase(),
    );
  }

  @override
  void dispose() {
    _timerFrase?.cancel();
    ShowcaseView.get().unregister();
    super.dispose();
  }

  void _cambiarFrase() {
    if (_frases.length < 2) return;
    String nueva;
    do {
      nueva = _frases[Random().nextInt(_frases.length)];
    } while (nueva == _frase); // evita repetir la misma frase
    setState(() => _frase = nueva);
  }

  void _nextBackground() {
    final total = AppAssets.homeBackgrounds.length;
    if (total < 2) return;
    setState(() => _bgIndex = (_bgIndex + 1) % total);
  }

  Widget _burbujaGuia({
    required GlobalKey key,
    required int paso,
    required String titulo,
    required String descripcion,
    required String davoAsset,
    required TooltipPosition tooltipPosition,
    required Widget child,
  }) {
    final anchoPantalla = MediaQuery.sizeOf(context).width;
    final anchoBurbuja = switch (tooltipPosition) {
      TooltipPosition.left ||
      TooltipPosition.right => min(anchoPantalla * 0.68, 380.0),
      TooltipPosition.top ||
      TooltipPosition.bottom => min(anchoPantalla - 32, 380.0),
    };

    return Showcase.withWidget(
      key: key,
      tooltipPosition: tooltipPosition,
      targetShapeBorder: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      targetPadding: const EdgeInsets.all(4),
      overlayColor: AppColors.primaryDark,
      overlayOpacity: 0.76,
      container: _BurbujaGuia(
        paso: paso,
        total: 5,
        titulo: titulo,
        descripcion: descripcion,
        davoAsset: davoAsset,
        ancho: anchoBurbuja,
      ),
      child: child,
    );
  }

  void _onBottomBarTap(int index) {
    // barra inferior
    switch (index) {
      case 0:
        return;
      case 1:
        Navigator.pushNamed(context, AppRoutes.teams);
        return;
      case 2:
        showAppSnackBar(context, message: 'Buscar próximamente');
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Fondo (intercambiable)
            HomeBackground(paths: AppAssets.homeBackgrounds, index: _bgIndex),

            // 2. Avatar personalizado con movimiento suave sobre el fondo.
            const Align(alignment: Alignment(0, -0.30), child: AvatarSlot()),

            // 3. Botones y datos encima de todo
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                child: Column(
                  children: [
                    // ---- Barra superior ----
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: width * 0.68,
                              ),
                              child: _GreetingChip(text: _frase),
                            ),
                            const SizedBox(height: 8),
                            Tooltip(
                              message: 'Cerrar sesión',
                              child: CircleMenuButton(
                                icon: Icons.logout_rounded,
                                size: 44,
                                onTap: () {
                                  UsuariosStore.cerrarSesion();
                                  Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    AppRoutes.login,
                                    (_) => false,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Column(
                          children: [
                            const CircleMenuButton(
                              icon: Icons.notifications_rounded,
                              iconAsset: AppAssets.iconNotificaciones,
                              size: 44,
                            ),
                            const SizedBox(height: 8),
                            Tooltip(
                              message: 'Cambiar fondo',
                              child: CircleMenuButton(
                                icon: Icons.wallpaper_rounded,
                                iconAsset: AppAssets.iconCambiarFondo,
                                size: 44,
                                onTap: _nextBackground,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // ---- Columnas laterales (el centro queda libre para el avatar) ----
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Respetar la altura disponible sobre Añadir tarea.
                          final menuSize = min(
                            (width * 0.19).clamp(60.0, 80.0),
                            max(0.0, (constraints.maxHeight - 34) / 4),
                          );
                          final statSize = min(
                            (width * 0.23).clamp(78.0, 100.0),
                            max(0.0, (constraints.maxHeight - 60) / 3),
                          );
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Izquierda
                              Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _burbujaGuia(
                                        key: _tareasKey,
                                        paso: 1,
                                        titulo: 'Tus tareas',
                                        descripcion: 'Aquí consultas las tareas del día y tu progreso.',
                                        davoAsset: AppAssets.davoGuideTasks,
                                        tooltipPosition: TooltipPosition.right,
                                        child: CircleMenuButton(
                                          label: 'Tareas Diarias',
                                          icon: Icons.checklist_rounded,
                                          iconAsset:
                                              AppAssets.iconTareasDiarias,
                                          size: menuSize,
                                          onTap: () => Navigator.pushNamed(
                                            context,
                                            AppRoutes.tareas,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      CircleMenuButton(
                                        label: 'General',
                                        icon: Icons.track_changes_rounded,
                                        iconAsset: AppAssets.iconObjetivos,
                                        size: menuSize,
                                        onTap: () => Navigator.pushNamed(
                                          context,
                                          AppRoutes.estadisticas,
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      _burbujaGuia(
                                        key: _avatarKey,
                                        paso: 2,
                                        titulo: 'Tu avatar',
                                        descripcion: 'Personaliza sus colores desde aquí.',
                                        davoAsset: AppAssets.davoGuideAvatar,
                                        tooltipPosition: TooltipPosition.right,
                                        child: CircleMenuButton(
                                          label: 'Avatar',
                                          icon: Icons.person_rounded,
                                          iconAsset: AppAssets.iconPersonalizar,
                                          size: menuSize,
                                          onTap: () => Navigator.pushNamed(
                                            context,
                                            AppRoutes.avatar,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const Spacer(),

                              // Derecha (estadísticas del dominio)
                              AnimatedBuilder(
                                animation: Listenable.merge([
                                  EstadisticasStore.instancia,
                                  TareasStore.instancia,
                                ]),
                                builder: (context, _) {
                                  final estadisticas =
                                      EstadisticasStore.instancia;
                                  final tareas = TareasStore.instancia.tareas;
                                  final tareasRealizadas = tareas
                                      .where((tarea) => tarea.completada)
                                      .length;
                                  final progresoTareas = tareas.isEmpty
                                      ? 0.0
                                      : tareasRealizadas / tareas.length;
                                  final estadisticasRotativas =
                                      [
                                            (
                                              key: 'Inteligencia',
                                              title: 'Inteligencia',
                                              value: estadisticas.inteligencia,
                                              icon: Icons.psychology_rounded,
                                              asset: AppAssets.iconInteligencia,
                                              activa: estadisticas
                                                  .inteligenciaActiva,
                                            ),
                                            (
                                              key: 'Finanzas',
                                              title: 'Finanzas',
                                              value: estadisticas.finanzas,
                                              icon: Icons
                                                  .account_balance_wallet_rounded,
                                              asset: null,
                                              activa:
                                                  estadisticas.finanzasActiva,
                                            ),
                                            (
                                              key: 'Salud',
                                              title: 'Salud',
                                              value: estadisticas.salud,
                                              icon: Icons.favorite_rounded,
                                              asset: null,
                                              activa: estadisticas.saludActiva,
                                            ),
                                            (
                                              key: 'Disciplina',
                                              title: 'Disciplina',
                                              value: estadisticas.disciplina,
                                              icon: Icons
                                                  .self_improvement_rounded,
                                              asset: null,
                                              activa:
                                                  estadisticas.disciplinaActiva,
                                            ),
                                          ]
                                          .where(
                                            (estadistica) => estadistica.activa,
                                          )
                                          .toList();
                                  final indiceSeleccionado =
                                      estadisticasRotativas.indexWhere(
                                        (estadistica) =>
                                            estadistica.key ==
                                            _estadisticaSeleccionada,
                                      );
                                  final estadisticaActual =
                                      estadisticasRotativas.isEmpty
                                      ? null
                                      : estadisticasRotativas[indiceSeleccionado <
                                                0
                                            ? 0
                                            : indiceSeleccionado];

                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _burbujaGuia(
                                        key: _estadisticasKey,
                                        paso: 3,
                                        titulo: 'Tu progreso',
                                        descripcion: 'Las estadísticas resumen cómo avanzas con tus tareas.',
                                        davoAsset: AppAssets.davoGuideProgress,
                                        tooltipPosition: TooltipPosition.left,
                                        child: StatBubble(
                                          title: 'General',
                                          value:
                                              '${estadisticas.general.toStringAsFixed(0)}/100',
                                          progress: estadisticas.general / 100,
                                          icon: Icons
                                              .local_fire_department_rounded,
                                          iconAsset: AppAssets.iconAura,
                                          size: statSize,
                                        ),
                                      ),
                                      const SizedBox(height: 30),
                                      StatBubble(
                                        title:
                                            estadisticaActual?.title ??
                                            'Sin activas',
                                        value: estadisticaActual == null
                                            ? '--'
                                            : '${estadisticaActual.value.toStringAsFixed(0)}/100',
                                        progress: estadisticaActual == null
                                            ? null
                                            : estadisticaActual.value / 100,
                                        icon:
                                            estadisticaActual?.icon ??
                                            Icons.insights_rounded,
                                        iconAsset: estadisticaActual?.asset,
                                        size: statSize,
                                        onTap:
                                            estadisticaActual == null ||
                                                estadisticasRotativas.length < 2
                                            ? null
                                            : () {
                                                final indiceActual =
                                                    estadisticasRotativas
                                                        .indexWhere(
                                                          (estadistica) =>
                                                              estadistica.key ==
                                                              estadisticaActual
                                                                  .key,
                                                        );
                                                setState(() {
                                                  _estadisticaSeleccionada =
                                                      estadisticasRotativas[(indiceActual +
                                                                  1) %
                                                              estadisticasRotativas
                                                                  .length]
                                                          .key;
                                                });
                                              },
                                      ),
                                      const SizedBox(height: 30),
                                      StatBubble(
                                        title: 'Tareas realizadas',
                                        value: '$tareasRealizadas',
                                        progress: progresoTareas,
                                        icon: Icons.fact_check_rounded,
                                        iconAsset:
                                            AppAssets.iconTareasRealizadas,
                                        size: statSize,
                                        onTap: () => Navigator.pushNamed(
                                          context,
                                          AppRoutes.historial,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                    // ---- Botón central ----
                    _burbujaGuia(
                      key: _anadirTareaKey,
                      paso: 4,
                      titulo: 'Empieza con una tarea',
                      descripcion:
                          'Añade una tarea propia para comenzar tu rutina.',
                      davoAsset: AppAssets.davoGuideStartTask,
                      tooltipPosition: TooltipPosition.top,
                      child: AddTaskButton(
                        iconAsset: AppAssets.iconAnadirTarea,
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.add),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ---- Barra inferior ----
                    HomeBottomBar(
                      currentIndex: 0,
                      onTap: _onBottomBarTap,
                      teamsItemGuide: (child) => _burbujaGuia(
                        key: _teamsKey,
                        paso: 5,
                        titulo: 'Teams',
                        descripcion: 'Trabaja en equipo creando un team.',
                        davoAsset: AppAssets.davoGuideTeams,
                        tooltipPosition: TooltipPosition.top,
                        child: child,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_syncing || _syncError != null)
              Positioned(
                top: 0,
                left: 12,
                right: 12,
                child: SafeArea(
                  child: Material(
                    borderRadius: BorderRadius.circular(16),
                    child: ListTile(
                      title: Text(_syncError ?? 'Recuperando tus datos...'),
                      trailing: _syncing
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(),
                            )
                          : TextButton(
                              onPressed: _sync,
                              child: const Text('Reintentar'),
                            ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BurbujaGuia extends StatelessWidget {
  const _BurbujaGuia({
    required this.paso,
    required this.total,
    required this.titulo,
    required this.descripcion,
    required this.davoAsset,
    required this.ancho,
  });

  final int paso;
  final int total;
  final String titulo;
  final String descripcion;
  final String davoAsset;
  final double ancho;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final anchoDavo = min(ancho * 0.22, 80.0);

    return Container(
      width: ancho,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.fieldFill,
        borderRadius: BorderRadius.circular(AppRadius.logo),
        border: Border.all(color: AppColors.fieldBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.14),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    'PASO $paso DE $total',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: texto.labelSmall?.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Omitir recorrido',
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints.tightFor(
                  width: 36,
                  height: 36,
                ),
                onPressed: ShowcaseView.get().dismiss,
                icon: const Icon(Icons.close_rounded, size: 20),
                color: AppColors.textMuted,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: anchoDavo,
                height: anchoDavo,
                child: Image.asset(
                  davoAsset,
                  fit: BoxFit.contain,
                  excludeFromSemantics: true,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.emoji_emotions_outlined,
                    color: AppColors.textHint,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      titulo,
                      style: texto.titleMedium?.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      descripcion,
                      style: texto.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: paso > 1
                ? WrapAlignment.spaceBetween
                : WrapAlignment.end,
            runSpacing: 6,
            children: [
              if (paso > 1)
                TextButton(
                  onPressed: ShowcaseView.get().previous,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryDark,
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Atrás'),
                )
              else
                const SizedBox.shrink(),
              FilledButton(
                onPressed: paso == total
                    ? ShowcaseView.get().dismiss
                    : ShowcaseView.get().next,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                ),
                child: Text(paso == total ? 'Terminar' : 'Siguiente'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Saludo de la esquina superior izquierda: miniatura del avatar + texto + flecha.
class _GreetingChip extends StatelessWidget {
  final String text;

  const _GreetingChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1B2A6B).withValues(alpha: 0.55),
      shape: StadiumBorder(
        side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () {}, // TODO: abrir perfil / mensajes
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppGradients.logo,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: ClipOval(
                  child: Center(
                    child: Image.asset(
                      AppAssets.davo,
                      width: 30,
                      height: 30,
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
