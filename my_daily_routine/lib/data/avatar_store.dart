import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/avatar_config.dart';

/// Preferencia local del dispositivo; todavía no hay sesión de usuario persistente.
class AvatarStore extends ChangeNotifier {
  static final instancia = AvatarStore();
  static const preferenceKey = 'avatar.config.v1';

  final Future<String?> Function() _read;
  final Future<void> Function(String) _write;
  Future<void>? _loading;
  AvatarConfig _config = const AvatarConfig();
  bool loadFailed = false;

  AvatarStore({
    Future<String?> Function()? read,
    Future<void> Function(String)? write,
  }) : _read =
           read ?? (() => SharedPreferencesAsync().getString(preferenceKey)),
       _write =
           write ??
           ((value) =>
               SharedPreferencesAsync().setString(preferenceKey, value));

  AvatarConfig get config => _config;

  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    try {
      final raw = await _read();
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
    await load();
    await _write(jsonEncode(config.toJson()));
    _config = config;
    loadFailed = false;
    notifyListeners();
  }
}
