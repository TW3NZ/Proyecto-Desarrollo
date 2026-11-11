import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/usuario.dart';
import '../services/auth_api_service.dart';
import '../utils/jwt.dart';
import 'id_temporal_store.dart';
import 'token_storage.dart';

/// Fachada de autenticación y directorio de usuarios en memoria.
///
/// Conserva la API pública que usan el resto de módulos (`usuarioActual`,
/// `buscarPorId`, `idUsuarioPractica`, `cerrarSesion`). Internamente delega el
/// login y el registro reales en [AuthApiService], guarda el JWT en
/// [TokenStorage] (almacenamiento seguro) y el perfil público en
/// SharedPreferences.
class UsuariosStore {
  UsuariosStore._();

  static const nickNamePractica = 'admin';
  static const passwordPractica = '12345678';
  static const int idUsuarioPractica = -1;

  static const _profileKey = 'usuario.actual.v1';

  static final Usuario _usuarioPractica = Usuario(
    id: idUsuarioPractica,
    name: 'Admin',
    lastName: 'Práctica',
    nickName: nickNamePractica,
    email: 'admin@mydailyroutine.local',
    password: passwordPractica,
    createDate: DateTime(2026, 1, 1),
  );

  static final List<Usuario> _usuarios = [_usuarioPractica];
  static String? _nickConTutorialPendiente;
  static int? _usuarioActualId;
  static String? _token;

  static Future<void> _pending = Future<void>.value();

  // Dependencias sustituibles en las pruebas.
  static AuthApiService api = AuthApiService();
  static TokenStorage tokenStorage = SecureTokenStorage();
  static Future<String?> Function() readProfile = () =>
      SharedPreferencesAsync().getString(_profileKey);
  static Future<void> Function(String) writeProfile = (value) =>
      SharedPreferencesAsync().setString(_profileKey, value);
  static Future<void> Function() removeProfile = () =>
      SharedPreferencesAsync().remove(_profileKey);

  static int generarIdTemporal() => IdTemporalStore.generar();

  static String? get token => _token;

  static bool consumirTutorialPendiente(String identificador) {
    final usuario = buscarPorIdentificador(identificador);
    if (usuario == null ||
        usuario.nickName.toLowerCase() !=
            _nickConTutorialPendiente?.toLowerCase()) {
      return false;
    }
    _nickConTutorialPendiente = null;
    return true;
  }

  static List<Usuario> get usuarios => List.unmodifiable(_usuarios);

  static Usuario? get usuarioActual =>
      _usuarioActualId == null ? null : buscarPorId(_usuarioActualId!);

  static Usuario? buscarPorIdentificador(String identificador) {
    final valor = identificador.trim().toLowerCase();
    for (final usuario in _usuarios) {
      if (usuario.nickName.toLowerCase() == valor ||
          usuario.email.toLowerCase() == valor) {
        return usuario;
      }
    }
    return null;
  }

  static Usuario? buscarPorId(int id) {
    for (final usuario in _usuarios) {
      if (usuario.id == id) return usuario;
    }
    return null;
  }

  static bool existeEmail(String email) =>
      _usuarios.any((u) => u.email.toLowerCase() == email.trim().toLowerCase());

  static bool existeNickName(String nickName) => _usuarios.any(
    (u) => u.nickName.toLowerCase() == nickName.trim().toLowerCase(),
  );

  /// Restaura la sesión al arrancar. Si el token está vencido, el perfil no se
  /// puede leer o ambos no son coherentes, limpia la persistencia por completo.
  static Future<void> load() async {
    await _pending;
    final token = await tokenStorage.read();
    if (token == null || token.isEmpty) return;
    if (tokenExpirado(token)) {
      await _borrarPersistencia();
      return;
    }
    final perfil = await _leerPerfil();
    if (perfil == null) {
      await _borrarPersistencia();
      return;
    }
    final sub = leerSub(token);
    if (sub == null || sub != perfil.id.toString()) {
      await _borrarPersistencia();
      return;
    }
    _establecerSesionApi(token, perfil);
  }

  /// Inicia sesión real contra FastAPI. La cuenta de práctica (solo desarrollo)
  /// no llama a la API ni escribe en el almacenamiento seguro.
  static Future<void> iniciarSesion(
    String identificador,
    String password,
  ) async {
    if (_esCuentaPractica(identificador, password)) {
      _establecerSesionPractica();
      return;
    }
    final resultado = await api.login(identificador.trim(), password);
    _establecerSesionApi(resultado.token, resultado.usuario);
    unawaited(_guardarPersistencia(resultado.token, resultado.usuario));
  }

  /// Registra un usuario en FastAPI. El ID lo genera el servidor.
  static Future<void> registrar(Usuario usuario) async {
    await api.registrar(usuario.toCreateUserJson());
    _nickConTutorialPendiente = usuario.nickName;
  }

  /// Autenticación síncrona de la cuenta de práctica (solo desarrollo).
  /// Mantenida por compatibilidad; la autenticación real es [iniciarSesion].
  static bool autenticar(String identificador, String password) {
    if (!_esCuentaPractica(identificador, password)) return false;
    _establecerSesionPractica();
    return true;
  }

  /// Cierra la sesión: borra el estado en memoria y, en segundo plano, el JWT
  /// del almacenamiento seguro y el perfil persistido. Solo toca el
  /// almacenamiento si había una sesión real persistida (la cuenta de práctica
  /// no persiste nada).
  static void cerrarSesion() {
    final habiaSesionPersistida = _token != null;
    _limpiarMemoria();
    if (habiaSesionPersistida) {
      unawaited(_borrarPersistencia());
    }
  }

  static bool _esCuentaPractica(String identificador, String password) {
    if (!kDebugMode || password != passwordPractica) return false;
    final valor = identificador.trim().toLowerCase();
    return valor == nickNamePractica.toLowerCase() ||
        valor == _usuarioPractica.email.toLowerCase();
  }

  static void _establecerSesionPractica() {
    _token = null;
    _usuarioActualId = idUsuarioPractica;
  }

  static void _establecerSesionApi(String token, Usuario usuario) {
    _token = token;
    _usuarios.removeWhere((u) => u.id == usuario.id);
    _usuarios.add(usuario);
    _usuarioActualId = usuario.id;
  }

  static void _limpiarMemoria() {
    _token = null;
    _usuarioActualId = null;
    _nickConTutorialPendiente = null;
    _usuarios.removeWhere((u) => u.id != idUsuarioPractica);
  }

  static Future<void> _guardarPersistencia(String token, Usuario usuario) {
    return _serializar(() async {
      await tokenStorage.write(token);
      await writeProfile(jsonEncode(usuario.toProfileJson()));
    });
  }

  static Future<void> _borrarPersistencia() {
    return _serializar(() async {
      await tokenStorage.delete();
      await removeProfile();
    });
  }

  static Future<Usuario?> _leerPerfil() async {
    try {
      final raw = await readProfile();
      if (raw == null) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return Usuario.fromProfileJson(decoded);
    } catch (_) {
      return null;
    }
  }

  /// Serializa las operaciones de persistencia para evitar condiciones de
  /// carrera entre el cierre de sesión y un nuevo inicio de sesión.
  static Future<void> _serializar(Future<void> Function() operacion) {
    final siguiente = _pending.then((_) => operacion());
    _pending = siguiente.catchError((Object _) {});
    return siguiente;
  }
}
