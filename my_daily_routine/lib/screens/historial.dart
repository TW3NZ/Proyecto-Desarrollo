import 'package:flutter/material.dart';

import '../assets_paths.dart';
import '../data/tareas_store.dart';
import '../data/usuarios_store.dart';
import '../models/tarea_modelo.dart';
import '../routes.dart';
import '../services/tareas_api_service.dart';
import '../theme.dart';
import '../widgets/common/cabecera_app.dart';
import '../widgets/home/round_buttons.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  final _tareasApi = TareasApiService();
  List<NuevaTarea>? _completadas;
  String? _error;

  bool get _esUsuarioReal =>
      (UsuariosStore.usuarioActual?.id ?? UsuariosStore.idUsuarioPractica) > 0;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    if (!_esUsuarioReal) {
      // Cuenta de práctica: historial local, sin backend.
      if (mounted) {
        setState(() {
          _completadas = null;
          _error = null;
        });
      }
      return;
    }

    final token = UsuariosStore.token;
    if (token == null || token.isEmpty) {
      if (mounted) {
        setState(() {
          _completadas = null;
          _error = 'No hay sesión activa. Inicia sesión de nuevo.';
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _completadas = null;
        _error = null;
      });
    }

    try {
      final tareas = await _tareasApi.obtenerTareas(token: token);
      if (!mounted) return;
      setState(() {
        _completadas = tareas.where((tarea) => tarea.completada).toList();
      });
    } on TareasApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo obtener las tareas. Inténtalo de nuevo.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          CabeceraApp(
            titulo: 'Objetivos completados',
            alVolver: () => Navigator.maybePop(context),
          ),
          Expanded(child: _contenido()),
        ],
      ),
    );
  }

  Widget _contenido() {
    if (!_esUsuarioReal) {
      return AnimatedBuilder(
        animation: TareasStore.instancia,
        builder: (context, _) {
          final completadas = TareasStore.instancia.tareas
              .where((tarea) => tarea.completada)
              .toList();
          return _listaCompletadas(completadas);
        },
      );
    }

    if (_error != null) return _estadoError(_error!);
    if (_completadas == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return _listaCompletadas(_completadas!);
  }

  Widget _listaCompletadas(List<NuevaTarea> completadas) {
    return Stack(
      children: [
        if (completadas.isEmpty)
          const _SinCompletadas()
        else
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            children: [
              Text(
                '${completadas.length} '
                '${completadas.length == 1 ? 'tarea completada' : 'tareas completadas'}',
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              ...completadas.map(
                (tarea) => _TareaCompletadaCard(
                  titulo: tarea.titulo,
                  descripcion: tarea.descripcion,
                  prioridad: tarea.prioridad.etiqueta,
                ),
              ),
            ],
          ),
        Positioned(
          right: 24,
          bottom: 28,
          child: AddTaskButton(
            iconAsset: AppAssets.iconAnadirTarea,
            onTap: () => Navigator.pushNamed(context, AppRoutes.add),
            label: '',
          ),
        ),
      ],
    );
  }

  Widget _estadoError(String mensaje) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 52,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 12),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _cargar,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SinCompletadas extends StatelessWidget {
  const _SinCompletadas();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.task_alt_rounded,
            size: 52,
            color: AppColors.textHint,
          ),
          SizedBox(height: 12),
          Text(
            'Aún no has completado tareas',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Las tareas que completes aparecerán aquí.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _TareaCompletadaCard extends StatelessWidget {
  final String titulo;
  final String descripcion;
  final String prioridad;

  const _TareaCompletadaCard({
    required this.titulo,
    required this.descripcion,
    required this.prioridad,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.fieldBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(
                alpha: 0.12,
              ),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                if (descripcion.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    descripcion,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  'Prioridad: $prioridad',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
