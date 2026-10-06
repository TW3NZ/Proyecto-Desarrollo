import 'package:flutter/material.dart';

import '../widgets/common/cabecera_app.dart';

class GeneralScreen extends StatelessWidget {
  const GeneralScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          CabeceraApp(
            titulo: 'Estadísticas',
            alVolver: () => Navigator.maybePop(context),
          ),
          const Expanded(
            child: Center(child: Text('Próximamente')),
          ),
        ],
      ),
    );
  }
}