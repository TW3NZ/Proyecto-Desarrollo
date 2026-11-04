import 'package:flutter/material.dart';

import '../utils/snackbar_utils.dart';
import '../widgets/common/cabecera_app.dart';
import '../widgets/crear_team_widget.dart';
import 'detalles_team.dart';

/// Formulario para crear un proyecto colaborativo y seleccionar integrantes.
class CrearTeamScreen extends StatefulWidget {
  const CrearTeamScreen({super.key});

  @override
  State<CrearTeamScreen> createState() => _CrearTeamScreenState();
}

class _CrearTeamScreenState extends State<CrearTeamScreen> {
  final _proyectoController = TextEditingController(
    text: 'Proyecto Final de Software',
  );
  final _integranteController = TextEditingController();
  final List<String> _integrantes = ['12345 (Tú)', '98765'];

  @override
  void dispose() {
    _proyectoController.dispose();
    _integranteController.dispose();
    super.dispose();
  }

  void _agregarIntegrante() {
    final id = _integranteController.text.trim();
    if (id.isEmpty) {
      showAppSnackBar(context, message: 'Escribe el ID del integrante');
      return;
    }
    if (_integrantes.any((integrante) => integrante.split(' ').first == id)) {
      showAppSnackBar(context, message: 'Ese integrante ya está agregado');
      return;
    }
    setState(() {
      _integrantes.add(id);
      _integranteController.clear();
    });
  }

  void _crearTeam() {
    if (_proyectoController.text.trim().isEmpty) {
      showAppSnackBar(context, message: 'Escribe el nombre del proyecto');
      return;
    }
    if (_integrantes.isEmpty) {
      showAppSnackBar(context, message: 'Agrega al menos un integrante');
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DetallesTeamScreen(
          nombreProyecto: _proyectoController.text.trim(),
          integrantes: List.unmodifiable(_integrantes),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: Column(
          children: [
            CabeceraApp(
              titulo: 'Teams',
              alVolver: () => Navigator.maybePop(context),
            ),
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    child: Column(
                      children: [
                        TarjetaCrearTeam(
                          titulo: 'Crear proyecto',
                          subtitulo: 'Establece el nombre del proyecto',
                          icono: Icons.folder_rounded,
                          contenido: CampoTeam(
                            controlador: _proyectoController,
                            pista: 'Nombre del proyecto',
                            icono: Icons.search_rounded,
                            capitalizacion: TextCapitalization.sentences,
                          ),
                        ),
                        const SizedBox(height: 28),
                        TarjetaCrearTeam(
                          titulo: 'Añadir integrantes',
                          subtitulo: 'Busca por ID del integrante (Ej. 12345)',
                          icono: Icons.groups_rounded,
                          contenido: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              CampoTeam(
                                controlador: _integranteController,
                                pista: 'Buscar por ID del integrante...',
                                icono: Icons.search_rounded,
                                accionTeclado: TextInputAction.search,
                                alEnviar: (_) => _agregarIntegrante(),
                              ),
                              const SizedBox(height: 18),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  for (final integrante in _integrantes)
                                    ChipIntegrante(
                                      texto: 'ID: $integrante',
                                      alQuitar: integrante.endsWith('(Tú)')
                                          ? null
                                          : () => setState(
                                              () => _integrantes.remove(
                                                integrante,
                                              ),
                                            ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 22),
                              Align(
                                alignment: Alignment.centerRight,
                                child: BotonAgregarIntegrante(
                                  alTocar: _agregarIntegrante,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 24,
                    bottom: 24,
                    child: BotonContinuar(alTocar: _crearTeam),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
