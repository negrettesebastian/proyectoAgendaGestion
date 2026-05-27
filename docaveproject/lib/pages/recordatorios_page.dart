import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class RecordatoriosPage extends StatefulWidget {
  const RecordatoriosPage({super.key});
  @override
  State<RecordatoriosPage> createState() => _RecordatoriosPageState();
}

class _RecordatoriosPageState extends State<RecordatoriosPage> {
  static const _baseUrl = 'http://127.0.0.1:8000/api';
  List<Map<String, dynamic>> _recordatorios = [];
  String? _token;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('access_token');
    await _fetchRecordatorios();
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $_token',
  };

  Future<void> _fetchRecordatorios() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.get(Uri.parse('$_baseUrl/reminders/'), headers: _headers);
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        List<dynamic> data = decoded is List ? decoded : decoded['results'] ?? [];
        setState(() => _recordatorios = data.cast<Map<String, dynamic>>());
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  Future<void> _showDialog({Map<String, dynamic>? rec}) async {
    final titleCtrl = TextEditingController(text: rec?['title'] ?? '');
    final descCtrl = TextEditingController(text: rec?['description'] ?? '');
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    String repeat = rec?['repeat'] ?? 'none';
    final repeats = ['none', 'daily', 'weekly', 'monthly'];
    final repeatLabels = ['Sin repetición', 'Diario', 'Semanal', 'Mensual'];

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(rec == null ? '🔔 Nuevo recordatorio' : '✏️ Editar recordatorio',
              style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w700)),
          content: SizedBox(
            width: 340,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, decoration: _inputDeco('Título *')),
                const SizedBox(height: 10),
                TextField(controller: descCtrl, decoration: _inputDeco('Descripción')),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                      onPressed: () async {
                        final d = await showDatePicker(
                          context: ctx,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (d != null) setStateDialog(() => selectedDate = d);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.access_time, size: 16),
                      label: Text(selectedTime.format(ctx)),
                      onPressed: () async {
                        final t = await showTimePicker(context: ctx, initialTime: selectedTime);
                        if (t != null) setStateDialog(() => selectedTime = t);
                      },
                    ),
                  ),
                ]),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: repeat,
                  decoration: _inputDeco('Repetición'),
                  items: List.generate(repeats.length, (i) =>
                    DropdownMenuItem(value: repeats[i], child: Text(repeatLabels[i]))),
                  onChanged: (v) => setStateDialog(() => repeat = v!),
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
                final remindAt = DateTime(selectedDate.year, selectedDate.month,
                    selectedDate.day, selectedTime.hour, selectedTime.minute);
                await _guardar(titleCtrl.text, descCtrl.text, remindAt, repeat, rec?['id']);
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

  Future<void> _guardar(String title, String desc, DateTime remindAt, String repeat, int? id) async {
    if (title.trim().isEmpty) return;
    final body = jsonEncode({
      'title': title,
      'description': desc,
      'remind_at': remindAt.toIso8601String(),
      'repeat': repeat,
    });
    try {
      if (id == null) {
        await http.post(Uri.parse('$_baseUrl/reminders/'), headers: _headers, body: body);
      } else {
        await http.put(Uri.parse('$_baseUrl/reminders/$id/'), headers: _headers, body: body);
      }
      await _fetchRecordatorios();
    } catch (_) {}
  }

  Future<void> _eliminar(int id) async {
    try {
      await http.delete(Uri.parse('$_baseUrl/reminders/$id/'), headers: _headers);
      await _fetchRecordatorios();
    } catch (_) {}
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
        title: const Text('🔔 Recordatorios',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDialog(),
        backgroundColor: AppColors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.blue))
          : _recordatorios.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('🔔', style: TextStyle(fontSize: 48)),
                      SizedBox(height: 12),
                      Text('No tienes recordatorios',
                          style: TextStyle(color: AppColors.textLight, fontSize: 16)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _recordatorios.length,
                  itemBuilder: (ctx, i) {
                    final rec = _recordatorios[i];
                    final isActive = rec['is_active'] ?? true;
                    final remindAt = DateTime.tryParse(rec['remind_at'] ?? '') ?? DateTime.now();
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border(left: BorderSide(
                          color: isActive ? AppColors.blue : AppColors.textLight, width: 4)),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
                            blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: ListTile(
                        leading: Icon(Icons.notifications,
                            color: isActive ? AppColors.blue : AppColors.textLight),
                        title: Text(rec['title'] ?? '',
                            style: const TextStyle(color: AppColors.textDark,
                                fontWeight: FontWeight.w700)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (rec['description'] != null && rec['description'].isNotEmpty)
                              Text(rec['description'],
                                  style: const TextStyle(color: AppColors.textMid, fontSize: 12)),
                            Text(
                              '${remindAt.day}/${remindAt.month}/${remindAt.year} ${remindAt.hour.toString().padLeft(2,'0')}:${remindAt.minute.toString().padLeft(2,'0')}',
                              style: const TextStyle(color: AppColors.textLight, fontSize: 11),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: AppColors.blue, size: 20),
                              onPressed: () => _showDialog(rec: rec),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                              onPressed: () => _eliminar(rec['id']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}