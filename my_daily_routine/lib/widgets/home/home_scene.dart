import 'package:flutter/material.dart';

// La "escena" del Home: fondo + espacio del avatar.

/// Fondo a pantalla completa. Muestra la imagen número [index] de [paths] y
/// hace un fundido suave cuando cambia. Si la lista está vacía o la imagen no
/// carga, muestra un degradado azul de respaldo.
class HomeBackground extends StatelessWidget {
  final List<String> paths;
  final int index;

  const HomeBackground({super.key, required this.paths, required this.index});

  Widget _placeholder() => const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF9DB8FF), Color(0xFF3F5FE0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SizedBox.expand(),
      );

  @override
  Widget build(BuildContext context) {
    final Widget child = paths.isEmpty
        ? _placeholder()
        : Image.asset(
            paths[index % paths.length],
            key: ValueKey(index),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, _, _) => _placeholder(),
          );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      child: child,
    );
  }
}

/// Espacio reservado para el avatar (imagen o GIF) que va sobre el fondo.
///
/// Todavía no está definido cómo se cargará, así que mientras [asset] sea null
/// solo reserva el espacio (invisible). Cuando haya ruta, `Image.asset`
/// reproduce tanto PNG como GIF animados.
///
/// TODO: aquí se conectará el avatar definitivo (y su animación).
class AvatarSlot extends StatelessWidget {
  final String? asset;

  const AvatarSlot({super.key, this.asset});

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final width = screen.width * 0.62;
    final height = screen.height * 0.5;

    if (asset == null) {
      return SizedBox(width: width, height: height);
    }

    return SizedBox(
      width: width,
      height: height,
      child: Image.asset(
        asset!,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      ),
    );
  }
}
