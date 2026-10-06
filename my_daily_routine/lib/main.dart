import 'package:flutter/material.dart';
import 'package:my_daily_routine/screens/estadisticas.dart';
import 'package:my_daily_routine/screens/tareas.dart';
import 'package:my_daily_routine/screens/general.dart';
import 'routes.dart';
import 'screens/add.dart';
import 'screens/home.dart';
import 'screens/login.dart';
import 'screens/teams.dart';
import 'theme.dart';
import 'screens/historial.dart';

void main() => runApp(const MyApp());

/// Scroll sin rebote ni estiramiento al llegar al borde.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const ClampingScrollPhysics();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) =>
      child;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      scrollBehavior: const AppScrollBehavior(),
      initialRoute: AppRoutes.login,
      routes: {
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.home: (_) => const HomeScreen(),
        AppRoutes.add: (_) => const AddScreen(),
        AppRoutes.historial: (_) => const HistorialScreen(),
        AppRoutes.teams: (_) => const TeamsScreen(),
        AppRoutes.tareas: (_) => const TareaScreen(),
        AppRoutes.general: (_) => const GeneralScreen(),
        AppRoutes.estadisticas: (_) => const EstadisticaScreen(),
      },
    );
  }
}
