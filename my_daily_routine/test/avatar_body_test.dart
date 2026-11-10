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
  test('Proportions persist, migrate and survive other edits', () async {
    String? disk;
    final store = AvatarStore(
      read: () async => disk,
      write: (v) async => disk = v,
    );
    final config = const AvatarConfig()
        .copyWith(bodyWidth: 1.5, bodyHeight: 0.8)
        .withHairstyle(AvatarHairstyle.rizado)
        .withColor(AvatarPart.shirt, 'blue');
    await store.save(config);
    final reopened = AvatarStore(read: () async => disk, write: (_) async {});
    await reopened.load();
    expect(reopened.config.bodyWidth, 1.5);
    expect(AvatarConfig.fromJson({'bodyWidth': 1.2}).bodyWidth, 1.2);
    expect(reopened.config.bodyHeight, 0.8);
    expect(AvatarConfig.fromJson({}).bodyHeight, 1);
    expect(
      AvatarConfig.fromJson({'bodyWidth': double.nan, 'bodyHeight': 'bad'})
          .bodyWidth,
      1,
    );
    expect(
      AvatarConfig.fromJson({'bodyWidth': 8, 'bodyHeight': -2}).bodyHeight,
      0.8,
    );
    expect(config.copyWith(eyes: AvatarEyes.round).bodyWidth, 1.5);
    store.dispose();
    reopened.dispose();
  });

  testWidgets('Both characters visibly change width and height within canvas', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(240, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    Future<ByteData> render(AvatarConfig config, {bool face = false}) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: RepaintBoundary(
            key: key,
            child: face
                ? MaterialApp(
                    home: Scaffold(
                      body: SingleChildScrollView(
                        child: AvatarFaceSelector(
                          config: config,
                          onChanged: (_) {},
                        ),
                      ),
                    ),
                  )
                : AvatarCharacter(config: config),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return (await tester.runAsync(() async {
        final image =
            await (key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage();
        final data = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        image.dispose();
        return data;
      }))!;
    }

    int rowWidth(ByteData data, int y) {
      var count = 0;
      for (var x = 0; x < 240; x++) {
        if (data.getUint8((y * 240 + x) * 4 + 3) > 100) count++;
      }
      return count;
    }

    int top(ByteData data) {
      for (var y = 0; y < 480; y++) {
        if (rowWidth(data, y) > 2) return y;
      }
      return 480;
    }

    for (final type in AvatarCharacterType.values) {
      await tester.runAsync(() => AvatarResources.load(type));
      final config = AvatarConfig(characterType: type, motion: false);
      final slim = await render(config.copyWith(bodyWidth: 0.8));
      final wide = await render(config.copyWith(bodyWidth: 1.2));
      final widest = await render(config.copyWith(bodyWidth: 1.5));
      final short = await render(config.copyWith(bodyHeight: 0.8));
      expect(rowWidth(wide, 200), greaterThan(rowWidth(slim, 200)));
      expect(rowWidth(widest, 200), greaterThan(rowWidth(wide, 200)));
      expect(top(short), greaterThan(top(slim) + 60));
      expect(top(wide), top(slim));
      final face = await render(config, face: true);
      final shortFace = await render(
        config.copyWith(bodyHeight: 0.8, bodyWidth: 1.5),
        face: true,
      );
      expect(
        shortFace.buffer.asUint8List(),
        orderedEquals(face.buffer.asUint8List()),
        reason: 'The face editor must keep exactly the same framing at minimum height.',
      );
    }
  });
}
