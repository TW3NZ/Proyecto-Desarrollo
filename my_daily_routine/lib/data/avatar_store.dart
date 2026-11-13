import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/avatar_config.dart';
import '../services/perfil_api_service.dart';
import 'usuarios_store.dart';

/// Apariencia por cuenta en MySQL; preferencias locales solo para práctica.
class AvatarStore extends ChangeNotifier {
  static final instancia = AvatarStore();
  static const preferenceKey = 'avatar.config.v1';

  final PerfilApiService _api;
  final Future<String?> Function() _read;
  final Future<void> Function(String) _write;
  Future<void>? _loading;
  AvatarConfig _config = const AvatarConfig();
  bool loadFailed = false;

  AvatarStore({
    PerfilApiService? api,
    Future<String?> Function()? read,
    Future<void> Function(String)? write,
  }) : _api = api ?? PerfilApiService(),
       _read =
           read ?? (() => SharedPreferencesAsync().getString(preferenceKey)),
       _write =
           write ??
           ((value) =>
               SharedPreferencesAsync().setString(preferenceKey, value)) {
    UsuariosStore.sessionVersion.addListener(_reset);
  }

  void _reset() {
    _loading = null;
    _config = const AvatarConfig();
    loadFailed = false;
    notifyListeners();
  }

  @override
  void dispose() {
    UsuariosStore.sessionVersion.removeListener(_reset);
    super.dispose();
  }

  AvatarConfig get config => _config;

  Future<void> load() => _loading ??= _load();

  bool get _remote => (UsuariosStore.usuarioActual?.id ?? -1) > 0;

  Future<void> _load() async {
    final epoch = UsuariosStore.sessionVersion.value;
    if (_remote) {
      try {
        final data = await _api.request('avatar', UsuariosStore.token!);
        if (epoch != UsuariosStore.sessionVersion.value) return;
        _config = AvatarConfig.fromJson(data);
        loadFailed = false;
      } catch (_) {
        if (epoch == UsuariosStore.sessionVersion.value) {
          loadFailed = true;
          _loading = null;
        }
        rethrow;
      }
      notifyListeners();
      return;
    }
    try {
      final raw = await _read();
      if (epoch != UsuariosStore.sessionVersion.value) return;
      if (raw != null) {
        final decoded = jsonDecode(raw);
        if (decoded is! Map<String, dynamic>) throw const FormatException();
        _config = AvatarConfig.fromJson(decoded);
      }
    } catch (_) {
      loadFailed = true;
    }
    notifyListeners();
  }

  /// Publicar el cambio solamente después de que el guardado termine bien.
  Future<void> save(AvatarConfig config) async {
    final epoch = UsuariosStore.sessionVersion.value;
    final token = UsuariosStore.token;
    final remote = _remote;
    await load();
    if (epoch != UsuariosStore.sessionVersion.value) {
      throw StateError('Sesion cambiada.');
    }
    if (remote) {
      await _api.request('avatar', token!, data: config.toJson());
    } else {
      await _write(jsonEncode(config.toJson()));
    }
    if (epoch != UsuariosStore.sessionVersion.value) return;
    _config = config;
    loadFailed = false;
    notifyListeners();
  }
}
