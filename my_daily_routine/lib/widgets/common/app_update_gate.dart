import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/app_update_service.dart';
import '../../theme.dart';

/// A non-blocking notice shared by login and all authenticated screens.
class AppUpdateGate extends StatefulWidget {
  const AppUpdateGate({
    super.key,
    required this.child,
    this.service,
    this.enabled,
  });
  final Widget child;
  final AppUpdateService? service;
  final bool? enabled;
  @override
  State<AppUpdateGate> createState() => _AppUpdateGateState();
}

class _AppUpdateGateState extends State<AppUpdateGate>
    with WidgetsBindingObserver {
  late final _service = widget.service ?? AppUpdateService();
  AppUpdate? _update;
  DateTime? _lastCheck;
  bool _checking = false, _busy = false, _ready = false, _hidden = false;
  double _progress = 0;
  String? _message;
  bool get _enabled =>
      widget.enabled ??
      (!kIsWeb &&
          kReleaseMode &&
          defaultTargetPlatform == TargetPlatform.android);
  @override
  void initState() {
    super.initState();
    if (_enabled) {
      WidgetsBinding.instance.addObserver(this);
      _service.onProgress((value) {
        if (mounted) setState(() => _progress = value.clamp(0, 1));
      });
      _check();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        !_busy &&
        (_lastCheck == null ||
            DateTime.now().difference(_lastCheck!) >
                const Duration(hours: 6))) {
      _check();
    }
  }

  Future<void> _check() async {
    if (_checking) return;
    _checking = true;
    _lastCheck = DateTime.now();
    try {
      final update = await _service.check();
      if (mounted && update != null && update.build != _update?.build) {
        setState(() {
          _update = update;
          _hidden = false;
          _ready = false;
          _message = null;
        });
      }
    } catch (_) {
      /* Offline or rate-limited: keep the app usable. Retry on resume. */
    } finally {
      _checking = false;
    }
  }

  Future<void> _action() async {
    if (_busy || _update == null) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      if (!_ready) {
        await _service.download(_update!);
        if (!mounted) return;
        setState(() => _ready = true);
      }
      final status = await _service.install(_update!);
      if (mounted) {
        setState(
          () => _message = status == 'permission'
              ? 'Permite instalar desde My Daily Routine, regresa y pulsa Instalar.'
              : 'Confirma la actualización en el instalador de Android.',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _ready = false;
          _progress = 0;
          _message = e is PlatformException
              ? e.message
              : 'No se pudo descargar. Revisa tu conexión y reintenta.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    if (_enabled) {
      WidgetsBinding.instance.removeObserver(this);
      _service.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_update == null || _hidden) return widget.child;
    return Column(
      children: [
        Material(
          color: AppColors.background,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.system_update, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Nueva versión ${_update!.version}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Más tarde',
                        onPressed: _busy
                            ? null
                            : () => setState(() => _hidden = true),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  if (_busy)
                    LinearProgressIndicator(value: _ready ? null : _progress),
                  if (_message != null) Text(_message!),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _busy
                              ? 'Descargando y verificando… ${(_progress * 100).round()}%'
                              : '${(_update!.size / 1000000).toStringAsFixed(1)} MB · Conserva tus datos',
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _busy ? null : _action,
                        child: Text(_ready ? 'Instalar' : 'Descargar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(child: widget.child),
      ],
    );
  }
}
