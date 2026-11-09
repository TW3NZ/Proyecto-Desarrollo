import 'package:flutter_test/flutter_test.dart';
import 'package:my_daily_routine/data/miembros_proyecto_store.dart';
import 'package:my_daily_routine/models/equipo_modelo.dart';
import 'package:my_daily_routine/models/miembro_proyecto.dart';

void main() {
  test('el rol se resuelve desde la pertenencia del proyecto consultado', () {
    const usuarioId = -910001;
    const miembroId = -910002;
    const primerProyectoId = -910003;
    const segundoProyectoId = -910004;
    final miembro = MiembroEquipo(
      id: miembroId,
      equipoId: -910005,
      usuarioId: usuarioId,
    );

    MiembrosProyectoStore.guardarProyecto(primerProyectoId, [
      const MiembroProyecto(
        id: -910006,
        miembroId: miembroId,
        proyectoId: primerProyectoId,
        rol: RolProyecto.administrador,
      ),
    ]);
    MiembrosProyectoStore.guardarProyecto(segundoProyectoId, [
      const MiembroProyecto(
        id: -910007,
        miembroId: miembroId,
        proyectoId: segundoProyectoId,
        rol: RolProyecto.integrante,
      ),
    ]);

    final relacionPrimerProyecto = MiembrosProyectoStore.buscarPorUsuario(
      proyectoId: primerProyectoId,
      usuarioId: usuarioId,
      miembrosEquipo: [miembro],
    );
    final relacionSegundoProyecto = MiembrosProyectoStore.buscarPorUsuario(
      proyectoId: segundoProyectoId,
      usuarioId: usuarioId,
      miembrosEquipo: [miembro],
    );

    expect(relacionPrimerProyecto?.rol, RolProyecto.administrador);
    expect(
      PermisosProyecto.puedeGestionarProyecto(relacionPrimerProyecto!.rol),
      isTrue,
    );
    expect(relacionSegundoProyecto?.rol, RolProyecto.integrante);
    expect(
      PermisosProyecto.puedeGestionarProyecto(relacionSegundoProyecto!.rol),
      isFalse,
    );
  });

  test('rechaza pertenencias de otro proyecto y duplicados', () {
    const proyectoId = -920001;
    const miembroId = -920002;
    const relacion = MiembroProyecto(
      id: -920003,
      miembroId: miembroId,
      proyectoId: proyectoId,
      rol: RolProyecto.integrante,
    );

    expect(
      () => MiembrosProyectoStore.guardarProyecto(proyectoId, [
        const MiembroProyecto(
          id: -920004,
          miembroId: miembroId,
          proyectoId: -920005,
          rol: RolProyecto.integrante,
        ),
      ]),
      throwsArgumentError,
    );
    expect(
      () => MiembrosProyectoStore.guardarProyecto(proyectoId, [
        relacion,
        const MiembroProyecto(
          id: -920006,
          miembroId: miembroId,
          proyectoId: proyectoId,
          rol: RolProyecto.administrador,
        ),
      ]),
      throwsArgumentError,
    );
    expect(MiembrosProyectoStore.deProyecto(proyectoId), isEmpty);
  });
}
