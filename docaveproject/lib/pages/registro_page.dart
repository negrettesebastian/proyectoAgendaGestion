import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../validators/form_validators.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/wave_background.dart';

class RegistroPage extends StatefulWidget {
  const RegistroPage({super.key});

  @override
  State<RegistroPage> createState() => _RegistroPageState();
}

class _RegistroPageState extends State<RegistroPage> {
  static const _baseUrl = 'http://127.0.0.1:8000/api';

  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _usuarioCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _usuarioCtrl.dispose();
    _emailCtrl.dispose();
    _telefonoCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'first_name': _nombreCtrl.text.trim(),
          'last_name': _apellidoCtrl.text.trim(),
          'username': _usuarioCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'phone': _telefonoCtrl.text.trim(),
          'password': _passwordCtrl.text,
          'confirm_password': _confirmCtrl.text,
        }),
      );

      if (!mounted) return;
      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        // Auto login después del registro
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', data['access']);
        await prefs.setString('username', data['user']['username']);

        _showSnack('¡Registro exitoso! Bienvenido 🎉', AppColors.success);
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        // Mostrar errores del backend
        String msg = 'Error al registrarse';
        if (data is Map) {
          final errors = data.values.first;
          if (errors is List) msg = errors.first.toString();
          else msg = errors.toString();
        }
        _showSnack(msg, AppColors.danger);
      }
    } catch (e) {
      _showSnack('Error de conexión con el servidor', AppColors.danger);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color.withOpacity(0.9),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  Widget _eyeIcon(bool obscure, VoidCallback onTap) => IconButton(
    icon: Icon(
      obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
      color: AppColors.textHint, size: 18),
    onPressed: onTap,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const WaveBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                children: [
                  const Text('Bienvenido',
                      style: TextStyle(color: AppColors.textHint, fontSize: 13,
                          fontWeight: FontWeight.w300, letterSpacing: 2)),
                  const SizedBox(height: 6),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [AppColors.cyan, AppColors.blue],
                    ).createShader(bounds),
                    child: const Text('DOCAVE',
                        style: TextStyle(color: Colors.white, fontSize: 32,
                            fontWeight: FontWeight.w900, letterSpacing: 5)),
                  ),
                  const SizedBox(height: 32),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.glassBackground,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.glassBorder),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4),
                            blurRadius: 40, offset: const Offset(0, 16))],
                      ),
                      padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            Container(
                              width: 56, height: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.glassBackground,
                                border: Border.all(color: AppColors.cyan, width: 1.5),
                              ),
                              child: const Icon(Icons.person_outline,
                                  size: 28, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 12),
                            const Text('REGISTRO',
                                style: TextStyle(color: AppColors.textPrimary,
                                    fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 4)),
                            const SizedBox(height: 6),
                            Container(width: 32, height: 1,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(colors: [AppColors.blue, AppColors.cyan]),
                                )),
                            const SizedBox(height: 24),

                            // Nombre
                            CustomTextField(
                              controller: _nombreCtrl,
                              hint: 'Nombre',
                              icon: Icons.badge_outlined,
                              validator: FormValidators.nombre,
                              inputFormatters: [FilteringTextInputFormatter.allow(
                                  RegExp(r"[a-zA-ZáéíóúÁÉÍÓÚüÜñÑ\s'-]"))],
                            ),
                            const SizedBox(height: 10),

                            // Apellido
                            CustomTextField(
                              controller: _apellidoCtrl,
                              hint: 'Apellido',
                              icon: Icons.badge_outlined,
                              validator: FormValidators.nombre,
                              inputFormatters: [FilteringTextInputFormatter.allow(
                                  RegExp(r"[a-zA-ZáéíóúÁÉÍÓÚüÜñÑ\s'-]"))],
                            ),
                            const SizedBox(height: 10),

                            // Usuario
                            CustomTextField(
                              controller: _usuarioCtrl,
                              hint: 'Nombre de usuario',
                              icon: Icons.alternate_email,
                              validator: FormValidators.usuario,
                            ),
                            const SizedBox(height: 10),

                            // Email
                            CustomTextField(
                              controller: _emailCtrl,
                              hint: 'Email',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: FormValidators.email,
                            ),
                            const SizedBox(height: 10),

                            // Teléfono
                            CustomTextField(
                              controller: _telefonoCtrl,
                              hint: 'Teléfono',
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              validator: FormValidators.telefono,
                              inputFormatters: [FilteringTextInputFormatter.allow(
                                  RegExp(r'[\d\s\-\(\)\+]'))],
                            ),
                            const SizedBox(height: 10),

                            // Contraseña
                            CustomTextField(
                              controller: _passwordCtrl,
                              hint: 'Contraseña',
                              icon: Icons.lock_outline,
                              obscureText: _obscurePass,
                              validator: FormValidators.password,
                              suffixIcon: _eyeIcon(_obscurePass,
                                  () => setState(() => _obscurePass = !_obscurePass)),
                            ),
                            const SizedBox(height: 10),

                            // Confirmar contraseña
                            CustomTextField(
                              controller: _confirmCtrl,
                              hint: 'Confirmar contraseña',
                              icon: Icons.lock_outline,
                              obscureText: _obscureConfirm,
                              validator: FormValidators.confirmarPassword(_passwordCtrl.text),
                              suffixIcon: _eyeIcon(_obscureConfirm,
                                  () => setState(() => _obscureConfirm = !_obscureConfirm)),
                            ),
                            const SizedBox(height: 26),

                            // Botón
                            _GradButton(
                              onPressed: _isLoading ? null : _onSubmit,
                              label: 'REGISTRARSE',
                              isLoading: _isLoading,
                            ),
                            const SizedBox(height: 16),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('¿Ya tienes cuenta? ',
                                    style: TextStyle(color: AppColors.textHint, fontSize: 12)),
                                GestureDetector(
                                  onTap: () => Navigator.of(context).pushReplacementNamed('/login'),
                                  child: const Text('Inicia sesión',
                                      style: TextStyle(color: AppColors.cyan,
                                          fontSize: 12, fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
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

class _GradButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final bool isLoading;

  const _GradButton({required this.onPressed, required this.label, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity, height: 46,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.blue, AppColors.cyan]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: AppColors.cyan.withOpacity(0.25),
              blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: isLoading
              ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(label, style: const TextStyle(color: Colors.white, fontSize: 12,
                  fontWeight: FontWeight.w700, letterSpacing: 2.5)),
        ),
      ),
    );
  }
}
