import 'package:flutter/material.dart';

import '../data/equipos_store.dart';
import '../data/id_temporal_store.dart';
import '../data/usuarios_store.dart';
import '../models/equipo_modelo.dart';
import '../utils/snackbar_utils.dart';
import '../widgets/common/cabecera_app.dart';
import '../widgets/crear_team_widget.dart';

class CrearTeamScreen extends StatefulWidget {
  const CrearTeamScreen({super.key});
  @override
  State<CrearTeamScreen> createState() => _CrearTeamScreenState();
}

class _CrearTeamScreenState extends State<CrearTeamScreen> {
  final _nombre = TextEditingController(text: 'Mi equipo');
  final _integrante = TextEditingController();
  final List<int> _integrantes = [
    UsuariosStore.usuarioActual?.id ?? UsuariosStore.idUsuarioPractica,
  ];
  @override
  void dispose() {
    _nombre.dispose();
    _integrante.dispose();
    super.dispose();
  }

  void _agregar() {
    final id = int.tryParse(_integrante.text.trim());
    if (id == null) {
      showAppSnackBar(context, message: 'Escribe el ID del integrante');
      return;
    }
    if (UsuariosStore.buscarPorId(id) == null) {
      showAppSnackBar(context, message: 'No existe un usuario con ese ID');
      return;
    }
    if (_integrantes.contains(id)) {
      showAppSnackBar(context, message: 'Ese integrante ya está agregado');
      return;
    }
    setState(() {
      _integrantes.add(id);
      _integrante.clear();
    });
  }

  void _crear() {
    final nombre = _nombre.text.trim();
    if (nombre.isEmpty) {
      showAppSnackBar(context, message: 'Escribe el nombre del equipo');
      return;
    }
    final creador =
        UsuariosStore.usuarioActual?.id ?? UsuariosStore.idUsuarioPractica;
    final equipoId = IdTemporalStore.generar();
    final miembros = [
      for (final id in _integrantes)
        MiembroEquipo(
          id: IdTemporalStore.generar(),
          equipoId: equipoId,
          usuarioId: id,
        ),
    ];
    if (!miembros.any((m) => m.usuarioId == creador)) {
      miembros.insert(
        0,
        MiembroEquipo(
          id: IdTemporalStore.generar(),
          equipoId: equipoId,
          usuarioId: creador,
        ),
      );
    }
    final siglas = nombre
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .take(2)
        .map((s) => s[0].toUpperCase())
        .join();
    EquiposStore.agregar(
      Equipo(
        id: equipoId,
        nombre: nombre,
        siglas: siglas.isEmpty ? 'EQ' : siglas,
        creadorId: creador,
        miembros: miembros,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        CabeceraApp(
          titulo: 'Crear equipo',
          alVolver: () => Navigator.maybePop(context),
        ),
        Expanded(
          child: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                children: [
                  TarjetaCrearTeam(
                    titulo: 'Nombre del equipo',
                    subtitulo: 'Crea el espacio de trabajo',
                    icono: Icons.groups_rounded,
                    contenido: CampoTeam(
                      controlador: _nombre,
                      pista: 'Nombre del equipo',
                      icono: Icons.edit_rounded,
                      capitalizacion: TextCapitalization.sentences,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TarjetaCrearTeam(
                    titulo: 'Añadir integrantes',
                    subtitulo: 'Busca por ID del integrante',
                    icono: Icons.people_rounded,
                    contenido: Column(
                      children: [
                        CampoTeam(
                          controlador: _integrante,
                          pista: 'ID del integrante',
                          icono: Icons.search_rounded,
                          accionTeclado: TextInputAction.search,
                          alEnviar: (_) => _agregar(),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final id in _integrantes)
                              ChipIntegrante(
                                texto: 'ID: $id',
                                alQuitar: id == _integrantes.first
                                    ? null
                                    : () => setState(
                                        () => _integrantes.remove(id),
                                      ),
                              ),
                          ],
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: BotonAgregarIntegrante(alTocar: _agregar),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                right: 24,
                bottom: 24,
                child: BotonContinuar(alTocar: _crear),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
