import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class NotasPage extends StatefulWidget {
  const NotasPage({super.key});
  @override
  State<NotasPage> createState() => _NotasPageState();
}

class _NotasPageState extends State<NotasPage> {
  static const _baseUrl = 'http://127.0.0.1:8000/api';
  List<Map<String, dynamic>> _notas = [];
  String? _token;
  bool _isLoading = true;

  final _colors = ['#FFFDE7', '#E8F5E9', '#E3F2FD', '#FCE4EC', '#F3E5F5'];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('access_token');
    await _fetchNotas();
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $_token',
  };

  Future<void> _fetchNotas() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.get(Uri.parse('$_baseUrl/notes/'), headers: _headers);
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        List<dynamic> data = decoded is List ? decoded : decoded['results'] ?? [];
        setState(() => _notas = data.cast<Map<String, dynamic>>());
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  Future<void> _showNoteDialog({Map<String, dynamic>? nota}) async {
    final titleCtrl = TextEditingController(text: nota?['title'] ?? '');
    final contentCtrl = TextEditingController(text: nota?['content'] ?? '');
    String selectedColor = nota?['color'] ?? _colors[0];

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(nota == null ? '📝 Nueva nota' : '✏️ Editar nota',
              style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w700)),
          content: SizedBox(
            width: 340,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: _inputDeco('Título'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentCtrl,
                  maxLines: 4,
                  decoration: _inputDeco('Contenido'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: _colors.map((c) {
                    final color = _hexToColor(c);
                    return GestureDetector(
                      onTap: () => setStateDialog(() => selectedColor = c),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selectedColor == c ? AppColors.blue : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar', style: TextStyle(color: AppColors.textLight))),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                if (nota == null) {
                  await _crearNota(titleCtrl.text, contentCtrl.text, selectedColor);
                } else {
                  await _editarNota(nota['id'], titleCtrl.text, contentCtrl.text, selectedColor);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: const Text('Guardar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _crearNota(String title, String content, String color) async {
    if (title.trim().isEmpty) return;
    try {
      await http.post(Uri.parse('$_baseUrl/notes/'), headers: _headers,
          body: jsonEncode({'title': title, 'content': content, 'color': color}));
      await _fetchNotas();
    } catch (_) {}
  }

  Future<void> _editarNota(int id, String title, String content, String color) async {
    try {
      await http.put(Uri.parse('$_baseUrl/notes/$id/'), headers: _headers,
          body: jsonEncode({'title': title, 'content': content, 'color': color}));
      await _fetchNotas();
    } catch (_) {}
  }

  Future<void> _eliminarNota(int id) async {
    try {
      await http.delete(Uri.parse('$_baseUrl/notes/$id/'), headers: _headers);
      await _fetchNotas();
    } catch (_) {}
  }

  Future<void> _togglePin(int id) async {
    try {
      await http.patch(Uri.parse('$_baseUrl/notes/$id/toggle_pin/'), headers: _headers);
      await _fetchNotas();
    } catch (_) {}
  }

  Color _hexToColor(String hex) {
    return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
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
        title: const Text('📝 Notas rápidas',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _fetchNotas,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNoteDialog(),
        backgroundColor: AppColors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.blue))
          : _notas.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('📝', style: TextStyle(fontSize: 48)),
                      SizedBox(height: 12),
                      Text('No tienes notas aún',
                          style: TextStyle(color: AppColors.textLight, fontSize: 16)),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: _notas.length,
                    itemBuilder: (ctx, i) {
                      final nota = _notas[i];
                      final color = _hexToColor(nota['color'] ?? '#FFFDE7');
                      final isPinned = nota['is_pinned'] ?? false;
                      return GestureDetector(
                        onTap: () => _showNoteDialog(nota: nota),
                        child: Container(
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08),
                                blurRadius: 8, offset: const Offset(0, 2))],
                          ),
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(nota['title'] ?? '',
                                        style: const TextStyle(
                                            color: AppColors.textDark,
                                            fontWeight: FontWeight.w700, fontSize: 14),
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                  Row(children: [
                                    GestureDetector(
                                      onTap: () => _togglePin(nota['id']),
                                      child: Icon(isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                                          size: 16, color: isPinned ? AppColors.blue : AppColors.textLight),
                                    ),
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      onTap: () => _eliminarNota(nota['id']),
                                      child: const Icon(Icons.close, size: 16, color: AppColors.textLight),
                                    ),
                                  ]),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: Text(nota['content'] ?? '',
                                    style: const TextStyle(color: AppColors.textMid, fontSize: 12),
                                    overflow: TextOverflow.fade),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}