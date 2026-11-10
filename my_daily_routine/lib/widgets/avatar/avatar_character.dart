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
  final ui.Image faceA;
  final ui.Image faceB;
  const AvatarResources(this.image, this.program, this.faceA, this.faceB);

  static final Map<AvatarCharacterType, Future<(ui.Image, ui.Image)>> _faces =
      {};

  static Future<ui.Image> _readImage(String path) async {
    final data = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
    try {
      return (await codec.getNextFrame()).image;
    } finally {
      codec.dispose();
    }
  }

  static Future<(ui.Image, ui.Image)> _loadFaces(
    AvatarCharacterType type,
  ) async {
    ui.Image? first;
    try {
      first = await _readImage('lib/assets/avatar/faces/${type.name}_a.png');
      final second = await _readImage(
        'lib/assets/avatar/faces/${type.name}_b.png',
      );
      return (first, second);
    } catch (_) {
      first?.dispose();
      _faces.remove(type);
      rethrow;
    }
  }

  static final Map<
    (AvatarCharacterType, AvatarHairstyle),
    Future<AvatarResources>
  >
  _pending = {};
  static final Map<(AvatarCharacterType, AvatarHairstyle), AvatarResources>
  _cached = {};
  static AvatarResources? cachedFor(
    AvatarCharacterType type, [
    AvatarHairstyle hairstyle = AvatarHairstyle.original,
  ]) => _cached[(type, hairstyle)];

  static String assetFor(AvatarCharacterType type, AvatarHairstyle hairstyle) {
    if (hairstyle == AvatarHairstyle.original) {
      return type == AvatarCharacterType.mujer
          ? AppAssets.avatarMujer
          : AppAssets.avatar;
    }
    return 'lib/assets/avatar/hairstyles/${type.name}_${hairstyle.name}.png';
  }

  static Future<AvatarResources> load([
    AvatarCharacterType type = AvatarCharacterType.hombre,
    AvatarHairstyle hairstyle = AvatarHairstyle.original,
  ]) => _cached[(type, hairstyle)] != null
      ? SynchronousFuture(_cached[(type, hairstyle)]!)
      : _pending[(type, hairstyle)] ??= _load(type, hairstyle);

  static Future<AvatarResources> _load(
    AvatarCharacterType type,
    AvatarHairstyle hairstyle,
  ) async {
    try {
      final program = await ui.FragmentProgram.fromAsset(
        'shaders/avatar_colors.frag',
      );
      final path = assetFor(type, hairstyle);
      final faces = await (_faces[type] ??= _loadFaces(type));
      return _cached[(type, hairstyle)] = AvatarResources(
        await _readImage(path),
        program,
        faces.$1,
        faces.$2,
      );
    } catch (_) {
      _pending.remove((type, hairstyle));
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
    child:
        AvatarResources.cachedFor(config.characterType, config.hairstyle) !=
            null
        ? _RenderedAvatar(
            key: ValueKey((config.characterType, config.hairstyle)),
            resources: AvatarResources.cachedFor(
              config.characterType,
              config.hairstyle,
            )!,
            config: config,
            portrait: portrait,
          )
        : FutureBuilder<AvatarResources>(
            key: ValueKey((config.characterType, config.hairstyle)),
            future: AvatarResources.load(
              config.characterType,
              config.hairstyle,
            ),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Image.asset(
                  AvatarResources.assetFor(
                    config.characterType,
                    config.hairstyle,
                  ),
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
    super.key,
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
            painter: _AvatarPainter(_shader, widget.resources, widget.config),
          ),
        ),
      ),
    );
  }
}

class _AvatarPainter extends CustomPainter {
  final ui.FragmentShader shader;
  final AvatarResources resources;
  final AvatarConfig config;
  _AvatarPainter(this.shader, this.resources, this.config);

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
    shader.setFloat(
      18,
      config.characterType == AvatarCharacterType.mujer ? 1 : 0,
    );
    shader.setFloat(19, config.eyes.index.toDouble());
    shader.setFloat(20, config.nose.index.toDouble());
    shader.setFloat(21, config.mouth.index.toDouble());
    shader.setImageSampler(0, resources.image);
    shader.setImageSampler(1, resources.faceA);
    shader.setImageSampler(2, resources.faceB);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_AvatarPainter oldDelegate) =>
      oldDelegate.config != config || oldDelegate.resources != resources;
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
