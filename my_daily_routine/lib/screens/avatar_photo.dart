import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/avatar_config.dart';
import '../theme.dart';
import '../widgets/common/cabecera_app.dart';
import '../services/avatar_photo_service.dart';
import '../widgets/avatar/avatar_character.dart';
import '../widgets/avatar/avatar_preview.dart';

class AvatarPhotoScreen extends StatefulWidget {
  final AvatarConfig current;
  final AvatarPhotoService? service;
  final ImagePicker? picker;
  const AvatarPhotoScreen({
    super.key,
    required this.current,
    this.service,
    this.picker,
  });

  @override
  State<AvatarPhotoScreen> createState() => _AvatarPhotoScreenState();
}

class _AvatarPhotoScreenState extends State<AvatarPhotoScreen> {
  late final _service = widget.service ?? AvatarPhotoService();
  late final _picker = widget.picker ?? ImagePicker();
  Uint8List? _photo;
  AvatarConfig? _proposal;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) _recover();
  }

  Future<void> _recover() async {
    setState(() => _busy = true);
    try {
      final lost = await _picker.retrieveLostData();
      if (lost.files?.isNotEmpty == true) {
        await _read(lost.files!.first);
      } else if (lost.exception != null && mounted) {
        setState(
          () => _error = 'No pudimos recuperar la foto. Elígela de nuevo.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'No pudimos recuperar la foto. Elígela de nuevo.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _read(XFile file) async {
    if (await file.length() > 4 * 1024 * 1024) {
      throw const AvatarPhotoException('Elige una foto de hasta 4 MB.');
    }
    final bytes = await file.readAsBytes();
    if (mounted) {
      setState(() {
        _photo = bytes;
        _proposal = null;
      });
    }
  }

  Future<void> _pick(ImageSource source) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final file = await _picker.pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
        requestFullMetadata: false,
      );
      if (file != null) await _read(file);
    } on AvatarPhotoException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'No pudimos abrir la cámara o las fotos. Revisa los permisos del dispositivo.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _analyze() async {
    setState(() {
      _busy = true;
      _error = null;
      _proposal = null;
    });
    try {
      final next = await _service.suggest(_photo!, widget.current);
      await AvatarResources.load(next.characterType, next.hairstyle);
      if (mounted) setState(() => _proposal = next);
    } on AvatarPhotoException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _error = 'No pudimos preparar la propuesta. Inténtalo de nuevo.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    if (widget.service == null) _service.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final camera =
        kIsWeb ||
        [
          TargetPlatform.android,
          TargetPlatform.iOS,
        ].contains(defaultTargetPlatform);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          CabeceraApp(
            titulo: 'Tu foto',
            alVolver: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                children: [
                  const Text(
                    'Un avatar más como tú',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Empieza con una foto. Después, dale tu toque personal.',
                    style: TextStyle(color: AppColors.textMuted, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  _PhotoPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _SectionLabel(
                          number: '1',
                          title: 'Elige tu foto',
                        ),
                        const SizedBox(height: 16),
                        Container(
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: AppColors.fieldFill,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.fieldBorder),
                          ),
                          child: _photo == null
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 20,
                                    horizontal: 16,
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.add_a_photo_outlined,
                                        size: 42,
                                        color: AppColors.primary,
                                      ),
                                      SizedBox(height: 10),
                                      Text(
                                        'Tu próxima versión empieza aquí',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Image.memory(
                                  _photo!,
                                  height: 220,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, _, _) => const Padding(
                                    padding: EdgeInsets.all(20),
                                    child: Text(
                                      'No se puede mostrar esta foto. Elige otra en JPEG, PNG o WebP.',
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          alignment: WrapAlignment.center,
                          children: [
                            if (camera)
                              OutlinedButton.icon(
                                style: _sourceButtonStyle,
                                onPressed: _busy
                                    ? null
                                    : () => _pick(ImageSource.camera),
                                icon: const Icon(
                                  Icons.camera_alt_outlined,
                                  size: 20,
                                ),
                                label: const Text('Tomar foto'),
                              ),
                            OutlinedButton.icon(
                              style: _sourceButtonStyle,
                              onPressed: _busy
                                  ? null
                                  : () => _pick(ImageSource.gallery),
                              icon: const Icon(
                                Icons.photo_library_outlined,
                                size: 20,
                              ),
                              label: const Text('Elegir foto'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'De frente · Buena luz · Solo tú',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!_service.configured) ...[
                    const _PhotoNotice(
                      icon: Icons.info_outline_rounded,
                      text: 'El servicio de fotos no estú configurado en esta instalación. Inicia la app con la configuración de fotos habilitada para analizar tu imagen.',
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_photo != null) ...[
                    _PhotoPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _SectionLabel(
                            number: '2',
                            title: 'Encuentra tus rasgos',
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Te propondremos una combinación de peinado, colores y rasgos. El parecido depende de las opciones disponibles.',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const _PhotoNotice(
                            icon: Icons.lock_outline_rounded,
                            text: 'Al pulsar «Analizar foto», enviarás la imagen a nuestro servidor y a OpenAI. Nuestro servidor no guarda la foto; OpenAI la procesa según sus políticas de datos. Usa una foto tuya o con permiso.',
                          ),
                          const SizedBox(height: 18),
                          _PhotoAction(
                            label: 'Analizar foto',
                            icon: Icons.auto_awesome_rounded,
                            onPressed: _busy || !_service.configured
                                ? null
                                : _analyze,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_busy) ...[
                    const _PhotoPanel(
                      child: Column(
                        children: [
                          LinearProgressIndicator(
                            color: AppColors.primary,
                            backgroundColor: AppColors.fieldBorder,
                          ),
                          SizedBox(height: 14),
                          Text(
                            'Preparando tu avatar…',
                            style: TextStyle(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_error != null) ...[
                    Semantics(
                      liveRegion: true,
                      child: _PhotoNotice(
                        icon: Icons.error_outline_rounded,
                        text: _error!,
                        isError: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_proposal != null)
                    _PhotoPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _SectionLabel(
                            number: '3',
                            title: 'Tu propuesta',
                          ),
                          const SizedBox(height: 16),
                          AvatarPreview(
                            height: 300,
                            config: _proposal!,
                            reaction: 0,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '¡Ahora dale tu toque!',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Conservamos tu personaje y los atributos que no se distinguen. Puedes seguir editando antes de guardar en la pantalla anterior.',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 18),
                          _PhotoAction(
                            label: 'Usar propuesta',
                            icon: Icons.check_rounded,
                            onPressed: _busy
                                ? null
                                : () => Navigator.pop(context, _proposal),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  ButtonStyle get _sourceButtonStyle => OutlinedButton.styleFrom(
    foregroundColor: AppColors.primary,
    side: const BorderSide(color: AppColors.fieldBorder),
    backgroundColor: AppColors.fieldFill,
    minimumSize: const Size(0, 48),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.button),
    ),
  );
}

class _PhotoPanel extends StatelessWidget {
  final Widget child;
  const _PhotoPanel({required this.child});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppColors.fieldBorder),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.06),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: child,
  );
}

class _SectionLabel extends StatelessWidget {
  final String number;
  final String title;
  const _SectionLabel({required this.number, required this.title});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          gradient: AppGradients.logo,
          shape: BoxShape.circle,
        ),
        child: Text(
          number,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
      ),
    ],
  );
}

class _PhotoNotice extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isError;
  const _PhotoNotice({
    required this.icon,
    required this.text,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isError
        ? Theme.of(context).colorScheme.error
        : AppColors.textMuted;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isError
            ? Theme.of(context).colorScheme.errorContainer
            : AppColors.fieldFill,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontSize: 13, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  const _PhotoAction({required this.label, required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: onPressed == null ? null : AppGradients.primary,
      color: onPressed == null ? AppColors.divider : null,
      borderRadius: BorderRadius.circular(AppRadius.button),
      boxShadow: onPressed == null
          ? []
          : [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.2),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
    ),
    child: FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: Colors.transparent,
        disabledBackgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        disabledForegroundColor: AppColors.textMuted,
        shadowColor: Colors.transparent,
        minimumSize: const Size(double.infinity, 54),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    ),
  );
}
