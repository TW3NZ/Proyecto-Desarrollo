import 'package:flutter/material.dart';
import '../../models/equipo_modelo.dart';
import '../../theme.dart';

/// Tarjeta de un team de la lista: círculo con siglas, nombre, miembros
/// conectados y botón "Entrar".
class TarjetaTeamActivo extends StatelessWidget {
  final Equipo equipo;
  final VoidCallback? alEntrar;

  const TarjetaTeamActivo({
    super.key,
    required this.equipo,
    this.alEntrar,
  });

  @override
  Widget build(BuildContext context) {
    final radio = BorderRadius.circular(26);
    final n = equipo.miembrosConectados;
    final textoMiembros =
        n == 1 ? '1 miembro conectado' : '$n miembros conectados';

    return Container(
      decoration: BoxDecoration(
        borderRadius: radio,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: radio,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppGradients.logo,
                ),
                child: FittedBox(
                  child: Text(
                    equipo.siglas,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      equipo.nombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      textoMiembros,
                      style: const TextStyle(
                        color: AppColors.textHint,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Material(
                color: const Color(0xFFE6ECFB),
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: alEntrar,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                    child: Text(
                      'Entrar',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
