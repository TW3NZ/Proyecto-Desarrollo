import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:my_daily_routine/screens/estadisticas.dart';
import 'package:my_daily_routine/screens/tareas.dart';
import 'package:my_daily_routine/screens/general.dart';

import 'routes.dart';
import 'screens/add.dart';
import 'screens/home.dart';
import 'screens/login.dart';
import 'screens/crear_usuario.dart';
import 'screens/welcome.dart';
import 'screens/teams.dart';
import 'theme.dart';
import 'screens/historial.dart';
import 'screens/avatar.dart';
import 'data/avatar_store.dart';
import 'data/tareas_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AvatarStore.instancia.load();
  await TareasStore.instancia.inicializarWidget();
  final uriInicial = await HomeWidget.initiallyLaunchedFromHomeWidget();
  _aplicarAccionWidget(uriInicial);
  HomeWidget.widgetClicked.listen(_aplicarAccionWidget);
  runApp(const MyApp());
}

void _aplicarAccionWidget(Uri? uri) {
  if (uri?.host != 'toggle-task') return;
  final indice = int.tryParse(uri?.queryParameters['index'] ?? '');
  if (indice != null) {
    TareasStore.instancia.alternarCompletadaPorIndice(indice);
  }
}

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
  ) => child;
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
        AppRoutes.crearUsuario: (_) => const CrearUsuario(),
        AppRoutes.welcome: (context) => WelcomeScreen(
          arguments:
              ModalRoute.of(context)!.settings.arguments! as WelcomeArguments,
        ),
        AppRoutes.home: (context) => HomeScreen(
          mostrarTutorial: ModalRoute.of(context)?.settings.arguments == true,
        ),
        AppRoutes.avatar: (_) => const AvatarScreen(),
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
