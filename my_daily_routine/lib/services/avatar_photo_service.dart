import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../models/avatar_config.dart';

class AvatarPhotoException implements Exception {
  final String message;
  const AvatarPhotoException(this.message);
  @override
  String toString() => message;
}

class AvatarPhotoService {
  final http.Client _client;
  final String baseUrl;
  final String token;

  AvatarPhotoService({
    http.Client? client,
    this.baseUrl = const String.fromEnvironment('AVATAR_API_URL'),
    this.token = const String.fromEnvironment('AVATAR_API_TOKEN'),
  }) : _client = client ?? http.Client();

  bool get configured => baseUrl.isNotEmpty && token.length >= 24;

  void close() => _client.close();

  Future<AvatarConfig> suggest(Uint8List photo, AvatarConfig current) async {
    if (!configured) {
      throw const AvatarPhotoException(
        'La función de fotos aún no está configurada.',
      );
    }
    if (photo.isEmpty || photo.length > 4 * 1024 * 1024) {
      throw const AvatarPhotoException('Elige una foto de hasta 4 MB.');
    }
    final uri = Uri.tryParse(
      '${baseUrl.replaceFirst(RegExp(r'/+$'), '')}/avatar/suggest',
    );
    if (uri == null ||
        !['http', 'https'].contains(uri.scheme) ||
        uri.host.isEmpty) {
      throw const AvatarPhotoException(
        'La dirección del servicio no es válida.',
      );
    }
    try {
      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'image_base64': base64Encode(photo),
              'character_type': current.characterType.name,
            }),
          )
          .timeout(const Duration(seconds: 60));
      if (response.statusCode != 200) {
        throw AvatarPhotoException(switch (response.statusCode) {
          401 =>
            'El acceso al servicio de fotos no está configurado correctamente.',
          413 => 'La foto es demasiado grande. Elige otra.',
          422 => 'No pudimos analizar esa foto. Prueba con una foto clara en JPEG, PNG o WebP.',
          429 => 'Servicio ocupado o sin cuota. Inténtalo más tarde.',
          503 => 'El servicio de fotos aún no está configurado.',
          _ => 'No se pudo analizar la foto. Inténtalo de nuevo.',
        });
      }
      return applySuggestion(
        jsonDecode(response.body) as Map<String, dynamic>,
        current,
      );
    } on AvatarPhotoException {
      rethrow;
    } catch (_) {
      throw const AvatarPhotoException(
        'No pudimos completar el análisis. Revisa la conexión e inténtalo de nuevo.',
      );
    }
  }

  /// Reject unknown remote values; null keeps the user's existing choice.
  static AvatarConfig applySuggestion(
    Map<String, dynamic> data,
    AvatarConfig current,
  ) {
    if (data['status'] != 'ok') {
      throw AvatarPhotoException(switch (data['status']) {
        'no_face' => 'No encontramos un rostro. Prueba con una foto de frente.',
        'multiple_faces' => 'Elige una foto en la que aparezcas solo tú.',
        'unclear' => 'El rostro no se ve con claridad. Prueba con más luz.',
        _ => 'El servicio devolvió una propuesta inválida.',
      });
    }
    var next = current;
    for (final part in AvatarPart.values) {
      if (!data.containsKey(part.name)) {
        throw const FormatException('Missing color');
      }
      final value = data[part.name];
      if (value == null) continue;
      if (!avatarPalettes[part]!.any((option) => option.id == value)) {
        throw const FormatException('Unknown color');
      }
      next = next.withColor(part, value as String);
    }
    T? read<T extends Enum>(String key, List<T> values) {
      if (!data.containsKey(key)) {
        throw const FormatException('Missing attribute');
      }
      if (data[key] == null) return null;
      return values.firstWhere((value) => value.name == data[key]);
    }

    return next.copyWith(
      hairstyle: read('hairstyle', AvatarHairstyle.values),
      eyes: read('eyes', AvatarEyes.values),
      nose: read('nose', AvatarNose.values),
      mouth: read('mouth', AvatarMouth.values),
    );
  }
}
