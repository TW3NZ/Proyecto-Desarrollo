import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_daily_routine/data/token_storage.dart';
import 'package:my_daily_routine/data/usuarios_store.dart';
import 'package:my_daily_routine/main.dart';
import 'package:my_daily_routine/models/usuario.dart';
import 'package:my_daily_routine/screens/home.dart';
import 'package:my_daily_routine/screens/welcome.dart';
import 'package:my_daily_routine/services/auth_api_service.dart';
import 'package:my_daily_routine/widgets/avatar/avatar_character.dart';

class _MemoryTokenStorage implements TokenStorage {
  String? _token;

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> write(String token) async => _token = token;

  @override
  Future<void> delete() async => _token = null;
}

class _FakeAuthApi extends AuthApiService {
  _FakeAuthApi(this._usuario);

  final Usuario _usuario;

  @override
  Future<LoginResult> login(String identificador, String password) async =>
      LoginResult('token-de-prueba', _usuario);

  @override
  Future<void> registrar(Map<String, dynamic> cuerpo) async {}
}

void main() {
  setUp(() {
    UsuariosStore.api = AuthApiService();
    UsuariosStore.tokenStorage = _MemoryTokenStorage();
    UsuariosStore.readProfile = () async => null;
    UsuariosStore.writeProfile = (_) async {};
    UsuariosStore.removeProfile = () async {};
    UsuariosStore.cerrarSesion();
  });

  testWidgets('el inicio de sesión directo a Inicio no daña el árbol', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.runAsync(AvatarResources.load);
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    final campos = find.byType(TextField);
    await tester.enterText(campos.at(0), UsuariosStore.nickNamePractica);
    await tester.enterText(campos.at(1), UsuariosStore.passwordPractica);
    final iniciarSesion = find.text('Iniciar sesión');
    await tester.ensureVisible(iniciarSesion);
    await tester.tap(iniciarSesion);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('el inicio de sesión completa el tutorial sin errores de árbol', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.runAsync(AvatarResources.load);
    final usuario = Usuario(
      id: 990001,
      name: 'Usuario',
      lastName: 'Prueba',
      nickName: 'login_lifecycle_test',
      email: 'login.lifecycle@example.test',
      password: 'password-segura',
      createDate: DateTime(2026, 11, 9),
    );
    UsuariosStore.api = _FakeAuthApi(usuario);
    await UsuariosStore.registrar(usuario);

    await tester.pumpWidget(const MyApp());
    await tester.pump();
    final campos = find.byType(TextField);
    await tester.enterText(campos.at(0), 'login_lifecycle_test');
    await tester.enterText(campos.at(1), 'password-segura');
    final iniciarSesion = find.text('Iniciar sesión');
    await tester.ensureVisible(iniciarSesion);
    await tester.tap(iniciarSesion);
    await tester.pumpAndSettle();

    expect(find.byType(WelcomeScreen), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Comenzar'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
