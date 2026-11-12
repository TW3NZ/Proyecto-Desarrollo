import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/tarea_modelo.dart';

/// Error al crear una tarea, con un mensaje apto para mostrar al usuario.
class TareasApiException implements Exception {
  final String message;
  const TareasApiException(this.message);

  @override
  String toString() => message;
}

/// Cliente HTTP del endpoint de tareas de FastAPI (`POST /tareas`).
///
/// Sigue el patrón de [AuthApiService]: cliente inyectable, URL base por
/// `String.fromEnvironment('API_URL')`, timeout y mapeo de códigos a mensajes.
class TareasApiService {
  final http.Client _client;
  final String baseUrl;

  TareasApiService({
    http.Client? client,
    this.baseUrl = const String.fromEnvironment('API_URL'),
  }) : _client = client ?? http.Client();

  bool get configured => baseUrl.isNotEmpty;

  void close() => _client.close();

  /// Crea una tarea y devuelve el `idTarea` generado por el servidor.
  Future<int> crearTarea(
    Map<String, dynamic> cuerpo, {
    required String token,
  }) async {
    final uri = _uri('/tareas');
    try {
      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(cuerpo),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 201) {
        throw TareasApiException(_mensajePorEstado(response.statusCode));
      }
      final datos = jsonDecode(response.body);
      if (datos is! Map<String, dynamic> || datos['idTarea'] is! int) {
        throw const TareasApiException('Respuesta del servidor no válida.');
      }
      return datos['idTarea'] as int;
    } on TareasApiException {
      rethrow;
    } catch (_) {
      throw const TareasApiException(
        'No se pudo crear la tarea. Revisa tu conexión e inténtalo de nuevo.',
      );
    }
  }

  /// Marca una tarea como completada en el servidor.
  Future<void> completarTarea({
    required int idTarea,
    required String token,
  }) async {
    final uri = _uri('/tareas/$idTarea/completar');
    try {
      final response = await _client
          .patch(
            uri,
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw TareasApiException(_mensajePorEstado(response.statusCode));
      }
    } on TareasApiException {
      rethrow;
    } catch (_) {
      throw const TareasApiException(
        'No se pudo completar la tarea. Revisa tu conexión e inténtalo de nuevo.',
      );
    }
  }

  /// Obtiene las tareas del usuario autenticado.
  Future<List<NuevaTarea>> obtenerTareas({required String token}) async {
    final uri = _uri('/tareas');
    try {
      final response = await _client
          .get(
            uri,
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw TareasApiException(_mensajePorEstado(response.statusCode));
      }
      final datos = jsonDecode(response.body);
      if (datos is! List) {
        throw const TareasApiException('Respuesta del servidor no válida.');
      }
      final tareas = <NuevaTarea>[];
      for (final item in datos) {
        if (item is Map<String, dynamic>) {
          tareas.add(NuevaTarea.fromApiJson(item));
        }
      }
      return tareas;
    } on TareasApiException {
      rethrow;
    } catch (_) {
      throw const TareasApiException(
        'No se pudo obtener las tareas. Revisa tu conexión e inténtalo de nuevo.',
      );
    }
  }

  Uri _uri(String ruta) {
    if (!configured) {
      throw const TareasApiException(
        'El servicio de tareas no está configurado.',
      );
    }
    final uri = Uri.tryParse(
      '${baseUrl.replaceFirst(RegExp(r'/+$'), '')}$ruta',
    );
    if (uri == null ||
        !['http', 'https'].contains(uri.scheme) ||
        uri.host.isEmpty) {
      throw const TareasApiException('La dirección del servicio no es válida.');
    }
    return uri;
  }

  String _mensajePorEstado(int estado) {
    if (estado == 401) {
      return 'Sesión expirada. Inicia sesión de nuevo.';
    }
    if (estado == 422) {
      return 'Datos no válidos. Revisa los campos e inténtalo de nuevo.';
    }
    return 'No se pudo crear la tarea. Inténtalo de nuevo.';
  }
}
