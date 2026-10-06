import 'package:flutter/material.dart';

import '../models/equipo_modelo.dart';
import '../theme.dart';
import '../utils/snackbar_utils.dart';
import '../widgets/common/cabecera_app.dart';
import '../widgets/equipos/encabezado_teams_activos.dart';
import '../widgets/equipos/insignia_seccion.dart';
import '../widgets/equipos/tarjeta_accion_team.dart';
import '../widgets/equipos/tarjeta_team_activo.dart';

/// Pantalla "Coworking" (sección Teams).
///
/// Por ahora es solo visual: los teams son datos de ejemplo y los botones
/// muestran "próximamente". Cada botón ya tiene su método (`_crearTeam`,
/// `_unirseATeam`, `_entrarAlTeam`, `_abrirNotificaciones`), que es donde
/// se conecta la lógica real más adelante.
class TeamsScreen extends StatefulWidget {
  const TeamsScreen({super.key});

  @override
  State<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends State<TeamsScreen> {
  // creacion de los equipos
  final List<Equipo> _equipos = const [
    Equipo(
      id: 'T000837267Z',
      nombre: 'Moscos Teams',
      siglas: 'MT',
      miembrosConectados: 9,
    ),

    Equipo(
      id: "T000837267Z",
      nombre: "Desarrollo de software", 
      siglas: "DS",
      miembrosConectados: 9
    ),
  ];

  void _crearTeam() {
    // TODO: abrir el flujo para crear un team y generar su código.
    showAppSnackBar(context, message: 'Crear team próximamente');
  }

  void _unirseATeam() {
    // TODO: pedir el código secreto y unir al usuario al team.
    showAppSnackBar(context, message: 'Unirse a team próximamente');
  }

  void _entrarAlTeam(Equipo equipo) {
    // TODO: navegar a la pantalla del team.
    showAppSnackBar(context, message: '${equipo.nombre} próximamente');
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
