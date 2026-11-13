import 'dart:convert';

import 'package:http/http.dart' as http;

/// Personal data is always scoped by the server to the JWT owner.
class PerfilApiService {
  PerfilApiService({
    http.Client? client,
    this.baseUrl = const String.fromEnvironment('API_URL'),
  }) : _client = client ?? http.Client();
  final http.Client _client;
  final String baseUrl;

  Future<Map<String, dynamic>> request(
    String path,
    String token, {
    Map<String, dynamic>? data,
  }) async {
    if (baseUrl.isEmpty) throw StateError('Servicio de perfil no configurado.');
    final uri = Uri.parse(
      '${baseUrl.replaceFirst(RegExp(r'/+$'), '')}/usuarios/me/$path',
    );
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    final response =
        await (data == null
                ? _client.get(uri, headers: headers)
                : _client.put(uri, headers: headers, body: jsonEncode(data)))
            .timeout(const Duration(seconds: 75));
    if (response.statusCode != 200) {
      throw StateError(
        response.statusCode == 401
            ? 'Sesión expirada. Inicia sesión de nuevo.'
            : 'No se pudo sincronizar tu perfil. Inténtalo de nuevo.',
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
