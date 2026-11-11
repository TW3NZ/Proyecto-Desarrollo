import 'dart:convert';

/// Utilidades para inspeccionar un JWT sin verificar su firma.
///
/// La aplicación nunca conoce el secreto del servidor, así que estas funciones
/// solo leen los claims en claro (`sub`, `exp`) para decidir la sesión local.
/// La autoridad real sigue siendo el backend.
Map<String, dynamic>? decodificarPayload(String token) {
  final partes = token.split('.');
  if (partes.length != 3) return null;
  final base64 = partes[1];
  final conPadding = base64.padRight(((base64.length + 3) ~/ 4) * 4, '=');
  try {
    final bytes = base64Url.decode(conPadding);
    final payload = jsonDecode(utf8.decode(bytes));
    return payload is Map<String, dynamic> ? payload : null;
  } catch (_) {
    return null;
  }
}

String? leerSub(String token) {
  final sub = decodificarPayload(token)?['sub'];
  return sub is String ? sub : null;
}

int? leerExpiracion(String token) {
  final exp = decodificarPayload(token)?['exp'];
  return exp is num ? exp.toInt() : null;
}

/// Devuelve `true` si el token está vencido o no se puede interpretar.
bool tokenExpirado(String token, {DateTime? ahora}) {
  final exp = leerExpiracion(token);
  if (exp == null) return true;
  final ahoraUtc = ahora ?? DateTime.now().toUtc();
  final ahoraSegundos = ahoraUtc.millisecondsSinceEpoch ~/ 1000;
  const margenSeguridad = 30;
  return exp <= ahoraSegundos + margenSeguridad;
}
