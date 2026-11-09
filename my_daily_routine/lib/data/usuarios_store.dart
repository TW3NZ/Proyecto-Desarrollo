import '../models/usuario.dart';
import 'id_temporal_store.dart';

/// Repositorio en memoria; incluye una cuenta fija para las prácticas.
class UsuariosStore {
  UsuariosStore._();

  static const nickNamePractica = 'admin';
  static const passwordPractica = '12345678';
  static const int idUsuarioPractica = -1;

  static final Usuario _usuarioPractica = Usuario(
    id: idUsuarioPractica,
    name: 'Admin',
    lastName: 'Práctica',
    nickName: nickNamePractica,
    email: 'admin@mydailyroutine.local',
    password: passwordPractica,
    createDate: DateTime(2026, 1, 1),
  );

  static final List<Usuario> _usuarios = [_usuarioPractica];
  static String? _nickConTutorialPendiente;
  static int? _usuarioActualId;

  static int generarIdTemporal() => IdTemporalStore.generar();

  static bool consumirTutorialPendiente(String identificador) {
    final usuario = buscarPorIdentificador(identificador);
    if (usuario == null ||
        usuario.nickName.toLowerCase() !=
            _nickConTutorialPendiente?.toLowerCase()) {
      return false;
    }
    _nickConTutorialPendiente = null;
    return true;
  }

  static List<Usuario> get usuarios => List.unmodifiable(_usuarios);

  static Usuario? get usuarioActual =>
      _usuarioActualId == null ? null : buscarPorId(_usuarioActualId!);

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

  static Usuario? buscarPorId(int id) {
    for (final usuario in _usuarios) {
      if (usuario.id == id) return usuario;
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
    _nickConTutorialPendiente = usuario.nickName;
  }

  static bool autenticar(String identificador, String password) {
    final usuario = buscarPorIdentificador(identificador);
    if (usuario == null || usuario.password != password) return false;
    _usuarioActualId = usuario.id;
    return true;
  }

  static void cerrarSesion() {
    _usuarioActualId = null;
  }
}
