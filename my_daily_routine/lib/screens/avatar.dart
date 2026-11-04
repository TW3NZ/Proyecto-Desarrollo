import 'package:flutter/material.dart';

import '../data/avatar_store.dart';
import '../models/avatar_config.dart';
import '../theme.dart';
import '../widgets/avatar/avatar_character.dart';

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
      await AvatarResources.load();
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

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tu avatar'),
          actions: [
            TextButton(
              onPressed: _ready && !_saving
                  ? () => setState(() => _draft = const AvatarConfig())
                  : null,
              child: const Text('Restablecer'),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: FilledButton.icon(
            onPressed: _ready && !_saving ? _save : null,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded),
            label: Text(_saving ? 'Guardando…' : 'Guardar cambios'),
          ),
        ),
        body: !_ready
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
                absorbing: _saving,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  children: [
                    Container(
                      height: (MediaQuery.sizeOf(context).height * 0.36).clamp(
                        200.0,
                        320.0,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3EAFF),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: AvatarMotion(
                          enabled: _draft.motion,
                          reaction: _reaction,
                          child: AvatarCharacter(config: _draft),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Hazlo tuyo',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    const Text(
                      'Prueba tus colores antes de guardar.',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                    if (_store.loadFailed)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'No pudimos recuperar tu última elección. Puedes guardar una nueva.',
                        ),
                      ),
                    for (final part in AvatarPart.values) _palette(part),
                    const Divider(height: 28),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Movimiento suave'),
                      subtitle: Text(
                        reducedMotion
                            ? 'Pausado por la opción de movimiento reducido del dispositivo.'
                            : 'Un movimiento sutil de reposo.',
                      ),
                      value: _draft.motion,
                      onChanged: (value) =>
                          setState(() => _draft = _draft.withMotion(value)),
                    ),
                    OutlinedButton.icon(
                      onPressed: _draft.motion && !reducedMotion
                          ? () => setState(() => _reaction++)
                          : null,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Probar reacción suave'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _palette(AvatarPart part) {
    final title = switch (part) {
      AvatarPart.skin => 'Tono de piel',
      AvatarPart.hair => 'Color de cabello',
      AvatarPart.shirt => 'Camiseta',
      AvatarPart.trousers => 'Pantalón',
    };
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in avatarPalettes[part]!)
                ChoiceChip(
                  label: Text(option.label),
                  avatar: CircleAvatar(
                    backgroundColor: option.color,
                    radius: 10,
                  ),
                  selected: _draft.selection(part) == option.id,
                  onSelected: (_) => setState(
                    () => _draft = _draft.withColor(part, option.id),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
