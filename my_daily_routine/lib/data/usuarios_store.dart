import '../models/usuario.dart';

/// Repositorio en memoria; sus datos viven mientras el proceso de la app siga abierto.
class UsuariosStore {
  UsuariosStore._();

  static final List<Usuario> _usuarios = [];

  static List<Usuario> get usuarios => List.unmodifiable(_usuarios);

  static Usuario? buscarPorIdentificador(String identificador) {
    final valor = identificador.trim().toLowerCase();
    for (final usuario in _usuarios) {
      if (usuario.nickName.toLowerCase() == valor ||
          usuario.email.toLowerCase() == valor) {
        return usuario;
      }
    }
    return null;
  }

  static bool existeEmail(String email) =>
      _usuarios.any((u) => u.email.toLowerCase() == email.trim().toLowerCase());

  static bool existeNickName(String nickName) => _usuarios.any(
    (u) => u.nickName.toLowerCase() == nickName.trim().toLowerCase(),
  );

  static void registrar(Usuario usuario) {
    if (existeEmail(usuario.email) || existeNickName(usuario.nickName)) {
      throw StateError('El correo o nombre de usuario ya está registrado.');
    }
    _usuarios.add(usuario);
  }

  static bool autenticar(String identificador, String password) {
    final usuario = buscarPorIdentificador(identificador);
    return usuario != null && usuario.password == password;
  }
}
