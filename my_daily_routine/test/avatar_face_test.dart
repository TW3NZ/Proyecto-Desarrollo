import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_daily_routine/data/avatar_store.dart';
import 'package:my_daily_routine/models/avatar_config.dart';
import 'package:my_daily_routine/widgets/avatar/avatar_character.dart';
import 'package:my_daily_routine/widgets/avatar/avatar_face_selector.dart';

void main() {
  test('Rasgos independientes, migración y persistencia', () async {
    String? disk;
    final store = AvatarStore(
      read: () async => disk,
      write: (value) async => disk = value,
    );
    final config =
        const AvatarConfig(
              eyes: AvatarEyes.almond,
              nose: AvatarNose.round,
              mouth: AvatarMouth.smile,
            )
            .withColor(AvatarPart.skin, 'deep')
            .withHairstyle(AvatarHairstyle.rizado)
            .withCharacterType(AvatarCharacterType.mujer)
            .withMotion(false);
    await store.save(config);
    final reloaded = AvatarStore(read: () async => disk, write: (_) async {});
    await reloaded.load();
    expect(reloaded.config.toJson(), config.toJson());
    expect(jsonDecode(disk!)['eyes'], 'almond');
    final legacy = AvatarConfig.fromJson({
      'eyes': 'unknown',
      'nose': null,
      'shirt': 'blue',
    });
    expect(legacy.eyes, AvatarEyes.original);
    expect(legacy.nose, AvatarNose.original);
    expect(legacy.mouth, AvatarMouth.original);
    expect(legacy.shirt, 'blue');
    store.dispose();
    reloaded.dispose();
  });

  testWidgets('Cada rasgo cambia solo su zona para ambos personajes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(887, 1774);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    Future<ByteData> render(AvatarConfig config) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: RepaintBoundary(
            key: key,
            child: AvatarCharacter(config: config),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return (await tester.runAsync(() async {
        final image =
            await (key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage();
        final bytes = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        image.dispose();
        return bytes;
      }))!;
    }

    List<int> pixel(ByteData b, int x, int y) =>
        List.generate(4, (i) => b.getUint8((y * 887 + x) * 4 + i));
    int differences(ByteData a, ByteData b, Rect rect) {
      var n = 0;
      for (var y = rect.top.toInt(); y < rect.bottom; y++) {
        for (var x = rect.left.toInt(); x < rect.right; x++) {
          if (a.getUint32((y * 887 + x) * 4) !=
              b.getUint32((y * 887 + x) * 4)) {
            n++;
          }
        }
      }
      return n;
    }

    for (final type in AvatarCharacterType.values) {
      await tester.runAsync(
        () => AvatarResources.load(type, AvatarHairstyle.rizado),
      );
      final config = AvatarConfig(
        characterType: type,
        hairstyle: AvatarHairstyle.rizado,
        motion: false,
      );
      final original = await render(config);
      for (final eyes in AvatarEyes.values.skip(1)) {
        final result = await render(config.copyWith(eyes: eyes));
        expect(
          differences(
            original,
            result,
            const Rect.fromLTRB(390, 208, 561, 282),
          ),
          greaterThan(50),
        );
        expect(pixel(result, 505, 287), pixel(original, 505, 287));
        expect(pixel(result, 490, 320), pixel(original, 490, 320));
      }
      for (final nose in AvatarNose.values.skip(1)) {
        final result = await render(config.copyWith(nose: nose));
        expect(
          differences(
            original,
            result,
            const Rect.fromLTRB(480, 240, 530, 300),
          ),
          greaterThan(30),
        );
        expect(pixel(result, 438, 250), pixel(original, 438, 250));
        expect(pixel(result, 490, 320), pixel(original, 490, 320));
      }
      for (final mouth in AvatarMouth.values.skip(1)) {
        final result = await render(config.copyWith(mouth: mouth));
        expect(
          differences(
            original,
            result,
            const Rect.fromLTRB(444, 298, 538, 348),
          ),
          greaterThan(50),
        );
        expect(pixel(result, 438, 250), pixel(original, 438, 250));
        expect(pixel(result, 505, 287), pixel(original, 505, 287));
        expect(pixel(result, 440, 650), pixel(original, 440, 650));
        expect(pixel(result, 0, 0)[3], 0);
      }
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Selectores independientes en pantalla estrecha', (tester) async {
    await tester.runAsync(
      () => AvatarResources.load(AvatarCharacterType.mujer),
    );
    tester.view.physicalSize = const Size(320, 750);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var config = const AvatarConfig(
      characterType: AvatarCharacterType.mujer,
      hair: 'silver',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => ListView(
              children: [
                AvatarFaceSelector(
                  config: config,
                  onChanged: (next) => setState(() => config = next),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    for (final name in ['eyes-almond', 'nose-round', 'mouth-smile']) {
      final finder = find.byKey(ValueKey(name));
      await tester.scrollUntilVisible(finder, 150);
      await Scrollable.ensureVisible(tester.element(finder), alignment: 0.4);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }
    expect(config.eyes, AvatarEyes.almond);
    expect(config.nose, AvatarNose.round);
    expect(config.mouth, AvatarMouth.smile);
    expect(config.hair, 'silver');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Vista de combinaciones para revisión visual', (tester) async {
    for (final type in AvatarCharacterType.values) {
      await tester.runAsync(
        () => AvatarResources.load(type, AvatarHairstyle.recogido),
      );
    }
    tester.view.physicalSize = const Size(1000, 440);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: RepaintBoundary(
          key: key,
          child: ColoredBox(
            color: const Color(0xFFE3EAFF),
            child: Column(
              children: [
                for (final type in AvatarCharacterType.values)
                  Row(
                    children: [
                      for (final config in [
                        AvatarConfig(
                          characterType: type,
                          hairstyle: AvatarHairstyle.recogido,
                        ),
                        AvatarConfig(
                          characterType: type,
                          hairstyle: AvatarHairstyle.recogido,
                          eyes: AvatarEyes.almond,
                          nose: AvatarNose.straight,
                          mouth: AvatarMouth.smile,
                        ),
                        AvatarConfig(
                          characterType: type,
                          hairstyle: AvatarHairstyle.recogido,
                          eyes: AvatarEyes.round,
                          nose: AvatarNose.round,
                          mouth: AvatarMouth.neutral,
                        ),
                        AvatarConfig(
                          characterType: type,
                          hairstyle: AvatarHairstyle.recogido,
                          eyes: AvatarEyes.almond,
                          nose: AvatarNose.round,
                          mouth: AvatarMouth.smile,
                          skin: 'deep',
                          hair: 'silver',
                        ),
                      ])
                        SizedBox(
                          width: 250,
                          height: 220,
                          child: ClipRect(
                            child: OverflowBox(
                              alignment: Alignment.topCenter,
                              minWidth: 500,
                              maxWidth: 500,
                              minHeight: 1000,
                              maxHeight: 1000,
                              child: AvatarCharacter(config: config),
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final image =
          await (key.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary)
              .toImage();
      final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
      final file = File('build/avatar-faces-preview.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes.buffer.asUint8List());
      image.dispose();
    });
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
