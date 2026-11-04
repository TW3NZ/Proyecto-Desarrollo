import 'package:flutter/material.dart';

import '../data/usuarios_store.dart';
import '../models/usuario.dart';
import '../theme.dart';
import '../widgets/auth/app_logo.dart';
import '../widgets/common/primary_button.dart';

class CrearUsuario extends StatefulWidget {
  const CrearUsuario({super.key});

  @override
  State<CrearUsuario> createState() => _CrearUsuarioState();
}

class _CrearUsuarioState extends State<CrearUsuario> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _lastName = TextEditingController();
  final _nickName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _showPassword = false;

  @override
  void dispose() {
    _name.dispose();
    _lastName.dispose();
    _nickName.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  String? _required(String? value, String label) =>
      value == null || value.trim().isEmpty ? 'Ingresa $label.' : null;

  String? _validateEmail(String? value) {
    if (_required(value, 'tu correo electrónico') != null) {
      return 'Ingresa tu correo electrónico.';
    }
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value!.trim())
        ? null
        : 'Ingresa un correo electrónico válido.';
  }

  String? _validatePassword(String? value) {
    if (value == null || value.length < 8) {
      return 'Usa al menos 8 caracteres.';
    }
    return null;
  }

  void _crearCuenta() {
    if (!_formKey.currentState!.validate()) return;
    if (UsuariosStore.existeEmail(_email.text)) {
      _showMessage('Ese correo ya está registrado.');
      return;
    }
    if (UsuariosStore.existeNickName(_nickName.text)) {
      _showMessage('Ese nombre de usuario ya está registrado.');
      return;
    }
    UsuariosStore.registrar(
      Usuario(
        name: _name.text.trim(),
        lastName: _lastName.text.trim(),
        nickName: _nickName.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
        createDate: DateTime.now(),
      ),
    );
    Navigator.pop(context, true);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _field({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    bool password = false,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.field),
      borderSide: const BorderSide(color: AppColors.fieldBorder),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 7),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            obscureText: password && !_showPassword,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.fieldFill,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 15,
              ),
              border: border,
              enabledBorder: border,
              focusedBorder: border.copyWith(
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
              suffixIcon: password
                  ? IconButton(
                      onPressed: () =>
                          setState(() => _showPassword = !_showPassword),
                      icon: Icon(
                        _showPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
          child: Column(
            children: [
              const AppLogo(),
              const SizedBox(height: 18),
              Text(
                'Crear cuenta',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'Completa tus datos para comenzar',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              const CircleAvatar(
                radius: 38,
                backgroundColor: Color(0xFFD6E2FB),
                child: Icon(
                  Icons.add_a_photo_outlined,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 22),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _field(
                      label: 'Nombre',
                      icon: Icons.person_outline,
                      controller: _name,
                      validator: (v) => _required(v, 'tu nombre'),
                    ),
                    _field(
                      label: 'Apellido',
                      icon: Icons.person_outline,
                      controller: _lastName,
                      validator: (v) => _required(v, 'tu apellido'),
                    ),
                    _field(
                      label: 'Nombre de usuario',
                      icon: Icons.alternate_email,
                      controller: _nickName,
                      validator: (v) => _required(v, 'un nombre de usuario'),
                    ),
                    _field(
                      label: 'Correo electrónico',
                      icon: Icons.mail_outline,
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                    ),
                    _field(
                      label: 'Contraseña',
                      icon: Icons.lock_outline,
                      controller: _password,
                      password: true,
                      validator: _validatePassword,
                    ),
                    _field(
                      label: 'Confirmar contraseña',
                      icon: Icons.lock_outline,
                      controller: _confirmPassword,
                      password: true,
                      validator: (v) {
                        if (v == null || v.isEmpty)
                          return 'Confirma tu contraseña.';
                        return v == _password.text
                            ? null
                            : 'Las contraseñas no coinciden.';
                      },
                    ),
                  ],
                ),
              ),
              PrimaryButton(text: 'Crear cuenta', onPressed: _crearCuenta),
              const SizedBox(height: 14),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Volver al inicio de sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
