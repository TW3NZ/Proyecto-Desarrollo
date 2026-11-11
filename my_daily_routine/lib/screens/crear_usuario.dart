import 'package:flutter/material.dart';

import '../assets_paths.dart';
import '../data/usuarios_store.dart';
import '../models/usuario.dart';
import '../services/auth_api_service.dart';
import '../theme.dart';
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
  bool _cargando = false;
  Genero? _genero;

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

  Future<void> _crearCuenta() async {
    if (_cargando) return;
    if (!_formKey.currentState!.validate()) return;
    if (UsuariosStore.existeEmail(_email.text)) {
      _showMessage('Ese correo ya está registrado.');
      return;
    }
    if (UsuariosStore.existeNickName(_nickName.text)) {
      _showMessage('Ese nombre de usuario ya está registrado.');
      return;
    }
    setState(() => _cargando = true);
    try {
      await UsuariosStore.registrar(
        Usuario(
          id: UsuariosStore.generarIdTemporal(),
          name: _name.text.trim(),
          lastName: _lastName.text.trim(),
          nickName: _nickName.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
          createDate: DateTime.now(),
          genero: _genero!,
        ),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showMessage(_mensajeError(e));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  String _mensajeError(Object e) => e is AuthApiException
      ? e.message
      : 'No se pudo crear la cuenta. Inténtalo de nuevo.';

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
      backgroundColor: const Color(0xFFEAF2FF),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final ancho = constraints.maxWidth;
          final altoCabecera = ancho * 444 / 1024;
          final altoContenido = (constraints.maxHeight - altoCabecera).clamp(
            0.0,
            double.infinity,
          );

          return SingleChildScrollView(
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
                  padding: const EdgeInsets.fromLTRB(28, 22, 28, 30),
                  decoration: const BoxDecoration(color: Colors.white),
                  child: Column(
                    children: [
                      Text(
                        'Crear cuenta',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w800,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Completa tus datos para comenzar',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 20),
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
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.wc_outlined,
                                        size: 18,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 7),
                                      Text(
                                        'Género',
                                        style: TextStyle(
                                          color: AppColors.primaryDark,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 7),
                                  DropdownButtonFormField<Genero>(
                                    initialValue: _genero,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: AppColors.fieldFill,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 15,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.field,
                                        ),
                                        borderSide: const BorderSide(
                                          color: AppColors.fieldBorder,
                                        ),
                                      ),
                                    ),
                                    hint: const Text('Selecciona una opción'),
                                    items: const [
                                      DropdownMenuItem(
                                        value: Genero.hombre,
                                        child: Text('Hombre'),
                                      ),
                                      DropdownMenuItem(
                                        value: Genero.mujer,
                                        child: Text('Mujer'),
                                      ),
                                    ],
                                    validator: (value) => value == null
                                        ? 'Selecciona tu género.'
                                        : null,
                                    onChanged: (value) =>
                                        setState(() => _genero = value),
                                  ),
                                ],
                              ),
                            ),
                            _field(
                              label: 'Nombre de usuario',
                              icon: Icons.alternate_email,
                              controller: _nickName,
                              validator: (v) =>
                                  _required(v, 'un nombre de usuario'),
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
                                if (v == null || v.isEmpty) {
                                  return 'Confirma tu contraseña.';
                                }
                                return v == _password.text
                                    ? null
                                    : 'Las contraseñas no coinciden.';
                              },
                            ),
                          ],
                        ),
                      ),
                      PrimaryButton(
                        text: _cargando ? 'Creando cuenta…' : 'Crear cuenta',
                        onPressed: _cargando ? null : () => _crearCuenta(),
                      ),
                      const SizedBox(height: 14),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Volver al inicio de sesión'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
