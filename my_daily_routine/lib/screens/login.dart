import 'package:flutter/material.dart';
import '../routes.dart';
import '../theme.dart';
import '../widgets/auth/app_logo.dart';
import '../widgets/auth/auth_widgets.dart';
import '../widgets/auth/labeled_text_field.dart';
import '../widgets/common/primary_button.dart';
import '../widgets/auth/text_link.dart';

/// Pantalla de login (solo visual, sin estado).
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

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
                  const LabeledTextField(
                    label: 'Correo',
                    icon: Icons.mail_outline,
                    hint: 'nombre@correo.com',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 18),
                  const LabeledTextField(
                    label: 'Contraseña',
                    icon: Icons.lock_outline,
                    hint: 'Tu contraseña',
                    obscure: true,
                    suffixIcon: Icons.visibility_outlined,
                  ),
                  const SizedBox(height: 14),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: TextLink(text: '¿Olvidaste tu contraseña?'),
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    text: 'Iniciar sesión',
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, AppRoutes.home),
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
                      const TextLink(text: 'Regístrate'),
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
