import 'package:flutter/material.dart';

void showAppSnackBar(
  BuildContext context, {
  String message = 'Próximamente',
  Duration duration = const Duration(seconds: 2),
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      duration: duration,
    ),
  );
}