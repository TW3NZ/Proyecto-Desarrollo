enum Genero { hombre, mujer }

DateTime _fechaDesdeApi(Object? valor) {
  if (valor is String) {
    final fecha = DateTime.tryParse(valor);
    if (fecha != null) return fecha;
  }
  return DateTime.now();
}

String _fechaParaApi(DateTime fecha) {
  final anio = fecha.year.toString().padLeft(4, '0');
  final mes = fecha.month.toString().padLeft(2, '0');
  final dia = fecha.day.toString().padLeft(2, '0');
  return '$anio-$mes-$dia';
}

Genero _generoDesdeApi(Object? valor) =>
    valor == 'Mujer' ? Genero.mujer : Genero.hombre;

String _generoParaApi(Genero genero) =>
    genero == Genero.mujer ? 'Mujer' : 'Hombre';

Genero _generoDesdeNombre(Object? valor) =>
    valor == Genero.mujer.name ? Genero.mujer : Genero.hombre;

class Usuario {
  final int id;
  final String name;
  final String lastName;
  final String nickName;
  final String email;
  final String password;
  final DateTime createDate;
  final Genero genero;
  final String? photo;

  const Usuario({
    required this.id,
    required this.name,
    required this.lastName,
    required this.nickName,
    required this.email,
    required this.password,
    required this.createDate,
    this.genero = Genero.hombre,
    this.photo,
  });

  /// Construye un usuario desde la respuesta de login de FastAPI
  /// (`POST /auth/login/user`), que usa las claves de la tabla MySQL.
  factory Usuario.fromApiJson(Map<String, dynamic> json) => Usuario(
    id: json['idUsu'] as int,
    name: json['nameUsu'] as String,
    lastName: json['lastName'] as String,
    nickName: json['nickName'] as String,
    email: json['email'] as String,
    password: '',
    createDate: _fechaDesdeApi(json['createDate']),
    genero: _generoDesdeApi(json['genero']),
    photo: json['foto'] as String?,
  );

  /// Cuerpo para registrar en FastAPI (`POST /usuarios`). El ID lo genera el
  /// servidor, así que no se envía.
  Map<String, dynamic> toCreateUserJson() => {
    'name': name,
    'lastName': lastName,
    'nickName': nickName,
    'email': email,
    'password': password,
    'createDate': _fechaParaApi(createDate),
    'genero': _generoParaApi(genero),
    'foto': photo,
  };

  /// Perfil público persistido localmente (sin contraseña).
  Map<String, dynamic> toProfileJson() => {
    'id': id,
    'name': name,
    'lastName': lastName,
    'nickName': nickName,
    'email': email,
    'createDate': createDate.toIso8601String(),
    'genero': genero.name,
    'foto': photo,
  };

  factory Usuario.fromProfileJson(Map<String, dynamic> json) => Usuario(
    id: json['id'] as int,
    name: json['name'] as String,
    lastName: json['lastName'] as String,
    nickName: json['nickName'] as String,
    email: json['email'] as String,
    password: '',
    createDate:
        DateTime.tryParse(json['createDate'] as String? ?? '') ??
        DateTime.now(),
    genero: _generoDesdeNombre(json['genero']),
    photo: json['foto'] as String?,
  );
}
