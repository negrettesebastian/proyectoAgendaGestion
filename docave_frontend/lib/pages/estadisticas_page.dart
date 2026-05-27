import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class EstadisticasPage extends StatefulWidget {
  const EstadisticasPage({super.key});
  @override
  State<EstadisticasPage> createState() => _EstadisticasPageState();
}

class _EstadisticasPageState extends State<EstadisticasPage> {
  static const _baseUrl = 'http://127.0.0.1:8000/api';
  Map<String, dynamic>? _stats;
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
    await _fetchStats();
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $_token',
  };

  Future<void> _fetchStats() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.get(Uri.parse('$_baseUrl/auth/stats/'), headers: _headers);
      if (res.statusCode == 200) {
        setState(() => _stats = jsonDecode(res.body));
      }
      final taskStats = await http.get(Uri.parse('$_baseUrl/tasks/stats/'), headers: _headers);
      if (taskStats.statusCode == 200) {
        final data = jsonDecode(taskStats.body);
        setState(() => _stats = {...?_stats, ...data});
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navyMid,
        title: const Text('📊 Estadísticas',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _fetchStats,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.blue))
          : _stats == null
              ? const Center(child: Text('No hay datos disponibles',
                  style: TextStyle(color: AppColors.textLight)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Resumen general',
                          style: TextStyle(color: AppColors.textDark,
                              fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 16),

                      // Cards de stats
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.4,
                        children: [
                          _statCard('Total tareas', '${_stats!['total_tasks'] ?? 0}',
                              Icons.task_alt, AppColors.blue),
                          _statCard('Completadas', '${_stats!['completed_tasks'] ?? _stats!['completed'] ?? 0}',
                              Icons.check_circle_outline, AppColors.success),
                          _statCard('Pendientes', '${_stats!['pending_tasks'] ?? _stats!['pending'] ?? 0}',
                              Icons.pending_outlined, AppColors.warning),
                          _statCard('Notas', '${_stats!['total_notes'] ?? 0}',
                              Icons.note_outlined, AppColors.purple),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Progreso circular grande
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
                              blurRadius: 10)],
                        ),
                        child: Column(
                          children: [
                            const Text('Tasa de completado',
                                style: TextStyle(color: AppColors.textDark,
                                    fontWeight: FontWeight.w700, fontSize: 15)),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 160,
                              child: CustomPaint(
                                painter: _DonutPainter(
                                  (_stats!['completion_rate'] ?? 0).toDouble() / 100,
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '${_stats!['completion_rate'] ?? 0}%',
                                        style: const TextStyle(
                                          color: AppColors.textDark,
                                          fontSize: 28,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const Text('completado',
                                          style: TextStyle(color: AppColors.textLight, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Por prioridad
                      if (_stats!.containsKey('by_priority'))
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.cardBg,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
                                blurRadius: 10)],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Por prioridad',
                                  style: TextStyle(color: AppColors.textDark,
                                      fontWeight: FontWeight.w700, fontSize: 15)),
                              const SizedBox(height: 16),
                              _priorityBar('Alta', _stats!['by_priority']['high'] ?? 0,
                                  _stats!['total'] ?? 1, AppColors.danger),
                              const SizedBox(height: 10),
                              _priorityBar('Media', _stats!['by_priority']['medium'] ?? 0,
                                  _stats!['total'] ?? 1, AppColors.warning),
                              const SizedBox(height: 10),
                              _priorityBar('Baja', _stats!['by_priority']['low'] ?? 0,
                                  _stats!['total'] ?? 1, AppColors.success),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color,
              fontSize: 24, fontWeight: FontWeight.w800)),
          Text(label, style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _priorityBar(String label, int value, int total, Color color) {
    final pct = total > 0 ? value / total : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textDark,
                fontSize: 13, fontWeight: FontWeight.w600)),
            Text('$value tareas', style: const TextStyle(
                color: AppColors.textLight, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: pct.toDouble(),
            backgroundColor: const Color(0xFFE2E8F0),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final double progress;
  _DonutPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 16;
    const strokeWidth = 16.0;

    final trackPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      final progressPaint = Paint()
        ..shader = const LinearGradient(
          colors: [AppColors.blue, AppColors.cyan],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.progress != progress;
}