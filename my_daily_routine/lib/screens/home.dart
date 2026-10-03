import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../assets_paths.dart';
import '../routes.dart';
import '../theme.dart';
import '../widgets/home/home_bottom_bar.dart';
import '../widgets/home/home_scene.dart';
import '../widgets/home/round_buttons.dart';


/// Pantalla principal. Es StatefulWidget solo para recordar qué fondo se está
/// mostrando (el botón de la esquina superior derecha los va alternando).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _bgIndex = 0;

  void _nextBackground() {
    final total = AppAssets.homeBackgrounds.length;
    if (total < 2) return;
    setState(() => _bgIndex = (_bgIndex + 1) % total);
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

            // 2. Avatar sobre el fondo (espacio reservado, aún sin definir)
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
                        const _GreetingChip(
                          text: '¡Vamos, sigue así!',
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
                    const SizedBox(height: 16),

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
                                  ),
                                  const SizedBox(height: 14),
                                  CircleMenuButton(
                                    label: 'Objetivos',
                                    icon: Icons.track_changes_rounded,
                                    iconAsset: AppAssets.iconObjetivos,
                                    size: menuSize,
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
                                label: 'Personalizar',
                                icon: Icons.person_rounded,
                                iconAsset: AppAssets.iconPersonalizar,
                                size: menuSize,
                              ),
                            ],
                          ),
                          const Spacer(),

                          // Derecha (datos de ejemplo, luego vendrán del dominio)
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              StatBubble(
                                title: 'Nivel de aura',
                                value: '80/100',
                                progress: 0.8,
                                icon: Icons.local_fire_department_rounded,
                                iconAsset: AppAssets.iconAura,
                                size: statSize,
                              ),
                              const SizedBox(height: 14),
                              StatBubble(
                                title: 'Inteligencia',
                                value: '90/100',
                                progress: 0.9,
                                icon: Icons.psychology_rounded,
                                iconAsset: AppAssets.iconInteligencia,
                                size: statSize,
                              ),
                              const SizedBox(height: 14),
                              StatBubble(
                                title: 'Tareas realizadas',
                                value: '55',
                                progress: 0.55,
                                icon: Icons.fact_check_rounded,
                                iconAsset: AppAssets.iconTareasRealizadas,
                                size: statSize,
                                onTap: () => Navigator.pushNamed(context,AppRoutes.historial),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // ---- Botón central ----
                    _AddTaskButton(
                      iconAsset: AppAssets.iconAnadirTarea,
                      onTap: () => Navigator.pushNamed(context, AppRoutes.add),
                    ),
                    const SizedBox(height: 14),

                    // ---- Barra inferior ----
                    // TODO: conectar la navegación entre pestañas.
                    const HomeBottomBar(currentIndex: 0),
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
      color: const Color(0xFF1B2A6B).withOpacity(0.55),
      shape: StadiumBorder(
        side: BorderSide(color: Colors.white.withOpacity(0.35)),
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
              const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botón central grande "+ Añadir tarea", con halo de luz y etiqueta debajo.
class _AddTaskButton extends StatelessWidget {
  /// Ruta de la imagen del ícono. Si es null se usa el "+" de Material.
  final String? iconAsset;
  final VoidCallback? onTap;
  static const double _size = 50;

  const _AddTaskButton({this.iconAsset, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GlassCircle(
          size: _size,
          onTap: onTap,
          glow: true,
          borderWidth: 3,
          child: AssetOrIcon(
            asset: iconAsset,
            icon: Icons.add_rounded,
            size: _size * 0.55,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Añadir tarea',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            shadows: [Shadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 1))],
          ),
        ),
      ],
    );
  }
}
