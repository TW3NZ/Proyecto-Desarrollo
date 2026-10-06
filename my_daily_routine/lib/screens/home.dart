import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../assets_paths.dart';
import '../data/estadisticas_store.dart';
import '../data/tareas_store.dart';
import '../routes.dart';
import '../theme.dart';
import '../utils/snackbar_utils.dart';
import '../widgets/home/home_bottom_bar.dart';
import '../widgets/home/home_scene.dart';
import '../widgets/home/round_buttons.dart';

import 'dart:async';
import 'dart:math';

/// Pantalla principal. Es StatefulWidget solo para recordar qué fondo se está
/// mostrando (el botón de la esquina superior derecha los va alternando).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _bgIndex = 0;
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
    _timerFrase = Timer.periodic(
      const Duration(minutes: 2),
      (_) => _cambiarFrase(),
    );
  }

  @override
  void dispose() {
    _timerFrase?.cancel();
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
    final menuSize = (width * 0.19).clamp(60.0, 80.0);
    final statSize = (width * 0.23).clamp(78.0, 100.0);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Fondo (intercambiable)
            HomeBackground(paths: AppAssets.homeBackgrounds, index: _bgIndex),

            // 2. Avatar sobre el fondo (espacio reservado, aún sin definir a falta de levis)
            const Align(
              alignment: Alignment(0, 0.25),
              child: AvatarSlot(asset: AppAssets.avatar),
            ),

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
                        _GreetingChip(
                          text: _frase,
                          avatarAsset: AppAssets.avatarThumb,
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
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Izquierda
                          Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleMenuButton(
                                    label: 'Tareas Diarias',
                                    icon: Icons.checklist_rounded,
                                    iconAsset: AppAssets.iconTareasDiarias,
                                    size: menuSize,
                                    onTap: () => Navigator.pushNamed(
                                      context,
                                      AppRoutes.tareas,
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
                                  CircleMenuButton(
                                    icon: Icons.card_giftcard_rounded,
                                    iconAsset: AppAssets.iconRegalo,
                                    size: menuSize,
                                  ),
                                ],
                              ),
                              CircleMenuButton(
                                label: 'Avatar',
                                icon: Icons.person_rounded,
                                iconAsset: AppAssets.iconPersonalizar,
                                size: menuSize,
                                onTap: () => showAppSnackBar(context),
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
                              final estadisticas = EstadisticasStore.instancia;
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
                                          activa:
                                              estadisticas.inteligenciaActiva,
                                        ),
                                        (
                                          key: 'Finanzas',
                                          title: 'Finanzas',
                                          value: estadisticas.finanzas,
                                          icon: Icons
                                              .account_balance_wallet_rounded,
                                          asset: null,
                                          activa: estadisticas.finanzasActiva,
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
                                          icon: Icons.self_improvement_rounded,
                                          asset: null,
                                          activa: estadisticas.disciplinaActiva,
                                        ),
                                      ]
                                      .where(
                                        (estadistica) => estadistica.activa,
                                      )
                                      .toList();
                              final indiceSeleccionado = estadisticasRotativas
                                  .indexWhere(
                                    (estadistica) =>
                                        estadistica.key ==
                                        _estadisticaSeleccionada,
                                  );
                              final estadisticaActual =
                                  estadisticasRotativas.isEmpty
                                  ? null
                                  : estadisticasRotativas[indiceSeleccionado < 0
                                        ? 0
                                        : indiceSeleccionado];

                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  StatBubble(
                                    title: 'General',
                                    value:
                                        '${estadisticas.general.toStringAsFixed(0)}/100',
                                    progress: estadisticas.general / 100,
                                    icon: Icons.local_fire_department_rounded,
                                    iconAsset: AppAssets.iconAura,
                                    size: statSize,
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
                                                          estadisticaActual.key,
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
                                    iconAsset: AppAssets.iconTareasRealizadas,
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
                      ),
                    ),

                    // ---- Botón central ----
                    AddTaskButton(
                      iconAsset: AppAssets.iconAnadirTarea,
                      onTap: () => Navigator.pushNamed(context, AppRoutes.add),
                    ),
                    const SizedBox(height: 14),

                    // ---- Barra inferior ----
                    HomeBottomBar(currentIndex: 0, onTap: _onBottomBarTap),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Saludo de la esquina superior izquierda: miniatura del avatar + texto + flecha.
class _GreetingChip extends StatelessWidget {
  final String text;

  /// Ruta de la miniatura del avatar. Si es null se muestra un ícono de persona.
  final String? avatarAsset;

  const _GreetingChip({required this.text, this.avatarAsset});

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
                    child: AssetOrIcon(
                      asset: avatarAsset,
                      icon: Icons.person_rounded,
                      size: 34,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
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
