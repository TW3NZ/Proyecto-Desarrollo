import 'package:flutter/foundation.dart';

import '../models/estadisticas.dart';
import '../services/perfil_api_service.dart';
import '../models/tarea_modelo.dart';
import '../models/puntuacion.dart';
import 'usuarios_store.dart';

class EstadisticasStore extends ChangeNotifier {
  EstadisticasStore._() {
    UsuariosStore.sessionVersion.addListener(() {
      _porUsuario.removeWhere((key, _) => key > 0);
      error = null;
      notifyListeners();
    });
  }
  final _api = PerfilApiService();
  String? error;
  bool saving = false;

  Future<void> load() async {
    final id = _usuarioIdActual;
    if (id <= 0) return;
    final epoch = UsuariosStore.sessionVersion.value;
    try {
      final data = await _api.request('estadisticas', UsuariosStore.token!);
      if (epoch != UsuariosStore.sessionVersion.value) return;
      aplicar(data);
    } catch (_) {
      if (epoch == UsuariosStore.sessionVersion.value) {
        error = 'No se pudieron cargar las estadisticas. Reintenta la sincronizacion.';
        notifyListeners();
      }
      rethrow;
    }
  }

  void aplicar(Map<String, dynamic> data) {
    final id = _usuarioIdActual;
    if (data['usuarioId'] != id) return;
    _porUsuario[id] = Estadisticas(
      usuarioId: id,
      inteligencia: (data['inteligencia'] as num).toDouble(),
      finanzas: (data['finanzas'] as num).toDouble(),
      salud: (data['salud'] as num).toDouble(),
      disciplina: (data['disciplina'] as num).toDouble(),
      inteligenciaActiva: data['inteligenciaActiva'] as bool,
      finanzasActiva: data['finanzasActiva'] as bool,
      saludActiva: data['saludActiva'] as bool,
      disciplinaActiva: data['disciplinaActiva'] as bool,
    );
    error = null;
    notifyListeners();
  }

  Future<void> _toggle(String field) async {
    if (saving) return;
    final epoch = UsuariosStore.sessionVersion.value;
    final a = actual;
    final values = <String, dynamic>{
      'inteligenciaActiva': a.inteligenciaActiva,
      'finanzasActiva': a.finanzasActiva,
      'saludActiva': a.saludActiva,
      'disciplinaActiva': a.disciplinaActiva,
    };
    values[field] = !(values[field] as bool);
    if (_usuarioIdActual <= 0) {
      a.inteligenciaActiva = values['inteligenciaActiva'];
      a.finanzasActiva = values['finanzasActiva'];
      a.saludActiva = values['saludActiva'];
      a.disciplinaActiva = values['disciplinaActiva'];
      notifyListeners();
      return;
    }
    saving = true;
    notifyListeners();
    try {
      final data = await _api.request(
        'estadisticas/preferencias',
        UsuariosStore.token!,
        data: values,
      );
      if (epoch == UsuariosStore.sessionVersion.value) aplicar(data);
    } catch (_) {
      if (epoch == UsuariosStore.sessionVersion.value) {
        error = 'No se pudo guardar la preferencia. Intentalo de nuevo.';
      }
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  static final EstadisticasStore instancia = EstadisticasStore._();

  final Map<int, Estadisticas> _porUsuario = {};

  int get _usuarioIdActual =>
      UsuariosStore.usuarioActual?.id ?? UsuariosStore.idUsuarioPractica;

  /// Estadísticas de la sesión actual (la cuenta de práctica si no hay sesión).
  Estadisticas get actual => paraUsuario(_usuarioIdActual);

  /// Obtiene o inicializa las estadísticas de una cuenta concreta.
  Estadisticas paraUsuario(int usuarioId) => _porUsuario.putIfAbsent(
    usuarioId,
    () => Estadisticas(usuarioId: usuarioId),
  );

  double get general => actual.general;

  double get inteligencia => actual.inteligencia;
  double get finanzas => actual.finanzas;
  double get salud => actual.salud;
  double get disciplina => actual.disciplina;

  bool get inteligenciaActiva => actual.inteligenciaActiva;
  bool get finanzasActiva => actual.finanzasActiva;
  bool get saludActiva => actual.saludActiva;
  bool get disciplinaActiva => actual.disciplinaActiva;

  final Set<(int, int)> _recompensadas = {};
  final Set<(int, int)> _penalizadas = {};

  void procesarTareaCompletada(NuevaTarea tarea, {int pendientes = 1}) {
    if (tarea.usuarioId > 0 ||
        !_recompensadas.add((tarea.usuarioId, tarea.id))) {
      return;
    }
    _aplicarTarea(tarea, puntosTarea(tarea.prioridad, pendientes));
  }

  void procesarVencidas(Iterable<NuevaTarea> tareas) {
    final now = DateTime.now();
    final hoy = DateTime(now.year, now.month, now.day);
    for (final tarea in tareas) {
      final fin = tarea.fechaFinalizacion;
      if (tarea.usuarioId > 0 ||
          tarea.proyectoId != null ||
          tarea.completada ||
          fin == null) {
        continue;
      }
      if (DateTime(fin.year, fin.month, fin.day).isBefore(hoy) &&
          _penalizadas.add((tarea.usuarioId, tarea.id))) {
        _aplicarTarea(tarea, puntosTarea(tarea.prioridad, 1, vencida: true));
      }
    }
  }

  void _aplicarTarea(NuevaTarea tarea, double puntosTotales) {
    if (tarea.usuarioId > 0 || tarea.categorias.isEmpty) return;

    final puntosPorCategoria = puntosTotales / tarea.categorias.length;
    final estadisticas = paraUsuario(tarea.usuarioId);

    for (final categoria in tarea.categorias) {
      switch (categoria) {
        case CategoriaTarea.educacion:
          estadisticas.inteligencia = _sumarPuntos(
            estadisticas.inteligencia,
            puntosPorCategoria,
          );
          break;
        case CategoriaTarea.finanzas:
          estadisticas.finanzas = _sumarPuntos(
            estadisticas.finanzas,
            puntosPorCategoria,
          );
          break;
        case CategoriaTarea.salud:
          estadisticas.salud = _sumarPuntos(
            estadisticas.salud,
            puntosPorCategoria,
          );
          break;
        case CategoriaTarea.disciplina:
          estadisticas.disciplina = _sumarPuntos(
            estadisticas.disciplina,
            puntosPorCategoria,
          );
          break;
      }
    }

    notifyListeners();
  }

  double _sumarPuntos(double actual, double puntos) {
    final nuevoValor = actual + puntos;
    return nuevoValor.clamp(0.0, 100.0);
  }

  Future<void> cambiarInteligenciaActiva() => _toggle('inteligenciaActiva');
  Future<void> cambiarFinanzasActiva() => _toggle('finanzasActiva');
  Future<void> cambiarSaludActiva() => _toggle('saludActiva');
  Future<void> cambiarDisciplinaActiva() => _toggle('disciplinaActiva');
}
