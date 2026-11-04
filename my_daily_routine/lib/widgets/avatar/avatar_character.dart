import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter/services.dart';

import '../../assets_paths.dart';
import '../../models/avatar_config.dart';

/// Imagen/programa compartidos; cada vista usa su propia instancia del shader.
class AvatarResources {
  final ui.Image image;
  final ui.FragmentProgram program;
  const AvatarResources(this.image, this.program);

  static Future<AvatarResources>? _pending;
  static AvatarResources? cached;
  static Future<AvatarResources> load() =>
      cached != null ? SynchronousFuture(cached!) : _pending ??= _load();

  static Future<AvatarResources> _load() async {
    try {
      final program = await ui.FragmentProgram.fromAsset(
        'shaders/avatar_colors.frag',
      );
      final data = await rootBundle.load(AppAssets.avatar);
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
      try {
        return cached = AvatarResources(
          (await codec.getNextFrame()).image,
          program,
        );
      } finally {
        codec.dispose();
      }
    } catch (_) {
      _pending = null;
      rethrow;
    }
  }
}

class AvatarCharacter extends StatelessWidget {
  final AvatarConfig config;
  final bool portrait;
  const AvatarCharacter({
    super.key,
    required this.config,
    this.portrait = false,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: 'Avatar personalizado',
    child: AvatarResources.cached != null
        ? _RenderedAvatar(
            resources: AvatarResources.cached!,
            config: config,
            portrait: portrait,
          )
        : FutureBuilder<AvatarResources>(
            future: AvatarResources.load(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Image.asset(
                  AppAssets.avatar,
                  fit: portrait ? BoxFit.cover : BoxFit.contain,
                  alignment: portrait ? Alignment.topCenter : Alignment.center,
                  excludeFromSemantics: true,
                );
              }
              return _RenderedAvatar(
                resources: snapshot.data!,
                config: config,
                portrait: portrait,
              );
            },
          ),
  );
}

class _RenderedAvatar extends StatefulWidget {
  final AvatarResources resources;
  final AvatarConfig config;
  final bool portrait;
  const _RenderedAvatar({
    required this.resources,
    required this.config,
    required this.portrait,
  });

  @override
  State<_RenderedAvatar> createState() => _RenderedAvatarState();
}

class _RenderedAvatarState extends State<_RenderedAvatar> {
  late final ui.FragmentShader _shader = widget.resources.program
      .fragmentShader();

  @override
  void dispose() {
    _shader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = widget.resources.image;
    return ClipRect(
      child: FittedBox(
        fit: widget.portrait ? BoxFit.cover : BoxFit.contain,
        alignment: widget.portrait ? Alignment.topCenter : Alignment.center,
        child: SizedBox(
          width: image.width.toDouble(),
          height: image.height.toDouble(),
          child: CustomPaint(
            painter: _AvatarPainter(_shader, image, widget.config),
          ),
        ),
      ),
    );
  }
}

class _AvatarPainter extends CustomPainter {
  final ui.FragmentShader shader;
  final ui.Image image;
  final AvatarConfig config;
  _AvatarPainter(this.shader, this.image, this.config);

  @override
  void paint(Canvas canvas, Size size) {
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    // Uniforms: tamaño (2), piel/cabello/camiseta/pantalón (4 × RGBA).
    for (final part in AvatarPart.values) {
      final option = config.option(part);
      final offset = 2 + part.index * 4;
      shader.setFloat(offset, option.color.r);
      shader.setFloat(offset + 1, option.color.g);
      shader.setFloat(offset + 2, option.color.b);
      shader.setFloat(offset + 3, option.id == 'original' ? 0 : 1);
    }
    shader.setImageSampler(0, image);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_AvatarPainter oldDelegate) =>
      oldDelegate.config != config;
}

/// Movimiento global sutil, anclado en los pies. No es una animación por huesos.
class AvatarMotion extends StatefulWidget {
  final bool enabled;
  final int reaction;
  final Widget child;
  const AvatarMotion({
    super.key,
    required this.child,
    this.enabled = true,
    this.reaction = 0,
  });

  @override
  State<AvatarMotion> createState() => _AvatarMotionState();
}

class _AvatarMotionState extends State<AvatarMotion>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final _idle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  );
  late final _reaction = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  bool _active = true;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _active = lifecycle == null || lifecycle == AppLifecycleState.resumed;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void didUpdateWidget(AvatarMotion oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncMotion();
    if (_running && oldWidget.reaction != widget.reaction) {
      _reaction.forward(from: 0);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    _syncMotion();
  }

  void _syncMotion() {
    final enabled =
        widget.enabled &&
        _active &&
        TickerMode.valuesOf(context).enabled &&
        !MediaQuery.disableAnimationsOf(context);
    _running = enabled;
    if (enabled) {
      if (!_idle.isAnimating) _idle.repeat(reverse: true);
    } else {
      _idle.stop();
      _reaction.stop();
      _idle.value = 0;
      _reaction.value = 0;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _idle.dispose();
    _reaction.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([_idle, _reaction]),
    child: RepaintBoundary(child: widget.child),
    builder: (context, child) {
      final breath = Curves.easeInOutSine.transform(_idle.value);
      final pulse = math.sin(_reaction.value * math.pi);
      return Transform(
        key: const ValueKey('avatar-motion-transform'),
        alignment: Alignment.bottomCenter,
        transform: Matrix4.diagonal3Values(
          1 + breath * 0.004 + pulse * 0.012,
          1 + breath * 0.008 + pulse * 0.018,
          1,
        ),
        child: child,
      );
    },
  );
}
