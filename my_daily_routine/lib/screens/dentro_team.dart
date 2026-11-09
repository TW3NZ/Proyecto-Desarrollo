import 'package:flutter/material.dart';

import '../data/proyectos_store.dart';
import '../data/miembros_proyecto_store.dart';
import '../data/usuarios_store.dart';
import '../models/equipo_modelo.dart';
import '../models/proyecto_modelo.dart';
import '../theme.dart';
import '../widgets/common/cabecera_app.dart';
import 'detalles_team.dart';
import 'dentro_proyecto.dart';

/// Página del equipo: muestra sus proyectos y miembros.
class DentroTeamScreen extends StatefulWidget {
  const DentroTeamScreen({super.key, required this.equipo, this.usuarioId});
  final Equipo equipo;
  final int? usuarioId;
  @override
  State<DentroTeamScreen> createState() => _DentroTeamScreenState();
}

class _DentroTeamScreenState extends State<DentroTeamScreen> {
  Equipo get equipo => widget.equipo;
  int get usuarioId =>
      widget.usuarioId ?? UsuariosStore.usuarioActual?.id ?? equipo.creadorId;
  bool get esMiembro => equipo.miembros.any((m) => m.usuarioId == usuarioId);
  List<Proyecto> get proyectos =>
      ProyectosStore.proyectosDeEquipo(equipo.id)
          .where(_esMiembroDelProyecto)
          .toList(growable: false);
  bool get puedeCrear => usuarioId == equipo.creadorId;

  bool _esMiembroDelProyecto(Proyecto proyecto) =>
      MiembrosProyectoStore.buscarPorUsuario(
        proyectoId: proyecto.id,
        usuarioId: usuarioId,
        miembrosEquipo: equipo.miembros,
      ) !=
      null;
  Future<void> _crearProyecto() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            DetallesTeamScreen(equipo: equipo, usuarioId: usuarioId),
      ),
    );
    if (mounted) setState(() {});
  }

  void _abrir(Proyecto proyecto) =>
      Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => DentroProyectoScreen(
            equipo: equipo,
            proyecto: proyecto,
            usuarioId: widget.usuarioId,
          ),
        ),
      ).then((_) {
        if (mounted) setState(() {});
      });
  @override
  Widget build(BuildContext context) {
    if (!esMiembro) {
      return Scaffold(
        body: Column(
          children: [
            CabeceraApp(
              titulo: 'Acceso restringido',
              alVolver: () => Navigator.maybePop(context),
            ),
            const Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No formas parte de este equipo.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          CabeceraApp(
            titulo: equipo.nombre,
            alVolver: () => Navigator.maybePop(context),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Proyectos',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (puedeCrear)
                      FilledButton.icon(
                        onPressed: _crearProyecto,
                        icon: const Icon(Icons.add),
                        label: const Text('Crear proyecto'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (proyectos.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        ProyectosStore.proyectosDeEquipo(equipo.id).isEmpty
                            ? 'Este equipo aún no tiene proyectos.'
                            : 'No formas parte de ningún proyecto de este equipo.',
                      ),
                    ),
                  )
                else
                  for (final proyecto in proyectos)
                    Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.folder_rounded),
                        ),
                        title: Text(
                          proyecto.nombre,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${proyecto.meta}\n${proyecto.tareas.length} tareas · ${proyecto.categoria.etiqueta}',
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _abrir(proyecto),
                      ),
                    ),
                const SizedBox(height: 20),
                Text(
                  'Miembros · ${equipo.miembros.length}',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                for (final miembro in equipo.miembros)
                  ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text('Usuario ${miembro.usuarioId}'),
                    subtitle: Text('ID de usuario: ${miembro.usuarioId}'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
