import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Contrato para guardar y recuperar el JWT. Permite sustituir el
/// almacenamiento seguro por una implementación en memoria en las pruebas.
abstract class TokenStorage {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> delete();
}

/// Implementación por defecto con almacenamiento seguro de la plataforma
/// (Keystore en Android, Keychain en iOS).
class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'auth.jwt';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String token) => _storage.write(key: _key, value: token);

  @override
  Future<void> delete() => _storage.delete(key: _key);
}
