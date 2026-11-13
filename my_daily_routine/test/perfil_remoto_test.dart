import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_daily_routine/data/avatar_store.dart';
import 'package:my_daily_routine/data/tareas_store.dart';
import 'package:my_daily_routine/data/token_storage.dart';
import 'package:my_daily_routine/data/usuarios_store.dart';
import 'package:my_daily_routine/models/avatar_config.dart';
import 'package:my_daily_routine/models/usuario.dart';
import 'package:my_daily_routine/services/auth_api_service.dart';
import 'package:my_daily_routine/services/perfil_api_service.dart';
import 'package:my_daily_routine/services/tareas_api_service.dart';

class MemoryToken implements TokenStorage {
  @override
  Future<void> delete() async {}
  @override
  Future<String?> read() async => null;
  @override
  Future<void> write(String token) async {}
}

class LoginApi extends AuthApiService {
  @override
  Future<LoginResult> login(String identificador, String password) async {
    final id = int.parse(identificador);
    return LoginResult(
      '$id',
      Usuario(
        id: id,
        name: 'Test',
        lastName: 'User',
        nickName: '$id',
        email: '$id@example.com',
        password: '',
        createDate: DateTime(2026),
      ),
    );
  }
}

void main() {
  setUp(() async {
    UsuariosStore.api = LoginApi();
    UsuariosStore.tokenStorage = MemoryToken();
    UsuariosStore.writeProfile = (_) async {};
    UsuariosStore.removeProfile = () async {};
    await UsuariosStore.iniciarSesion('42', 'test');
  });
  tearDown(UsuariosStore.cerrarSesion);

  test('avatar survives a new store and remains isolated by account', () async {
    final saved = <String, Map<String, dynamic>>{};
    final api = PerfilApiService(
      baseUrl: 'https://example.com',
      client: MockClient((r) async {
        final account = r.headers['Authorization']!;
        if (r.method == 'PUT') saved[account] = jsonDecode(r.body);
        return http.Response(
          jsonEncode(saved[account] ?? const AvatarConfig().toJson()),
          200,
        );
      }),
    );
    var writes = 0;
    final store = AvatarStore(
      api: api,
      read: () async => throw StateError('No local reads'),
      write: (_) async {
        writes++;
      },
    );
    await store.save(
      const AvatarConfig(hairstyle: AvatarHairstyle.rizado, shirt: '#ABCDEF'),
    );
    final reopened = AvatarStore(api: api);
    await reopened.load();
    expect(reopened.config.hairstyle, AvatarHairstyle.rizado);
    expect(writes, 0);
    await UsuariosStore.iniciarSesion('99', 'test');
    expect(store.config.hairstyle, AvatarHairstyle.original);
    await reopened.load();
    expect(reopened.config.shirt, 'original');
    store.dispose();
    reopened.dispose();
  });

  test('late avatar response from previous account is discarded', () async {
    final pending = Completer<http.Response>();
    final store = AvatarStore(
      api: PerfilApiService(
        baseUrl: 'https://example.com',
        client: MockClient((_) => pending.future),
      ),
    );
    final loading = store.load();
    await UsuariosStore.iniciarSesion('99', 'test');
    pending.complete(
      http.Response(
        jsonEncode(
          const AvatarConfig(hairstyle: AvatarHairstyle.recogido).toJson(),
        ),
        200,
      ),
    );
    await loading;
    expect(store.config.hairstyle, AvatarHairstyle.original);
    store.dispose();
  });

  test(
    'real task history is fetched from API without device persistence',
    () async {
      final store = TareasStore(
        read: () async => throw StateError('No local reads'),
        write: (_) async => fail('Real tasks must not be persisted locally'),
        publishWidget: (_) async {},
        api: TareasApiService(
          baseUrl: 'https://example.com',
          client: MockClient((r) async {
            expect(r.headers['Authorization'], 'Bearer 42');
            return http.Response(
              jsonEncode([
                {
                  'idTarea': 8,
                  'idUsu': 42,
                  'Titulo': 'Restored',
                  'Prioridad': 'Baja',
                  'Completada': true,
                  'categorias': [1],
                  'Fecha': '2026-11-13',
                },
              ]),
              200,
            );
          }),
        ),
      );
      await store.load();
      expect(store.tareas.single.completada, true);
      await UsuariosStore.iniciarSesion('99', 'test');
      expect(store.tareas, isEmpty);
      store.dispose();
    },
  );
}
