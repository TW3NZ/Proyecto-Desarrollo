import 'package:flutter/material.dart';

import '../data/usuarios_store.dart';
import '../routes.dart';
import '../theme.dart';
import '../widgets/auth/app_logo.dart';
import '../widgets/auth/auth_widgets.dart';
import '../widgets/auth/labeled_text_field.dart';
import '../widgets/common/primary_button.dart';
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
      body: Stack(
        children: [
          // Resplandor azul de la esquina superior derecha
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.25),
                    AppColors.primary.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                children: [
                  const AppLogo(),
                  const SizedBox(height: 20),
                  Text(
                    'Bienvenido de nuevo',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Inicia sesión para continuar tu rutina',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 28),
                  LabeledTextField(
                    label: 'Correo o nombre de usuario',
                    icon: Icons.mail_outline,
                    hint: 'Correo o nickName',
                    keyboardType: TextInputType.emailAddress,
                    controller: _identificador,
                  ),
                  const SizedBox(height: 18),
                  LabeledTextField(
                    label: 'Contraseña',
                    icon: Icons.lock_outline,
                    hint: 'Tu contraseña',
                    obscure: true,
                    suffixIcon: Icons.visibility_outlined,
                    controller: _password,
                  ),
                  const SizedBox(height: 14),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: TextLink(text: '¿Olvidaste tu contraseña?'),
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    text: 'Iniciar sesión',
                    onPressed: _iniciarSesion,
                  ),
                  const SizedBox(height: 24),
                  const DividerWithText(text: 'O CONTINÚA CON'),
                  const SizedBox(height: 18),
                  const Row(
                    children: [
                      Expanded(
                        child: SocialButton(
                          text: 'Google',
                          icon: Icons.g_mobiledata,
                          iconColor: Color(0xFFEA4335),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: SocialButton(text: 'Apple', icon: Icons.apple),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '¿No tienes cuenta? ',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      TextLink(
                        text: 'Crear usuario',
                        onTap: () async {
                          final creado = await Navigator.pushNamed<dynamic>(
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
          ),
        ],
      ),
    );
  }
}
