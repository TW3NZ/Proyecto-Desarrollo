import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_daily_routine/data/estadisticas_store.dart';
import 'package:my_daily_routine/data/usuarios_store.dart';
import 'package:my_daily_routine/models/avatar_config.dart';
import 'package:my_daily_routine/models/avatar_expression.dart';
import 'package:my_daily_routine/models/tarea_modelo.dart';
import 'package:my_daily_routine/widgets/avatar/avatar_character.dart';
import 'package:my_daily_routine/widgets/home/home_scene.dart';

void main() {
  test('Expression thresholds and disabled categories', () {
    expect(AvatarExpression.fromProgress(0), AvatarExpression.tired);
    expect(AvatarExpression.fromProgress(24.9), AvatarExpression.tired);
    expect(AvatarExpression.fromProgress(25), AvatarExpression.bored);
    expect(AvatarExpression.fromProgress(50), AvatarExpression.neutral);
    expect(AvatarExpression.fromProgress(75), AvatarExpression.happy);
    expect(AvatarExpression.fromProgress(100), AvatarExpression.happy);
    expect(
      AvatarExpression.fromProgress(0, hasActiveStats: false),
      AvatarExpression.neutral,
    );
  });

  testWidgets(
    'Home reacts to earned points and keeps user statistics separate',
    (tester) async {
      UsuariosStore.autenticar('admin', '12345678');
      final store = EstadisticasStore.instancia;
      final stats = store.actual;
      stats.inteligencia = 70;
      stats.finanzasActiva = false;
      stats.saludActiva = false;
      stats.disciplinaActiva = false;
      addTearDown(() {
        stats.inteligencia = 0;
        stats.finanzasActiva = stats.saludActiva = stats.disciplinaActiva =
            true;
        UsuariosStore.cerrarSesion();
      });
      await tester.runAsync(() => AvatarResources.load());
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: AvatarSlot())),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        tester.widget<AvatarCharacter>(find.byType(AvatarCharacter)).expression,
        AvatarExpression.neutral,
      );
      NuevaTarea task(int user) => NuevaTarea(
        id: -700,
        usuarioId: user,
        titulo: 'Prueba',
        categorias: {CategoriaTarea.educacion},
        prioridad: PrioridadTarea.baja,
      );
      store.procesarTareaCompletada(task(-99999));
      await tester.pump();
      expect(stats.inteligencia, 70);
      store.procesarTareaCompletada(task(UsuariosStore.idUsuarioPractica));
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        tester.widget<AvatarCharacter>(find.byType(AvatarCharacter)).expression,
        AvatarExpression.happy,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('Expressions change only the face for both characters', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(240, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    Future<ByteData> render(
      AvatarConfig config,
      AvatarExpression expression,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RepaintBoundary(
            key: key,
            child: AvatarCharacter(config: config, expression: expression),
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

    for (final type in AvatarCharacterType.values) {
      await tester.runAsync(() => AvatarResources.load(type));
      final config = AvatarConfig(
        characterType: type,
        motion: false,
        eyeColor: '#00BCD4',
      );
      final original = await render(config, AvatarExpression.neutral);
      final before = config.toJson();
      for (final expression in [
        AvatarExpression.happy,
        AvatarExpression.bored,
        AvatarExpression.tired,
      ]) {
        final changed = await render(config, expression);
        var faceChanges = 0;
        for (var y = 0; y < 480; y++) {
          for (var x = 0; x < 240; x++) {
            final i = (y * 240 + x) * 4;
            if (original.getUint32(i) != changed.getUint32(i)) {
              expect(y, lessThan(100));
              faceChanges++;
            }
          }
        }
        expect(faceChanges, greaterThan(10));
      }
      expect(config.toJson(), before);
    }
  });

  testWidgets('Expression review sheet', (tester) async {
    tester.view.physicalSize = const Size(960, 500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final type in AvatarCharacterType.values) {
      await tester.runAsync(() => AvatarResources.load(type));
    }
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
                      for (final expression in AvatarExpression.values)
                        SizedBox(
                          width: 240,
                          height: 250,
                          child: Column(
                            children: [
                                Text(expression.label, style: const TextStyle(fontSize: 16, color: Colors.black)),
                              SizedBox(
                                height: 210,
                                child: ClipRect(
                                  child: OverflowBox(
                                    alignment: Alignment.topCenter,
                                    minWidth: 480,
                                    maxWidth: 480,
                                    minHeight: 960,
                                    maxHeight: 960,
                                    child: AvatarCharacter(
                                      config: AvatarConfig(
                                        characterType: type,
                                        motion: false,
                                      ),
                                      portrait: true,
                                      expression: expression,
                                    ),
                                  ),
                                ),
                              ),
                            ],
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
      final data = (await image.toByteData(format: ui.ImageByteFormat.png))!;
      await File('build/avatar-expressions-preview.png')
          .writeAsBytes(data.buffer.asUint8List());
      image.dispose();
    });
  });
}
