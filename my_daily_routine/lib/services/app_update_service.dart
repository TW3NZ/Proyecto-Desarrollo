import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class AppUpdate {
  const AppUpdate({
    required this.build,
    required this.version,
    required this.sha256,
    required this.size,
    required this.url,
  });
  final int build, size;
  final String version, sha256, url;
  Map<String, dynamic> toJson() => {
    'build': build,
    'size': size,
    'sha256': sha256,
    'url': url,
  };

  factory AppUpdate.parse(Map<String, dynamic> json, String manifestUrl) {
    final uri = Uri.parse(manifestUrl);
    if (uri.scheme != 'https' ||
        uri.host != 'raw.githubusercontent.com' ||
        !uri.path.startsWith('/TW3NZ/Proyecto-Desarrollo/') ||
        !uri.path.endsWith('/app-update.json') ||
        uri.hasPort ||
        uri.userInfo.isNotEmpty) {
      throw const FormatException('Origen de actualización inválido.');
    }
    final build = json['build'];
    final size = json['size'];
    final hash = json['sha256'];
    final version = json['version'];
    if (json['schema'] != 1 ||
        json['abi'] != 'arm64-v8a' ||
        build is! int ||
        build < 1 ||
        size is! int ||
        size < 1 ||
        size > 150000000 ||
        hash is! String ||
        !RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(hash) ||
        version is! String ||
        version.length > 60) {
      throw const FormatException(
        'La publicación de la actualización no es válida.',
      );
    }
    return AppUpdate(
      build: build,
      size: size,
      version: version,
      sha256: hash,
      url: uri.resolve('my-daily-rutine-android-arm64.apk').toString(),
    );
  }
}

class AppUpdateService {
  AppUpdateService({http.Client? client, MethodChannel? channel})
    : _client = client ?? http.Client(),
      _channel = channel ?? const MethodChannel('my_daily_routine/updates');
  final http.Client _client;
  final MethodChannel _channel;
  void onProgress(void Function(double) callback) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'progress') {
        callback((call.arguments as num).toDouble());
      }
    });
  }

  Future<AppUpdate?> check() async {
    final installed = await _channel.invokeMapMethod<String, dynamic>(
      'installed',
    );
    if (installed == null || installed['arm64'] != true) return null;
    // Omitting ref follows GitHub's default branch, whether master or main.
    final response = await _client
        .get(
          Uri.parse(
            'https://api.github.com/repos/TW3NZ/Proyecto-Desarrollo/contents/app-update.json',
          ),
          headers: {
            'Accept': 'application/vnd.github+json',
            'Cache-Control': 'no-cache',
          },
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 404) return null; // First publication pending.
    if (response.statusCode != 200) {
      throw StateError('No se pudo consultar GitHub. Reintenta más tarde.');
    }
    final envelope = jsonDecode(response.body) as Map<String, dynamic>;
    if (envelope['encoding'] != 'base64') {
      throw const FormatException('Publicación inválida.');
    }
    final content = utf8.decode(
      base64Decode(
        (envelope['content'] as String).replaceAll(RegExp(r'\s'), ''),
      ),
    );
    final update = AppUpdate.parse(
      jsonDecode(content) as Map<String, dynamic>,
      envelope['download_url'] as String,
    );
    return update.build > (installed['build'] as num) ? update : null;
  }

  Future<void> download(AppUpdate update) async {
    await _channel.invokeMethod<String>('download', update.toJson());
  }

  Future<String?> install(AppUpdate update) =>
      _channel.invokeMethod<String>('install', update.toJson());
  void dispose() {
    _channel.setMethodCallHandler(null);
    _client.close();
  }
}
