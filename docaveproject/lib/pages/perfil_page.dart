import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});
  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  static const _baseUrl = 'http://127.0.0.1:8000/api';
  Map<String, dynamic>? _perfil;
  Map<String, dynamic>? _stats;
  String? _token;
  bool _isLoading = true;
  bool _editMode = false;

  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('access_token');
    await Future.wait([_fetchPerfil(), _fetchStats()]);
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $_token',
  };

  Future<void> _fetchPerfil() async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/auth/profile/'), headers: _headers);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _perfil = data;
          _nombreCtrl.text = data['first_name'] ?? '';
          _apellidoCtrl.text = data['last_name'] ?? '';
          _emailCtrl.text = data['email'] ?? '';
          _telefonoCtrl.text = data['phone'] ?? '';
          _bioCtrl.text = data['bio'] ?? '';
        });
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  Future<void> _fetchStats() async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/auth/stats/'), headers: _headers);
      if (res.statusCode == 200) {
        setState(() => _stats = jsonDecode(res.body));
      }
    } catch (_) {}
  }

  Future<void> _guardarPerfil() async {
    try {
      final res = await http.patch(
        Uri.parse('$_baseUrl/auth/profile/'),
        headers: _headers,
        body: jsonEncode({
          'first_name': _nombreCtrl.text.trim(),
          'last_name': _apellidoCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'phone': _telefonoCtrl.text.trim(),
          'bio': _bioCtrl.text.trim(),
        }),
      );
      if (res.statusCode == 200) {
        setState(() { _editMode = false; _perfil = jsonDecode(res.body); });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Perfil actualizado'),
          backgroundColor: AppColors.success,
        ));
      }
    } catch (_) {}
  }

  Future<void> _cambiarPassword() async {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🔒 Cambiar contraseña',
            style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: oldCtrl, obscureText: true,
                decoration: _inputDeco('Contraseña actual')),
            const SizedBox(height: 10),
            TextField(controller: newCtrl, obscureText: true,
                decoration: _inputDeco('Nueva contraseña')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await http.post(Uri.parse('$_baseUrl/auth/change-password/'),
                    headers: _headers,
                    body: jsonEncode({
                      'old_password': oldCtrl.text,
                      'new_password': newCtrl.text,
                    }));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('✅ Contraseña actualizada'),
                  backgroundColor: AppColors.success,
                ));
              } catch (_) {}
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.textLight),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.blue, width: 1.5),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navyMid,
        title: const Text('👤 Mi Perfil',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: () => setState(() => _editMode = !_editMode),
            child: Text(_editMode ? 'Cancelar' : 'Editar',
                style: const TextStyle(color: AppColors.cyan, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.blue))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AppColors.blue, AppColors.cyan]),
                    ),
                    child: Center(
                      child: Text(
                        (_perfil?['username'] ?? 'U')[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white,
                            fontSize: 36, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(_perfil?['full_name'] ?? _perfil?['username'] ?? '',
                      style: const TextStyle(color: AppColors.textDark,
                          fontSize: 20, fontWeight: FontWeight.w800)),
                  Text('@${_perfil?['username'] ?? ''}',
                      style: const TextStyle(color: AppColors.textLight, fontSize: 14)),
                  const SizedBox(height: 24),

                  // Stats
                  if (_stats != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
                            blurRadius: 8)],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _statItem('${_stats!['total_tasks']}', 'Tareas', AppColors.blue),
                          _statItem('${_stats!['completed_tasks']}', 'Completadas', AppColors.success),
                          _statItem('${_stats!['completion_rate']}%', 'Progreso', AppColors.warning),
                          _statItem('${_stats!['total_notes']}', 'Notas', AppColors.purple),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Formulario
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Información personal',
                            style: TextStyle(color: AppColors.textDark,
                                fontWeight: FontWeight.w700, fontSize: 15)),
                        const SizedBox(height: 16),
                        _perfilField('Nombre', _nombreCtrl, Icons.person_outline),
                        const SizedBox(height: 10),
                        _perfilField('Apellido', _apellidoCtrl, Icons.person_outline),
                        const SizedBox(height: 10),
                        _perfilField('Email', _emailCtrl, Icons.email_outlined,
                            type: TextInputType.emailAddress),
                        const SizedBox(height: 10),
                        _perfilField('Teléfono', _telefonoCtrl, Icons.phone_outlined,
                            type: TextInputType.phone),
                        const SizedBox(height: 10),
                        _perfilField('Bio', _bioCtrl, Icons.info_outline, maxLines: 3),
                        if (_editMode) ...[
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _guardarPerfil,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.blue,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text('Guardar cambios',
                                  style: TextStyle(color: Colors.white,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Cambiar contraseña
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _cambiarPassword,
                      icon: const Icon(Icons.lock_outline, color: AppColors.blue),
                      label: const Text('Cambiar contraseña',
                          style: TextStyle(color: AppColors.blue, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.blue),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _statItem(String value, String label, Color color) {
    return Column(children: [
      Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w800)),
      Text(label, style: const TextStyle(color: AppColors.textLight, fontSize: 11)),
    ]);
  }

  Widget _perfilField(String label, TextEditingController ctrl, IconData icon,
      {TextInputType type = TextInputType.text, int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      enabled: _editMode,
      maxLines: maxLines,
      keyboardType: type,
      style: const TextStyle(color: AppColors.textDark, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textLight),
        prefixIcon: Icon(icon, color: AppColors.textLight, size: 18),
        filled: true,
        fillColor: _editMode ? Colors.white : const Color(0xFFF8F9FF),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.blue, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
    );
  }
}