import 'package:flutter/material.dart';

import '../data/estadisticas_store.dart';
import '../theme.dart';
import '../widgets/common/cabecera_app.dart';

class EstadisticaScreen extends StatelessWidget {
  const EstadisticaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            CabeceraApp(
              titulo: 'Estadísticas',
              alVolver: () => Navigator.maybePop(context),
            ),
            const Expanded(
              child: _ContenidoEstadisticas(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContenidoEstadisticas extends StatelessWidget {
  const _ContenidoEstadisticas();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: EstadisticasStore.instancia,
      builder: (context, _) {
        final estadisticas = EstadisticasStore.instancia;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          children: [
            _TarjetaGeneral(
              valor: estadisticas.general,
            ),

            const SizedBox(height: 26),

            const Text(
              'Mis estadísticas',
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Activa las estadísticas que quieres que influyan en tu aura.',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 16),

            _TarjetaEstadistica(
              titulo: 'Inteligencia',
              icono: Icons.psychology_rounded,
              valor: estadisticas.inteligencia,
              activa: estadisticas.inteligenciaActiva,
              onChanged: (_) {
                estadisticas.cambiarInteligenciaActiva();
              },
            ),

            const SizedBox(height: 12),

            _TarjetaEstadistica(
              titulo: 'Finanzas',
              icono: Icons.account_balance_wallet_rounded,
              valor: estadisticas.finanzas,
              activa: estadisticas.finanzasActiva,
              onChanged: (_) {
                estadisticas.cambiarFinanzasActiva();
              },
            ),

            const SizedBox(height: 12),

            _TarjetaEstadistica(
              titulo: 'Salud',
              icono: Icons.favorite_rounded,
              valor: estadisticas.salud,
              activa: estadisticas.saludActiva,
              onChanged: (_) {
                estadisticas.cambiarSaludActiva();
              },
            ),

            const SizedBox(height: 12),

            _TarjetaEstadistica(
              titulo: 'Disciplina',
              icono: Icons.bolt_rounded,
              valor: estadisticas.disciplina,
              activa: estadisticas.disciplinaActiva,
              onChanged: (_) {
                estadisticas.cambiarDisciplinaActiva();
              },
            ),
          ],
        );
      },
    );
  }
}

class _TarjetaGeneral extends StatelessWidget {
  final double valor;

  const _TarjetaGeneral({
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    final porcentaje = valor / 100;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.20),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'AURA',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            valor.toStringAsFixed(0),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 46,
              fontWeight: FontWeight.w900,
            ),
          ),

          const Text(
            'General',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 16),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: porcentaje.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.20),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            '${valor.toStringAsFixed(0)} / 100',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaEstadistica extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final double valor;
  final bool activa;
  final ValueChanged<bool> onChanged;

  const _TarjetaEstadistica({
    required this.titulo,
    required this.icono,
    required this.valor,
    required this.activa,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final progreso = valor / 100;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: activa ? 1 : 0.55,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.fieldBorder,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    icono,
                    color: AppColors.primary,
                    size: 23,
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
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${valor.toStringAsFixed(0)} / 100',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                Switch(
                  value: activa,
                  onChanged: onChanged,
                  activeColor: AppColors.primary,
                ),
              ],
            ),

            const SizedBox(height: 12),

            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: progreso.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: AppColors.fieldBorder,
                valueColor: AlwaysStoppedAnimation<Color>(
                  activa
                      ? AppColors.primary
                      : AppColors.textHint,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}