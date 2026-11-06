enum Genero { hombre, mujer }

class Usuario {
  final String? id;
  final String name;
  final String lastName;
  final String nickName;
  final String email;
  final String password;
  final DateTime createDate;
  final Genero genero;
  final String? photo;

  const Usuario({
    this.id,
    required this.name,
    required this.lastName,
    required this.nickName,
    required this.email,
    required this.password,
    required this.createDate,
    this.genero = Genero.hombre,
    this.photo,
  });
}
