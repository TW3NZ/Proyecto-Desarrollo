import 'package:flutter/material.dart';

import '../data/equipos_store.dart';
import '../data/usuarios_store.dart';
import '../models/equipo_modelo.dart';
import 'crear_team.dart';
import '../theme.dart';
import '../widgets/common/cabecera_app.dart';
import '../widgets/equipos/encabezado_teams_activos.dart';
import '../widgets/equipos/insignia_seccion.dart';
import '../widgets/equipos/tarjeta_accion_team.dart';
import '../widgets/equipos/tarjeta_id_usuario.dart';
import '../widgets/equipos/tarjeta_team_activo.dart';
import 'dentro_team.dart';

/// Pantalla "Coworking" (sección Teams).
///
/// Los teams creados se mantienen en memoria durante la sesión.
class TeamsScreen extends StatefulWidget {
  const TeamsScreen({super.key});

  @override
  State<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends State<TeamsScreen> {
  int get _usuarioId =>
      UsuariosStore.usuarioActual?.id ?? UsuariosStore.idUsuarioPractica;
  List<Equipo> get _equipos => EquiposStore.equipos
      .where((equipo) => equipo.miembros.any((m) => m.usuarioId == _usuarioId))
      .toList(growable: false);

  Future<void> _crearTeam() async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const CrearTeamScreen()));
    if (mounted) setState(() {});
  }

  void _unirseATeam() {
    showDialog<void>(
      context: context,
      builder: (_) => const _UnirseTeamDialog(),
    );
  }

  void _entrarAlTeam(Equipo equipo) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            DentroTeamScreen(equipo: equipo, usuarioId: _usuarioId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          CabeceraApp(
            titulo: 'Equipos',
            alVolver: () => Navigator.maybePop(context),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 26, 18, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ---- Introducción ----
                  const Center(
                    child: InsigniaSeccion(
                      icono: Icons.groups_rounded,
                      texto: 'Sección Teams',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Espacio Colaborativo',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Organiza tareas en equipo, comparte objetivos y avanza '
                      'con tus compañeros.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF4A66C8),
                        fontSize: 15,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),

                  // ---- ID personal ----
                  TarjetaIdUsuario(id: _usuarioId),
                  const SizedBox(height: 16),

                  // ---- Acciones principales ----
                  TarjetaAccionTeam(
                    icono: Icons.groups_rounded,
                    titulo: 'Crear team',
                    descripcion:
                        'Inicia un nuevo grupo de estudio o proyecto y comparte '
                        'el código.',
                    iconoAccion: Icons.add_rounded,
                    alTocar: _crearTeam,
                  ),
                  const SizedBox(height: 16),
                  TarjetaAccionTeam(
                    icono: Icons.login_rounded,
                    titulo: 'Unirse a team',
                    descripcion:
                        'Ingresa un código secreto para colaborar en un equipo '
                        'existente.',
                    iconoAccion: Icons.vpn_key_rounded,
                    colorIconoAccion: const Color(0xFFE0A526),
                    alTocar: _unirseATeam,
                  ),
                  const SizedBox(height: 30),

                  // ---- Teams activos ----
                  EncabezadoTeamsActivos(cantidad: _equipos.length),
                  const SizedBox(height: 14),
                  if (_equipos.isEmpty)
                    const _SinTeams()
                  else
                    for (final equipo in _equipos) ...[
                      TarjetaTeamActivo(
                        equipo: equipo,
                        alEntrar: () => _entrarAlTeam(equipo),
                      ),
                      const SizedBox(height: 12),
                    ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mensaje que se muestra cuando el usuario todavía no está en ningún team.
class _SinTeams extends StatelessWidget {
  const _SinTeams();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Text(
        'Aún no estás en ningún team. Crea uno o únete con un código.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.textMuted, fontSize: 14),
      ),
    );
  }
}

class _UnirseTeamDialog extends StatefulWidget {
  const _UnirseTeamDialog();

  @override
  State<_UnirseTeamDialog> createState() => _UnirseTeamDialogState();
}

class _UnirseTeamDialogState extends State<_UnirseTeamDialog> {
  final _idController = TextEditingController();
  bool _mostrarAviso = false;

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      icon: const Icon(
        Icons.groups_rounded,
        color: AppColors.primary,
        size: 34,
      ),
      title: const Text(
        'Unirse a un equipo',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.textDark,
          fontWeight: FontWeight.w800,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _idController,
            autofocus: true,
            textInputAction: TextInputAction.done,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Ingresa el ID del equipo',
              prefixIcon: const Icon(
                Icons.vpn_key_rounded,
                color: AppColors.primary,
              ),
              filled: true,
              fillColor: AppColors.fieldFill,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.fieldBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.fieldBorder),
              ),
            ),
          ),
          if (_mostrarAviso) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF1FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'La opción para unirse a equipos estará disponible próximamente.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.primaryDark, fontSize: 13),
              ),
            ),
          ],
        ],
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            FocusScope.of(context).unfocus();
            setState(() => _mostrarAviso = true);
          },
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: const StadiumBorder(),
          ),
          child: const Text('Unirse'),
        ),
      ],
    );
  }
}
