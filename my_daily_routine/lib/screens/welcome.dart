import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../assets_paths.dart';
import '../routes.dart';
import '../theme.dart';

class WelcomeArguments {
  const WelcomeArguments({required this.mostrarTutorial});

  final bool mostrarTutorial;
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required this.arguments});

  static const _anchoOriginal = 852.0;
  static const _altoOriginal = 1846.0;

  final WelcomeArguments arguments;

  void _continuar(BuildContext context) {
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.home,
      arguments: arguments.mostrarTutorial,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final escala = math.min(
              constraints.maxWidth / _anchoOriginal,
              constraints.maxHeight / _altoOriginal,
            );
            final ancho = _anchoOriginal * escala;
            final alto = _altoOriginal * escala;

            return Center(
              child: SizedBox(
                width: ancho,
                height: alto,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(AppAssets.welcome, fit: BoxFit.fill),
                    ),
                    Positioned(
                      left: ancho * 0.09,
                      top: alto * 0.844,
                      width: ancho * 0.82,
                      height: alto * 0.08,
                      child: Semantics(
                        button: true,
                        label: 'Comenzar',
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            customBorder: const StadiumBorder(),
                            onTap: () => _continuar(context),
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
