import 'package:flutter/material.dart';

import '../theme.dart';

/// Tarjeta de formulario con encabezado de icono y contenido personalizable.
class TarjetaCrearTeam extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final IconData icono;
  final Widget contenido;
  final String? decoracion;

  const TarjetaCrearTeam({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.contenido,
    this.decoracion,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F0FF),
                  borderRadius: BorderRadius.circular(23),
                ),
                child: Icon(icono, color: AppColors.primary, size: 34),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitulo,
                      style: const TextStyle(
                        color: AppColors.textHint,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (decoracion != null) ...[
                const SizedBox(width: 4),
                Text(decoracion!, style: const TextStyle(fontSize: 25)),
              ],
            ],
          ),
          const SizedBox(height: 22),
          contenido,
        ],
      ),
    );
  }
}

/// Campo redondeado con icono de búsqueda.
class CampoTeam extends StatelessWidget {
  final TextEditingController controlador;
  final String pista;
  final IconData icono;
  final TextInputAction? accionTeclado;
  final TextCapitalization capitalizacion;
  final ValueChanged<String>? alEnviar;

  const CampoTeam({
    super.key,
    required this.controlador,
    required this.pista,
    required this.icono,
    this.accionTeclado,
    this.capitalizacion = TextCapitalization.none,
    this.alEnviar,
  });

  @override
  Widget build(BuildContext context) {
    final forma = OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: const BorderSide(color: AppColors.divider, width: 1.5),
    );
    return TextField(
      controller: controlador,
      textInputAction: accionTeclado,
      textCapitalization: capitalizacion,
      onSubmitted: alEnviar,
      style: const TextStyle(
        color: AppColors.textDark,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: pista,
        hintStyle: const TextStyle(color: AppColors.textHint),
        prefixIcon: Icon(icono, color: AppColors.primary),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        enabledBorder: forma,
        border: forma,
        focusedBorder: forma.copyWith(
          borderSide: const BorderSide(color: AppColors.primary, width: 1.7),
        ),
      ),
    );
  }
}

/// Chip azul claro que identifica a un integrante seleccionado.
class ChipIntegrante extends StatelessWidget {
  final String texto;
  final VoidCallback? alQuitar;

  const ChipIntegrante({
    super.key,
    required this.texto,
    this.alQuitar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(14, 8, alQuitar == null ? 14 : 8, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE7F0FF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFB9D5FF), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            texto,
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          if (alQuitar != null) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: alQuitar,
              borderRadius: BorderRadius.circular(20),
              child: const Icon(Icons.close_rounded,
                  size: 18, color: AppColors.primary),
            ),
          ],
        ],
      ),
    );
  }
}

/// Botón de acción azul con texto e indicador de avance.
class BotonAgregarIntegrante extends StatelessWidget {
  final VoidCallback alTocar;

  const BotonAgregarIntegrante({super.key, required this.alTocar});

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: alTocar,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: const StadiumBorder(),
        elevation: 4,
      ),
      iconAlignment: IconAlignment.end,
      label: const Text(
        'Agregar integrante',
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
      ),
      icon: const Icon(Icons.arrow_forward_rounded, size: 20),
    );
  }
}

/// Acción circular fija en la esquina inferior derecha.
class BotonContinuar extends StatelessWidget {
  final VoidCallback alTocar;

  const BotonContinuar({super.key, required this.alTocar});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      shape: const CircleBorder(),
      elevation: 8,
      shadowColor: AppColors.primary.withValues(alpha: 0.35),
      child: InkWell(
        onTap: alTocar,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 68,
          height: 68,
          child: Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 32),
        ),
      ),
    );
  }
}
