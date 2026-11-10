import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/avatar_config.dart';
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
      appBar: AppBar(title: const Text('Avatar desde una foto')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Usa una foto de frente, con buena luz y una sola persona. El parecido depende de los rasgos disponibles; después podrás ajustarlos.',
          ),
          const SizedBox(height: 16),
          if (!_service.configured)
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                'La función de fotos aún no está configurada en esta versión.',
              ),
            ),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              if (camera)
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _pick(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Tomar foto'),
                ),
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _pick(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Elegir foto'),
              ),
            ],
          ),
          if (_photo != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.memory(
                _photo!,
                height: 220,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Text(
                  'No se puede mostrar esta foto. Elige otra en JPEG, PNG o WebP.',
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Al pulsar «Analizar foto», se enviará esta imagen a nuestro servidor y a OpenAI para sugerir los rasgos. Nuestro servidor no guarda la foto. OpenAI la procesa según sus políticas de datos. Usa una foto tuya o con permiso.',
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _busy || !_service.configured ? null : _analyze,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Analizar foto'),
            ),
          ],
          if (_busy)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  LinearProgressIndicator(),
                  SizedBox(height: 8),
                  Text('Preparando tu avatar…'),
                ],
              ),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(_error!, semanticsLabel: _error),
            ),
          if (_proposal != null) ...[
            const SizedBox(height: 16),
            const Text(
              'Tu propuesta',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            AvatarPreview(height: 300, config: _proposal!, reaction: 0),
            const SizedBox(height: 12),
            const Text(
              'Conservamos tu personaje y los atributos que no se distinguen. Puedes seguir editando; los cambios se guardan en la pantalla anterior.',
            ),
            FilledButton(
              onPressed: _busy ? null : () => Navigator.pop(context, _proposal),
              child: const Text('Usar propuesta'),
            ),
          ],
        ],
      ),
    );
  }
}
