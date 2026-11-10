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
import 'package:my_daily_routine/widgets/avatar/avatar_hairstyle_selector.dart';

Future<void> preload() async {
  for (final type in AvatarCharacterType.values) {
    for (final style in AvatarHairstyle.values) {
      await AvatarResources.load(type, style);
    }
  }
}

void main() {
  testWidgets(
    'Los ocho recursos tienen transparencia y admiten color de cabello sin teñir ojos',
    (tester) async {
      await tester.runAsync(preload);
      tester.view.physicalSize = const Size(887, 1774);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final boundaryKey = GlobalKey();
      Future<ByteData> render(AvatarConfig config) async {
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
        return (await tester.runAsync(() async {
          final boundary =
              boundaryKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await boundary.toImage();
          final data = (await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!;
          image.dispose();
          return data;
        }))!;
      }

      List<int> pixel(ByteData data, int x, int y) =>
          List.generate(4, (i) => data.getUint8((y * 887 + x) * 4 + i));
      for (final type in AvatarCharacterType.values) {
        for (final style in AvatarHairstyle.values) {
          final resources = AvatarResources.cachedFor(type, style)!;
          expect(resources.image.width, 887);
          expect(resources.image.height, 1774);
          final config = AvatarConfig(
            characterType: type,
            hairstyle: style,
            motion: false,
          );
          final original = await render(config);
          final silver = await render(
            config.withColor(AvatarPart.hair, 'silver'),
          );
          expect(pixel(original, 0, 0)[3], 0);
          expect(pixel(original, 420, 120)[3], greaterThan(200));
          expect(
            pixel(silver, 420, 120),
            isNot(pixel(original, 420, 120)),
            reason: '${type.name}/${style.name} cabello',
          );
          expect(
            pixel(silver, 438, 250),
            pixel(original, 438, 250),
            reason: 'ojos',
          );
          expect(
            pixel(silver, 440, 650),
            pixel(original, 440, 650),
            reason: 'camiseta',
          );
        }
      }
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'El peinado se previsualiza, se descarta y se guarda con los colores',
    (tester) async {
      await tester.runAsync(preload);
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      String? disk;
      final store = AvatarStore(
        read: () async => disk,
        write: (value) async => disk = value,
      );
      await store.save(
        const AvatarConfig(shirt: 'blue', hair: 'silver', motion: false),
      );
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
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );
      Future<void> select() async {
        await tester.tap(find.text('Abrir'));
        await tester.pumpAndSettle();
        final tile = find.byKey(const ValueKey('hairstyle-rizado'));
        await tester.scrollUntilVisible(tile, 180);
        await Scrollable.ensureVisible(tester.element(tile), alignment: 0.3);
        await tester.pumpAndSettle();
        await tester.tap(tile);
        await tester.pumpAndSettle();
        final config = tester
            .widget<AvatarHairstyleSelector>(
              find.byType(AvatarHairstyleSelector),
            )
            .config;
        expect(config.hairstyle, AvatarHairstyle.rizado);
        expect(config.shirt, 'blue');
        expect(config.hair, 'silver');
      }

      await select();
      expect(store.config.hairstyle, AvatarHairstyle.original);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(store.config.hairstyle, AvatarHairstyle.original);
      await select();
      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();
      expect(jsonDecode(disk!)['hairstyle'], 'rizado');
      final reloaded = AvatarStore(read: () async => disk, write: (_) async {});
      await reloaded.load();
      expect(reloaded.config.hairstyle, AvatarHairstyle.rizado);
      expect(
        reloaded.config.withCharacterType(AvatarCharacterType.mujer).hairstyle,
        AvatarHairstyle.rizado,
      );
      await tester.pumpWidget(const SizedBox());
      store.dispose();
      reloaded.dispose();
    },
  );

  testWidgets('Miniaturas seleccionables en pantalla estrecha', (tester) async {
    tester.view.physicalSize = const Size(320, 750);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RepaintBoundary(
            key: key,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: AvatarHairstyleSelector(
                config: const AvatarConfig(
                  characterType: AvatarCharacterType.mujer,
                ),
                onSelected: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(() async {
      for (final style in AvatarHairstyle.values) {
        await precacheImage(
          AssetImage(
            AvatarResources.assetFor(AvatarCharacterType.mujer, style),
          ),
          tester.element(find.byType(AvatarHairstyleSelector)),
        );
      }
    });
    await tester.pumpAndSettle();
    expect(find.byType(InkWell), findsNWidgets(4));
    expect(tester.takeException(), isNull);
    await tester.runAsync(() async {
      final image =
          await (key.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary)
              .toImage();
      final data = (await image.toByteData(format: ui.ImageByteFormat.png))!;
      final file = File('build/hairstyles-selector.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(data.buffer.asUint8List());
      image.dispose();
    });
    await tester.pumpWidget(const SizedBox());
  });
}
