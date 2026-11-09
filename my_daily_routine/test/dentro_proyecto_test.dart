import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_daily_routine/data/miembros_proyecto_store.dart';
import 'package:my_daily_routine/data/team_trabajo_store.dart';
import 'package:my_daily_routine/models/equipo_modelo.dart';
import 'package:my_daily_routine/models/miembro_proyecto.dart';
import 'package:my_daily_routine/models/proyecto_modelo.dart';
import 'package:my_daily_routine/models/tarea_modelo.dart';
import 'package:my_daily_routine/screens/dentro_proyecto.dart';

void main() {
  testWidgets('guarda una tarea nueva desde el proyecto del equipo', (
    tester,
  ) async {
    const equipoId = -930001;
    const proyectoId = -930002;
    const usuarioId = -930003;
    const miembroId = -930004;
    final miembro = MiembroEquipo(
      id: miembroId,
      equipoId: equipoId,
      usuarioId: usuarioId,
    );
    final equipo = Equipo(
      id: equipoId,
      nombre: 'Equipo de prueba',
      siglas: 'EP',
      creadorId: usuarioId,
      miembros: [miembro],
    );
    final proyecto = Proyecto(
      id: proyectoId,
      equipoId: equipoId,
      nombre: 'Proyecto de prueba',
      meta: 'Validar tareas',
      categoria: CategoriaTarea.educacion,
      fechaInicio: DateTime(2026, 11, 1),
      fechaFin: DateTime(2026, 11, 30),
      tareas: [],
    );
    MiembrosProyectoStore.guardarProyecto(proyectoId, [
      const MiembroProyecto(
        id: -930005,
        miembroId: miembroId,
        proyectoId: proyectoId,
        rol: RolProyecto.creador,
      ),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: DentroProyectoScreen(
          equipo: equipo,
          proyecto: proyecto,
          usuarioId: usuarioId,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final addButton = find.byIcon(Icons.add_circle);
    await tester.scrollUntilVisible(addButton, 250);
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Preparar informe');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(proyecto.tareas, hasLength(1));
    expect(proyecto.tareas.single.titulo, 'Preparar informe');
    expect(
      TeamTrabajoStore.instancia.tareas(proyecto).single.titulo,
      'Preparar informe',
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
