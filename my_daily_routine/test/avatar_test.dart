import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_daily_routine/data/avatar_store.dart';
import 'package:my_daily_routine/models/avatar_config.dart';
import 'package:my_daily_routine/screens/avatar.dart';
import 'package:my_daily_routine/widgets/avatar/avatar_character.dart';

void main() {
  test('Los colores guardados sobreviven a una nueva instancia', () async {
    String? disk;
    final store = AvatarStore(
      read: () async => disk,
      write: (value) async => disk = value,
    );
    final selected = const AvatarConfig()
        .withColor(AvatarPart.skin, 'deep')
        .withColor(AvatarPart.hair, 'silver')
        .withColor(AvatarPart.shirt, 'blue')
        .withColor(AvatarPart.trousers, 'sand')
        .withMotion(false);
    await store.save(selected);
    final reopened = AvatarStore(read: () async => disk, write: (_) async {});
    await reopened.load();
    expect(reopened.config.toJson(), selected.toJson());
    store.dispose();
    reopened.dispose();
  });

  test(
    'Datos inválidos se recuperan y un fallo de guardado no aplica el borrador',
    () async {
      final store = AvatarStore(
        read: () async => 'invalid json',
        write: (_) async => throw StateError('disk'),
      );
      await store.load();
      expect(store.loadFailed, isTrue);
      await expectLater(
        store.save(const AvatarConfig(shirt: 'blue')),
        throwsStateError,
      );
      expect(store.config.shirt, 'original');
      final decoded = AvatarConfig.fromJson(
        jsonDecode('{"skin":"unknown","motion":"invalid"}'),
      );
      expect(decoded.skin, 'original');
      expect(decoded.motion, isTrue);
      store.dispose();
    },
  );

  testWidgets(
    'El movimiento se detiene por preferencia, accesibilidad y TickerMode',
    (tester) async {
      Widget scene({
        bool motion = true,
        bool reduced = false,
        bool ticker = true,
      }) => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: TickerMode(
            enabled: ticker,
            child: AvatarMotion(
              enabled: motion,
              child: const SizedBox(width: 100, height: 200),
            ),
          ),
        ),
      );
      double scale() => tester
          .widget<Transform>(
            find.byKey(const ValueKey('avatar-motion-transform')),
          )
          .transform
          .entry(1, 1);
      await tester.pumpWidget(scene());
      await tester.pump(const Duration(seconds: 1));
      expect(scale(), greaterThan(1));
      await tester.pumpWidget(scene(reduced: true));
      await tester.pump(const Duration(seconds: 1));
      expect(scale(), 1);
      await tester.pumpWidget(scene(motion: false));
      await tester.pump(const Duration(seconds: 1));
      expect(scale(), 1);
      await tester.pumpWidget(scene(ticker: false));
      await tester.pump(const Duration(seconds: 1));
      expect(scale(), 1);
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'La recoloración cambia zonas independientes y conserva transparencia',
    (tester) async {
      await tester.runAsync(AvatarResources.load);
      tester.view.physicalSize = const Size(887, 1774);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final boundaryKey = GlobalKey();
      Future<ByteData> render(AvatarConfig config, {String? output}) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: RepaintBoundary(
              key: boundaryKey,
              child: AvatarCharacter(config: config),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final boundary =
            boundaryKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final bytes = await tester.runAsync(() async {
          final image = await boundary.toImage();
          final data = (await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!;
          if (output != null) {
            final png = (await image.toByteData(
              format: ui.ImageByteFormat.png,
            ))!;
            final file = File(output);
            await file.parent.create(recursive: true);
            await file.writeAsBytes(png.buffer.asUint8List());
          }
          image.dispose();
          return data;
        });
        return bytes!;
      }

      List<int> pixel(ByteData data, int x, int y) =>
          List.generate(4, (i) => data.getUint8((y * 887 + x) * 4 + i));
      final original = await render(const AvatarConfig());
      final shirt = await render(const AvatarConfig(shirt: 'coral'));
      expect(pixel(shirt, 440, 650), isNot(pixel(original, 440, 650)));
      expect(pixel(shirt, 450, 300), pixel(original, 450, 300));
      expect(pixel(shirt, 400, 1250), pixel(original, 400, 1250));
      final edited = await render(
        const AvatarConfig(
          skin: 'deep',
          hair: 'silver',
          shirt: 'blue',
          trousers: 'sand',
        ),
        output: 'build/avatar-preview.png',
      );
      for (final point in [
        const Offset(480, 90),
        const Offset(450, 300),
        const Offset(440, 650),
        const Offset(400, 1250),
      ]) {
        expect(
          pixel(edited, point.dx.toInt(), point.dy.toInt()),
          isNot(pixel(original, point.dx.toInt(), point.dy.toInt())),
        );
      }
      expect(pixel(edited, 0, 0)[3], 0);
      // El cabello no debe teñir el iris ni sus reflejos.
      expect(pixel(edited, 438, 250), pixel(original, 438, 250));
      expect(pixel(edited, 300, 1690), pixel(original, 300, 1690));
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('El editor descarta al volver y aplica solamente al guardar', (
    tester,
  ) async {
    await tester.runAsync(AvatarResources.load);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    String? disk;
    final store = AvatarStore(
      read: () async => disk,
      write: (value) async => disk = value,
    );
    await store.save(const AvatarConfig(motion: false));
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => AvatarScreen(store: store),
                ),
              ),
              child: const Text('Abrir avatar'),
            ),
          ),
        ),
      ),
    );
    Future<void> chooseBlue() async {
      await tester.tap(find.text('Abrir avatar'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Azul'), 160);
      await tester.drag(find.byType(ListView), const Offset(0, -220));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Azul'));
      await tester.pumpAndSettle();
    }

    await chooseBlue();
    expect(store.config.shirt, 'original');
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(store.config.shirt, 'original');
    await chooseBlue();
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();
    expect(store.config.shirt, 'blue');
    expect(jsonDecode(disk!)['shirt'], 'blue');
    expect(find.text('Abrir avatar'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    store.dispose();
  });
}
