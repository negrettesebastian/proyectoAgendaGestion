import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../validators/form_validators.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/wave_background.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usuarioCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _usuarioCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/api/auth/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _usuarioCtrl.text.trim(),
          'password': _passwordCtrl.text,
        }),
      );

      if (!mounted) return;
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', data['access']);
        await prefs.setString('username', data['user']['username']);
        _showSnack('¡Bienvenido!', AppColors.success);
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        _showSnack(data['detail'] ?? 'Credenciales inválidas', AppColors.danger);
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
                  const Text('Bienvenido a',
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
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.4),
                              blurRadius: 40, offset: const Offset(0, 16)),
                        ],
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
                              child: const Icon(Icons.lock_outline,
                                  size: 28, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 12),
                            const Text('INICIAR SESIÓN',
                                style: TextStyle(color: AppColors.textPrimary,
                                    fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 4)),
                            const SizedBox(height: 6),
                            Container(width: 32, height: 1,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [AppColors.blue, AppColors.cyan]),
                                )),
                            const SizedBox(height: 24),
                            CustomTextField(
                              controller: _usuarioCtrl,
                              hint: 'Usuario o correo electrónico',
                              icon: Icons.person_outline,
                              keyboardType: TextInputType.emailAddress,
                              validator: FormValidators.required,
                            ),
                            const SizedBox(height: 10),
                            CustomTextField(
                              controller: _passwordCtrl,
                              hint: 'Contraseña',
                              icon: Icons.lock_outline,
                              obscureText: _obscurePass,
                              validator: FormValidators.required,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: AppColors.textHint, size: 18),
                                onPressed: () => setState(() => _obscurePass = !_obscurePass),
                              ),
                            ),
                            const SizedBox(height: 24),
                            _GradButton(
                              onPressed: _isLoading ? null : _onSubmit,
                              label: 'INGRESAR',
                              isLoading: _isLoading,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('¿No tienes cuenta? ',
                                    style: TextStyle(color: AppColors.textHint, fontSize: 12)),
                                GestureDetector(
                                  onTap: () => Navigator.of(context).pushReplacementNamed('/register'),
                                  child: const Text('Regístrate',
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