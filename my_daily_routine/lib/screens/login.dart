import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../assets_paths.dart';
import '../data/usuarios_store.dart';
import '../routes.dart';
import '../theme.dart';
import '../widgets/auth/labeled_text_field.dart';
import '../widgets/auth/text_link.dart';

/// Pantalla de inicio de sesión.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identificador = TextEditingController();
  final _password = TextEditingController();
  bool _mostrarPassword = false;

  @override
  void dispose() {
    _identificador.dispose();
    _password.dispose();
    super.dispose();
  }

  void _iniciarSesion() {
    if (UsuariosStore.autenticar(_identificador.text, _password.text)) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'El correo o nombre de usuario y la contraseña son incorrectos.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF2FF),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final ancho = constraints.maxWidth;
          final altoCabecera = ancho * 444 / 1024;
          final altoContenido = math.max(
            0.0,
            constraints.maxHeight - altoCabecera,
          );

          return DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFEAF2FF), Color(0xFFF7F9FF)],
              ),
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    AspectRatio(
                      aspectRatio: 1024 / 444,
                      child: Image.asset(
                        AppAssets.cabeceraLogin,
                        width: ancho,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Container(
                      constraints: BoxConstraints(minHeight: altoContenido),
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      padding: const EdgeInsets.fromLTRB(28, 4, 28, 30),
                      decoration: const BoxDecoration(color: Colors.white),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Bienvenido de nuevo',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.primaryDark,
                              fontSize: ancho < 380 ? 26 : 29,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Inicia sesión para continuar tu rutina',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF40517B),
                              fontSize: 16,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 12),
                          LabeledTextField(
                            label: 'Correo o nombre de usuario',
                            icon: Icons.mail_outline_rounded,
                            hint: 'Correo o nickName',
                            keyboardType: TextInputType.emailAddress,
                            controller: _identificador,
                          ),
                          const SizedBox(height: 8),
                          LabeledTextField(
                            label: 'Contraseña',
                            icon: Icons.lock_outline_rounded,
                            hint: 'Tu contraseña',
                            obscure: !_mostrarPassword,
                            suffixIcon: _mostrarPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            onSuffixTap: () => setState(
                              () => _mostrarPassword = !_mostrarPassword,
                            ),
                            controller: _password,
                          ),
                          const SizedBox(height: 14),
                          const Align(
                            alignment: Alignment.centerRight,
                            child: TextLink(text: '¿Olvidaste tu contraseña?'),
                          ),
                          const SizedBox(height: 17),
                          _BotonIniciarSesion(onPressed: _iniciarSesion),
                          const SizedBox(height: 26),
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text(
                                '¿No tienes cuenta? ',
                                style: TextStyle(
                                  color: Color(0xFF40517B),
                                  fontSize: 16,
                                ),
                              ),
                              TextLink(
                                text: 'Crear usuario',
                                onTap: () async {
                                  final creado =
                                      await Navigator.pushNamed<dynamic>(
                                        context,
                                        AppRoutes.crearUsuario,
                                      );
                                  if (creado == true && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Cuenta creada correctamente. Inicia sesión para continuar.',
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BotonIniciarSesion extends StatelessWidget {
  final VoidCallback onPressed;

  const _BotonIniciarSesion({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF3478F6), Color(0xFF00A5F5)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(22),
          child: const Center(
            child: Text(
              'Iniciar sesión',
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
