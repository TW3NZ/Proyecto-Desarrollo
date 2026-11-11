import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/usuario.dart';

/// Error de autenticación con un mensaje apto para mostrar al usuario.
class AuthApiException implements Exception {
  final String message;
  const AuthApiException(this.message);

  @override
  String toString() => message;
}

/// Resultado de un inicio de sesión exitoso.
class LoginResult {
  final String token;
  final Usuario usuario;
  const LoginResult(this.token, this.usuario);
}

/// Cliente HTTP de los endpoints de autenticación de FastAPI (`api/`).
///
/// Sigue el patrón de [AvatarPhotoService]: cliente inyectable, URL base por
/// `String.fromEnvironment('API_URL')`, timeout y mapeo de códigos a mensajes.
class AuthApiService {
  final http.Client _client;
  final String baseUrl;

  AuthApiService({
    http.Client? client,
    this.baseUrl = const String.fromEnvironment('API_URL'),
  }) : _client = client ?? http.Client();

  bool get configured => baseUrl.isNotEmpty;

  void close() => _client.close();

  Future<LoginResult> login(String identificador, String password) async {
    final uri = _uri('/auth/login/user');
    try {
      final response = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'identificador': identificador,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw AuthApiException(_mensajePorEstado(response.statusCode, 401));
      }
      final datos = jsonDecode(response.body);
      if (datos is! Map<String, dynamic>) {
        throw const AuthApiException('Respuesta del servidor no válida.');
      }
      final token = datos['access_token'];
      final usuario = datos['usuario'];
      if (token is! String || usuario is! Map<String, dynamic>) {
        throw const AuthApiException('Respuesta del servidor no válida.');
      }
      return LoginResult(token, Usuario.fromApiJson(usuario));
    } on AuthApiException {
      rethrow;
    } catch (_) {
      throw const AuthApiException(
        'No se pudo conectar con el servidor. Revisa tu conexión e inténtalo de nuevo.',
      );
    }
  }

  Future<void> registrar(Map<String, dynamic> cuerpo) async {
    final uri = _uri('/usuarios');
    try {
      final response = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(cuerpo),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 201) {
        throw AuthApiException(_mensajePorEstado(response.statusCode, null));
      }
    } on AuthApiException {
      rethrow;
    } catch (_) {
      throw const AuthApiException(
        'No se pudo conectar con el servidor. Revisa tu conexión e inténtalo de nuevo.',
      );
    }
  }

  Uri _uri(String ruta) {
    if (!configured) {
      throw const AuthApiException(
        'El servicio de autenticación no está configurado.',
      );
    }
    final uri = Uri.tryParse(
      '${baseUrl.replaceFirst(RegExp(r'/+$'), '')}$ruta',
    );
    if (uri == null ||
        !['http', 'https'].contains(uri.scheme) ||
        uri.host.isEmpty) {
      throw const AuthApiException('La dirección del servicio no es válida.');
    }
    return uri;
  }

  String _mensajePorEstado(int estado, int? estadoNoAutorizado) {
    if (estado == estadoNoAutorizado) {
      return 'Usuario o contraseña incorrectos.';
    }
    if (estado == 422) {
      return 'Datos no válidos. Revisa los campos e inténtalo de nuevo.';
    }
    return 'No se pudo completar la operación. Inténtalo de nuevo.';
  }
}
