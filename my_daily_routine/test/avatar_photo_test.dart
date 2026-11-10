import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_daily_routine/models/avatar_config.dart';
import 'package:my_daily_routine/screens/avatar_photo.dart';
import 'package:my_daily_routine/services/avatar_photo_service.dart';
import 'package:my_daily_routine/widgets/avatar/avatar_character.dart';

Map<String, dynamic> suggestion() => {
  'status': 'ok',
  'skin': 'brown',
  'hair': 'black',
  'shirt': null,
  'trousers': null,
  'hairstyle': 'rizado',
  'eyes': 'almond',
  'nose': 'straight',
  'mouth': 'smile',
};

class FakePicker extends ImagePicker {
  @override
  Future<LostDataResponse> retrieveLostData() async => LostDataResponse.empty();

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async => XFile.fromData(
    base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Wl6VbAAAAAASUVORK5CYII=',
    ),
    mimeType: 'image/png',
  );
}

void main() {
  test(
    'remote catalog preserves manual character, motion and invisible clothing',
    () {
      const current = AvatarConfig(
        characterType: AvatarCharacterType.mujer,
        motion: false,
        bodyWidth: 1.15,
        bodyHeight: 0.9,
        shirt: 'cream',
        trousers: 'olive',
      );
      final next = AvatarPhotoService.applySuggestion(suggestion(), current);
      expect(next.characterType, current.characterType);
      expect(next.motion, false);
      expect(next.bodyWidth, current.bodyWidth);
      expect(next.bodyHeight, current.bodyHeight);
      expect(next.shirt, 'cream');
      expect(next.trousers, 'olive');
      expect(next.hairstyle, AvatarHairstyle.rizado);
      expect(next.eyes, AvatarEyes.almond);
      expect(
        () => AvatarPhotoService.applySuggestion({
          ...suggestion(),
          'skin': 'unknown',
        }, current),
        throwsFormatException,
      );
      expect(
        () => AvatarPhotoService.applySuggestion({
          ...suggestion(),
          'status': 'multiple_faces',
        }, current),
        throwsA(isA<AvatarPhotoException>()),
      );
    },
  );

  test(
    'HTTP contract sends image and manual character to backend only',
    () async {
      final service = AvatarPhotoService(
        baseUrl: 'https://example.test/',
        token: 'a' * 24,
        client: MockClient((request) async {
          expect(request.url.path, '/avatar/suggest');
          expect(request.headers['Authorization'], 'Bearer ${'a' * 24}');
          final body = jsonDecode(request.body);
          expect(body['image_base64'], 'AQID');
          expect(body['character_type'], 'mujer');
          return http.Response(jsonEncode(suggestion()), 200);
        }),
      );
      addTearDown(service.close);
      final result = await service.suggest(
        Uint8List.fromList([1, 2, 3]),
        const AvatarConfig(characterType: AvatarCharacterType.mujer),
      );
      expect(result.skin, 'brown');
    },
  );

  test(
    'service handles auth failure, malformed output and size limits',
    () async {
      for (final response in [
        http.Response('', 401),
        http.Response('{}', 200),
      ]) {
        final service = AvatarPhotoService(
          baseUrl: 'https://example.test',
          token: 'a' * 24,
          client: MockClient((_) async => response),
        );
        addTearDown(service.close);
        await expectLater(
          service.suggest(Uint8List.fromList([1]), const AvatarConfig()),
          throwsA(isA<AvatarPhotoException>()),
        );
        await expectLater(
          service.suggest(Uint8List(4 * 1024 * 1024 + 1), const AvatarConfig()),
          throwsA(isA<AvatarPhotoException>()),
        );
      }
    },
  );

  testWidgets(
    'photo is sent only after Analyze and proposal requires acceptance',
    (tester) async {
      var requests = 0;
      AvatarConfig? accepted;
      final service = AvatarPhotoService(
        baseUrl: 'https://example.test',
        token: 'a' * 24,
        client: MockClient((_) async {
          requests++;
          return http.Response(jsonEncode(suggestion()), 200);
        }),
      );
      addTearDown(service.close);
      await tester.runAsync(
        () => AvatarResources.load(
          AvatarCharacterType.hombre,
          AvatarHairstyle.rizado,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  accepted = await Navigator.push<AvatarConfig>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AvatarPhotoScreen(
                        current: const AvatarConfig(motion: false),
                        service: service,
                        picker: FakePicker(),
                      ),
                    ),
                  );
                },
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Elegir foto'));
      await tester.pumpAndSettle();
      expect(requests, 0);
      expect(accepted, isNull);
      await tester.scrollUntilVisible(
        find.text('Analizar foto').hitTestable(),
        150,
      );
      await tester.tap(find.text('Analizar foto'));
      await tester.pumpAndSettle();
      expect(requests, 1);
      expect(accepted, isNull);
      await tester.scrollUntilVisible(
        find.text('Usar propuesta').hitTestable(),
        150,
      );
      await tester.tap(find.text('Usar propuesta'));
      await tester.pumpAndSettle();
      expect(accepted?.hairstyle, AvatarHairstyle.rizado);
    },
  );
}
