import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_daily_routine/services/app_update_service.dart';
import 'package:my_daily_routine/widgets/common/app_update_gate.dart';

const url =
    'https://raw.githubusercontent.com/TW3NZ/Proyecto-Desarrollo/main/app-update.json';
final manifest = {
  'schema': 1,
  'abi': 'arm64-v8a',
  'version': '0.3.0',
  'build': 3,
  'size': 50000000,
  'sha256': 'a' * 64,
};

class FakeUpdater extends AppUpdateService {
  int downloads = 0, installs = 0;
  bool fail = false;
  @override
  void onProgress(void Function(double) callback) {}
  @override
  Future<AppUpdate?> check() async => AppUpdate.parse(manifest, url);
  @override
  Future<void> download(AppUpdate update) async {
    downloads++;
    if (fail) throw StateError('offline');
  }

  @override
  Future<String?> install(AppUpdate update) async {
    installs++;
    return installs == 1 ? 'permission' : 'installer';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('test/updates');
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );
  test('default branch lookup detects only newer builds and resolves APK in that branch', () async {
    var installed = 2;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (call) async => {'build': installed, 'arm64': true},
        );
    final service = AppUpdateService(
      channel: channel,
      client: MockClient((request) async {
        expect(request.url.queryParameters.containsKey('ref'), false);
        expect(request.headers.containsKey('Authorization'), false);
        return http.Response(
          jsonEncode({
            'encoding': 'base64',
            'content': base64Encode(utf8.encode(jsonEncode(manifest))),
            'download_url': url,
          }),
          200,
        );
      }),
    );
    final update = await service.check();
    expect(update!.build, 3);
    expect(
      update.url,
      'https://raw.githubusercontent.com/TW3NZ/Proyecto-Desarrollo/main/my-daily-rutine-android-arm64.apk',
    );
    installed = 3;
    expect(await service.check(), null);
    installed = 4;
    expect(await service.check(), null);
    service.dispose();
  });
  test('rejects foreign repository, non-HTTPS and malformed checksum', () {
    for (final address in [
      url.replaceFirst('https:', 'http:'),
      url.replaceFirst('TW3NZ', 'attacker'),
    ]) {
      expect(() => AppUpdate.parse(manifest, address), throwsFormatException);
    }
    expect(
      () => AppUpdate.parse({...manifest, 'sha256': 'bad'}, url),
      throwsFormatException,
    );
    expect(
      () => AppUpdate.parse({...manifest, 'size': 200000000}, url),
      throwsFormatException,
    );
  });
  test('missing first manifest is not an update', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (call) async => {'build': 2, 'arm64': true},
        );
    final service = AppUpdateService(
      channel: channel,
      client: MockClient((_) async => http.Response('', 404)),
    );
    expect(await service.check(), null);
    service.dispose();
  });
  testWidgets(
    'download requires a tap; returning from permission does not download twice',
    (tester) async {
      final service = FakeUpdater();
      await tester.pumpWidget(
        MaterialApp(
          home: AppUpdateGate(
            service: service,
            enabled: true,
            child: const Scaffold(body: Text('App')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(service.downloads, 0);
      await tester.tap(find.text('Descargar'));
      await tester.pumpAndSettle();
      expect(service.downloads, 1);
      expect(find.textContaining('Permite instalar'), findsOneWidget);
      await tester.tap(find.text('Instalar'));
      await tester.pumpAndSettle();
      expect(service.downloads, 1);
      expect(service.installs, 2);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('failed download can retry without blocking the app', (
    tester,
  ) async {
    final service = FakeUpdater()..fail = true;
    await tester.pumpWidget(
      MaterialApp(
        home: AppUpdateGate(
          service: service,
          enabled: true,
          child: const Scaffold(body: Text('App')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Descargar'));
    await tester.pumpAndSettle();
    expect(service.installs, 0);
    expect(find.text('App'), findsOneWidget);
    expect(find.text('Descargar'), findsOneWidget);
    await tester.tap(find.byTooltip('Más tarde'));
    await tester.pumpAndSettle();
    expect(find.text('Descargar'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
