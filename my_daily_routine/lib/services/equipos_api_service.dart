import 'dart:convert';

import 'package:http/http.dart' as http;

class EquiposApiService {
  EquiposApiService({
    http.Client? client,
    this.baseUrl = const String.fromEnvironment('API_URL'),
  }) : _client = client ?? http.Client();
  final http.Client _client;
  final String baseUrl;

  Future<dynamic> request(
    String path,
    String token, {
    String method = 'GET',
    Map<String, dynamic>? data,
  }) async {
    if (baseUrl.isEmpty) {
      throw StateError('Servicio de equipos no configurado.');
    }
    final request = http.Request(
      method,
      Uri.parse('${baseUrl.replaceFirst(RegExp(r'/+$'), '')}/equipos$path'),
    );
    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });
    if (data != null) request.body = jsonEncode(data);
    final response = await _client
        .send(request)
        .then(http.Response.fromStream)
        .timeout(const Duration(seconds: 75));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'No se pudo conectar con equipos. Inténtalo de nuevo.';
      if (response.statusCode == 401) {
        message = 'Tu sesión expiró. Inicia sesión de nuevo.';
      } else if ([403, 404, 422].contains(response.statusCode)) {
        try {
          final detail = jsonDecode(response.body)['detail'];
          message = detail is String
              ? detail
              : 'Revisa los campos del formulario.';
        } catch (_) {
          /* A proxy may return HTML. */
        }
      }
      throw StateError(message);
    }
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  void close() => _client.close();
}
