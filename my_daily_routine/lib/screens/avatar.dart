import 'package:flutter/material.dart';

import '../data/avatar_store.dart';
import '../models/avatar_config.dart';
import '../theme.dart';
import 'avatar_photo.dart';
import '../widgets/avatar/avatar_motion_controls.dart';
import '../widgets/avatar/avatar_palette_section.dart';
import '../widgets/avatar/avatar_character.dart';
import '../widgets/avatar/avatar_preview.dart';
import '../widgets/avatar/avatar_hairstyle_selector.dart';
import '../widgets/avatar/avatar_face_selector.dart';
import '../widgets/common/cabecera_app.dart';
import '../widgets/common/primary_button.dart';

class AvatarScreen extends StatefulWidget {
  final AvatarStore? store;
  const AvatarScreen({super.key, this.store});

  @override
  State<AvatarScreen> createState() => _AvatarScreenState();
}

class _AvatarScreenState extends State<AvatarScreen> {
  AvatarStore get _store => widget.store ?? AvatarStore.instancia;
  AvatarConfig _draft = const AvatarConfig();
  bool _ready = false;
  bool _saving = false;
  bool _changingAppearance = false;
  String? _error;
  int _reaction = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      await _store.load();
      await AvatarResources.load(
        _store.config.characterType,
        _store.config.hairstyle,
      );
      if (!mounted) return;
      setState(() {
        _draft = _store.config;
        _ready = true;
      });
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _error = 'No pudimos cargar la vista previa. Inténtalo de nuevo.',
        );
      }
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _store.save(_draft);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudieron guardar los cambios. Inténtalo de nuevo.',
          ),
        ),
      );
    }
  }

  Future<void> _changeAppearance(AvatarConfig next) async {
    if (_changingAppearance || _saving) return;
    setState(() => _changingAppearance = true);
    try {
      await AvatarResources.load(next.characterType, next.hairstyle);
      if (mounted) setState(() => _draft = next);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo cargar el avatar. Inténtalo de nuevo.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _changingAppearance = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: SizedBox(
            height: 54,
            width: double.infinity,
            child: Stack(
              children: [
                Positioned.fill(
                  child: PrimaryButton(
                    text: _saving ? 'Guardando…' : 'Guardar cambios',
                    onPressed: _ready && !_saving && !_changingAppearance
                        ? _save
                        : null,
                  ),
                ),
                if (_saving)
                  const Positioned(
                    left: 24,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        body: Column(
          children: [
            CabeceraApp(
              titulo: 'Tu avatar',
              alVolver: () => Navigator.of(context).maybePop(),
              accionDerecha: TextButton(
                onPressed: _ready && !_saving && !_changingAppearance
                    ? () => _changeAppearance(const AvatarConfig())
                    : null,
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                child: const Text('Restablecer'),
              ),
            ),
            Expanded(
              child: !_ready
                  ? Center(
                      child: _error == null
                          ? const CircularProgressIndicator()
                          : Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(_error!, textAlign: TextAlign.center),
                                  TextButton(
                                    onPressed: _load,
                                    child: const Text('Reintentar'),
                                  ),
                                ],
                              ),
                            ),
                    )
                  : AbsorbPointer(
                      absorbing: _saving || _changingAppearance,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                        children: [
                          AvatarPreview(
                            height: (MediaQuery.sizeOf(context).height * 0.36)
                                .clamp(200.0, 320.0),
                            config: _draft,
                            reaction: _reaction,
                          ),
                          SizedBox(
                            height: 4,
                            child: _changingAppearance
                                ? const LinearProgressIndicator(
                                    semanticsLabel: 'Cargando avatar',
                                  )
                                : null,
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.add_a_photo_outlined),
                            label: const Text('Crear desde una foto'),
                            onPressed: () async {
                              final next = await Navigator.push<AvatarConfig>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AvatarPhotoScreen(current: _draft),
                                ),
                              );
                              if (next != null && mounted) {
                                await _changeAppearance(next);
                              }
                            },
                          ),
                          const Text(
                            'Personaje',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              for (final type in AvatarCharacterType.values)
                                ChoiceChip(
                                  label: Text(
                                    type == AvatarCharacterType.hombre
                                        ? 'Hombre'
                                        : 'Mujer',
                                  ),
                                  selected: _draft.characterType == type,
                                  onSelected: (_) => _changeAppearance(
                                    _draft.withCharacterType(type),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          AvatarHairstyleSelector(
                            config: _draft,
                            onSelected: (style) =>
                                _changeAppearance(_draft.withHairstyle(style)),
                          ),
                          const SizedBox(height: 16),
                          AvatarFaceSelector(
                            config: _draft,
                            onChanged: _changeAppearance,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Hazlo tuyo',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                            ),
                          ),
                          const Text(
                            'Combina tus rasgos, peinado y colores antes de guardar.',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                          if (_store.loadFailed)
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text(
                                'No pudimos recuperar tu última elección. Puedes guardar una nueva.',
                              ),
                            ),
                          for (final part in AvatarPart.values)
                            AvatarPaletteSection(
                              part: part,
                              selectedId: _draft.selection(part),
                              onSelected: (colorId) => setState(
                                () => _draft = _draft.withColor(part, colorId),
                              ),
                            ),
                          const Divider(height: 28),
                          AvatarMotionControls(
                            motionEnabled: _draft.motion,
                            reducedMotion: reducedMotion,
                            onMotionChanged: (value) => setState(
                              () => _draft = _draft.withMotion(value),
                            ),
                            onTryReaction: () => setState(() => _reaction++),
                          ),
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
