import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_daily_routine/data/avatar_store.dart';
import 'package:my_daily_routine/models/avatar_config.dart';
import 'package:my_daily_routine/widgets/avatar/avatar_color_picker.dart';

void main() {
  test(
    'Custom RGB colors survive persistence and reject invalid input',
    () async {
      String? disk;
      final store = AvatarStore(
        read: () async => disk,
        write: (v) async => disk = v,
      );
      final original = const AvatarConfig()
          .withColor(AvatarPart.shirt, '#00ff99')
          .withColor(AvatarPart.trousers, '#ff3377')
          .copyWith(eyeColor: '#abcdef');
      await store.save(original);
      final reopened = AvatarStore(read: () async => disk, write: (_) async {});
      await reopened.load();
      expect(reopened.config.shirt, '#00FF99');
      expect(reopened.config.trousers, '#FF3377');
      expect(reopened.config.eyeColor, '#ABCDEF');
      expect(
        reopened.config.option(AvatarPart.shirt).color,
        const Color(0xFF00FF99),
      );
      expect(
        original.withColor(AvatarPart.shirt, '#00000000').shirt,
        original.shirt,
      );
      expect(AvatarConfig.fromJson({'eyeColor': 'bad'}).eyeColor, 'original');
      expect(
        original.withHairstyle(AvatarHairstyle.rizado).eyeColor,
        '#ABCDEF',
      );
      store.dispose();
      reopened.dispose();
    },
  );

  testWidgets('Color dialog validates HEX and only commits on Apply', (
    tester,
  ) async {
    String? chosen;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                chosen = await pickAvatarColor(context, Colors.blue);
              },
              child: const Text('Color'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Color'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '#xx');
    await tester.pump();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    await tester.enterText(find.byType(TextField), '#eebbaa');
    await tester.pump();
    expect(chosen, isNull);
    await tester.tap(find.text('Aplicar color'));
    await tester.pumpAndSettle();
    expect(chosen, '#EEBBAA');
  });
}
