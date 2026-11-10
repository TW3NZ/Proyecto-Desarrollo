import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_daily_routine/data/id_temporal_store.dart';
import 'package:my_daily_routine/data/tareas_store.dart';
import 'package:my_daily_routine/models/tarea_modelo.dart';

void main() {
  test('persiste y restaura tareas, categorías y estado completado', () async {
    String? disk;
    String? publishedWidget;
    final store = TareasStore(
      read: () async => disk,
      write: (value) async => disk = value,
      publishWidget: (value) async => publishedWidget = value,
    );
    final tarea = NuevaTarea(
      id: -960001,
      usuarioId: -960002,
      titulo: 'Preparar exposición',
      categorias: {CategoriaTarea.educacion, CategoriaTarea.disciplina},
      prioridad: PrioridadTarea.alta,
      descripcion: 'Repasar las diapositivas',
      fecha: DateTime(2026, 11, 10, 9, 30),
      fechaFinalizacion: DateTime(2026, 11, 12),
      responsableId: -960003,
    );

    await store.agregarTarea(tarea);
    await store.alternarCompletada(tarea);
    expect(disk, isNotNull);
    final widgetSnapshot = jsonDecode(publishedWidget!) as List<dynamic>;
    expect(widgetSnapshot.single, containsPair('id', tarea.id));
    expect(widgetSnapshot.single, containsPair('completada', true));

    final reopened = TareasStore(
      read: () async => disk,
      write: (value) async => disk = value,
      publishWidget: (_) async {},
    );
    await reopened.inicializarWidget();

    expect(reopened.loadFailed, isFalse);
    expect(reopened.tareas, hasLength(1));
    final restored = reopened.tareas.single;
    expect(restored.id, tarea.id);
    expect(restored.usuarioId, tarea.usuarioId);
    expect(restored.titulo, tarea.titulo);
    expect(restored.categorias, tarea.categorias);
    expect(restored.prioridad, PrioridadTarea.alta);
    expect(restored.descripcion, tarea.descripcion);
    expect(restored.fecha, tarea.fecha);
    expect(restored.fechaFinalizacion, tarea.fechaFinalizacion);
    expect(restored.responsableId, tarea.responsableId);
    expect(restored.completada, isTrue);
    expect(IdTemporalStore.generar(), lessThan(tarea.id));
  });

  test(
    'una lectura inválida no rompe ni borra la instantánea del widget',
    () async {
      var writes = 0;
      final store = TareasStore(
        read: () async => '{no es json',
        write: (_) async => writes++,
      );

      await store.inicializarWidget();

      expect(store.loadFailed, isTrue);
      expect(store.tareas, isEmpty);
      expect(writes, 0);
    },
  );
}
