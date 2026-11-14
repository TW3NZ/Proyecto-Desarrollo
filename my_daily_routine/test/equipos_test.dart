import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_daily_routine/data/usuarios_store.dart';
import 'package:my_daily_routine/screens/equipos_remotos.dart';
import 'package:my_daily_routine/services/equipos_api_service.dart';
import 'package:my_daily_routine/widgets/equipos/formulario_tarea_equipo.dart';

import 'perfil_remoto_test.dart' show LoginApi, MemoryToken;

void main() {
  test('API sends JWT and preserves server authorization errors', () async {
    final api = EquiposApiService(
      baseUrl: 'https://example.com/',
      client: MockClient((r) async {
        expect(r.url.path, '/equipos/unirse');
        expect(r.headers['Authorization'], 'Bearer token');
        expect(jsonDecode(r.body), {'codigo': 'ABCD2345'});
        return http.Response('{"detail":"No perteneces al equipo"}', 403);
      }),
    );
    await expectLater(
      api.request(
        '/unirse',
        'token',
        method: 'POST',
        data: {'codigo': 'ABCD2345'},
      ),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          'No perteneces al equipo',
        ),
      ),
    );
    api.close();
  });

  testWidgets('assignment requires selected members', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FormularioTareaEquipo(
            miembros: const [
              {'idUsu': 42, 'nickName': 'ana'},
            ],
          ),
        ),
      ),
    );
    await tester.enterText(
      find.byType(TextFormField).first,
      'Preparar entrega',
    );
    await tester.tap(find.text('Asignar'));
    await tester.pumpAndSettle();
    expect(
      find.text('Selecciona una categoría y al menos un participante.'),
      findsOneWidget,
    );
  });

  testWidgets('marking my part requires confirmation and waits for teammates', (
    tester,
  ) async {
    UsuariosStore.api = LoginApi();
    UsuariosStore.tokenStorage = MemoryToken();
    UsuariosStore.writeProfile = (_) async {};
    UsuariosStore.removeProfile = () async {};
    await UsuariosStore.iniciarSesion('42', 'test');
    var marked = false;
    var calls = 0;
    final api = EquiposApiService(
      baseUrl: 'https://example.com',
      client: MockClient((r) async {
        if (r.method == 'PATCH') {
          calls++;
          expect(r.url.path, '/equipos/7/tareas/9/mi-parte');
          marked = true;
          return http.Response(
            '{"completada":false,"miParteCompletada":true}',
            200,
          );
        }
        return http.Response(
          jsonEncode({
            'idEquipo': 7,
            'nombre': 'Equipo',
            'idCreador': 99,
            'codigo': null,
            'miembros': [
              {'idUsu': 42, 'nickName': 'ana'},
              {'idUsu': 99, 'nickName': 'luis'},
            ],
            'proyectos': [
              {'idProyecto': 8, 'nombre': 'Proyecto'},
            ],
            'tareas': [
              {
                'idTarea': 9,
                'idProyecto': 8,
                'titulo': 'Entrega',
                'descripcion': '',
                'prioridad': 'Media',
                'fechaFinalizacion': null,
                'completada': false,
                'categorias': [1],
                'participantes': [
                  {'idUsu': 42, 'nickName': 'ana', 'completada': marked},
                  {'idUsu': 99, 'nickName': 'luis', 'completada': false},
                ],
              },
            ],
          }),
          200,
        );
      }),
    );
    await tester.pumpWidget(
      MaterialApp(home: EquiposRemotosScreen(equipoId: 7, api: api)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Crear proyecto'), findsNothing);
    await tester.scrollUntilVisible(find.text('Marcar mi parte'), 300);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Marcar mi parte'));
    await tester.pumpAndSettle();
    expect(calls, 0);
    await tester.tap(find.text('Sí, terminé'));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(
      find.text('Tu parte está lista. Esperando al resto del equipo.'),
      findsOneWidget,
    );
    expect(find.text('Marcar mi parte'), findsNothing);
    UsuariosStore.cerrarSesion();
    await tester.pumpAndSettle();
    expect(find.text('Entrega'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
