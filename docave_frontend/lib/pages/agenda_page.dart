import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_item.dart';
import '../theme/app_theme.dart';
import '../widgets/arc_progress_meter.dart';
import '../widgets/add_task_menu.dart';
import '../widgets/task_card.dart';

class AgendaPage extends StatefulWidget {
  const AgendaPage({super.key});

  @override
  State<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends State<AgendaPage> {
  static const _baseUrl = 'http://127.0.0.1:8000/api';

  DateTime _visibleMonth = DateTime.now();
  DateTime _selectedDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  List<TaskItem> _tasks = [];
  String? _accessToken;
  String _username = 'Usuario';
  bool _isLoading = true;
  bool _showAddMenu = false;
  bool _showSearch = false;
  String _searchQuery = '';
  bool _showTaskList = false;

  static const _weekdayLabels = ['DO','LU','MA','MI','JU','VI','SA'];
  static const _monthNames = [
    '','Enero','Febrero','Marzo','Abril','Mayo','Junio',
    'Julio','Agosto','Septiembre','Octubre','Noviembre','Diciembre'
  ];

  @override
  
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    _username = prefs.getString('username') ?? 'Usuario';
    if (_accessToken == null) {
      if (mounted) Navigator.of(context).pushReplacementNamed('/login');
      return;
    }
    await _fetchTasks();
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $_accessToken',
  };

  Future<void> _fetchTasks() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/tasks/'),
        headers: _headers,
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List<dynamic> data;
        if (decoded is List) {
          data = decoded;
        } else if (decoded is Map && decoded.containsKey('results')) {
          data = decoded['results'];
        } else {
          data = [];
        }
        final tasks = data.map((j) => TaskItem.fromJson(j)).toList();
        debugPrint('✅ Tareas cargadas: ${tasks.length}');
        setState(() => _tasks = tasks);
      } else if (response.statusCode == 401) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveTask(String title, String description, TimeOfDay time, String category, String priority) async {
    setState(() => _showAddMenu = false);
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/tasks/'),
        headers: _headers,
        body: jsonEncode({
          'title': title,
          'description': description,
          'due_date': '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2,'0')}-${_selectedDate.day.toString().padLeft(2,'0')}',
          'due_time': '${time.hour.toString().padLeft(2,'0')}:${time.minute.toString().padLeft(2,'0')}',
          'priority': priority,
          'category': null,
          'tags': category,
        }),
      );
      if (response.statusCode == 201) await _fetchTasks();
    } catch (_) {}
  }

  Future<void> _toggleTask(int id) async {
    setState(() {
      _tasks = _tasks.map((t) =>
        t.id == id ? t.copyWith(isCompleted: !t.isCompleted) : t
      ).toList();
    });
    try {
      await http.patch(
        Uri.parse('$_baseUrl/tasks/$id/toggle/'),
        headers: _headers,
      );
    } catch (_) {}
  }

  Future<void> _deleteTask(int id) async {
    setState(() => _tasks.removeWhere((t) => t.id == id));
    try {
      await http.delete(
        Uri.parse('$_baseUrl/tasks/$id/'),
        headers: _headers,
      );
    } catch (_) {}
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) Navigator.of(context).pushReplacementNamed('/login');
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<TaskItem> get _todayTasks =>
      _tasks.where((t) => _sameDay(t.dueDate, DateTime.now())).toList();

  List<TaskItem> get _selectedTasks =>
      _tasks.where((t) => _sameDay(t.dueDate, _selectedDate)).toList();

  double get _progress {
    final today = _todayTasks;
    if (today.isEmpty) return 0;
    return today.where((t) => t.isCompleted).length / today.length;
  }

  List<TaskItem> get _searchResults => _searchQuery.isEmpty
      ? []
      : _tasks.where((t) =>
          t.title.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return '¡Buenos días';
    if (h < 18) return '¡Buenas tardes';
    return '¡Buenas noches';
  }

  List<DateTime?> _calendarDays() {
    final vy = _visibleMonth.year, vm = _visibleMonth.month;
    final count = DateTime(vy, vm + 1, 0).day;
    final firstWD = DateTime(vy, vm, 1).weekday % 7;
    final days = <DateTime?>[];
    for (int i = 0; i < firstWD; i++) days.add(null);
    for (int d = 1; d <= count; d++) days.add(DateTime(vy, vm, d));
    return days;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildNavBar(),
      drawer: _buildDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.blue))
          : Stack(
              children: [
                _showTaskList ? _buildTaskList() : _buildHome(),
                if (_showSearch) _buildSearchOverlay(),
                if (_showAddMenu)
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () => setState(() => _showAddMenu = false),
                      child: Container(color: Colors.black26),
                    ),
                  ),
                if (_showAddMenu)
                  Positioned(
                    bottom: 80, left: 0, right: 0,
                    child: Center(
                      child: AddTaskMenu(
                        selectedDate: _selectedDate,
                        onSave: _saveTask,
                        onClose: () => setState(() => _showAddMenu = false),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  PreferredSizeWidget _buildNavBar() {
    return AppBar(
      backgroundColor: AppColors.navyMid,
      automaticallyImplyLeading: false,
      elevation: 2,
      title: const Text('DOCAVE',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900,
              fontSize: 20, letterSpacing: 4)),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white70),
          onPressed: () => setState(() => _showSearch = !_showSearch),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(children: [
            Text(_username, style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.blueLight,
              child: Text(
                _username.isNotEmpty ? _username[0].toUpperCase() : 'U',
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ]),
        ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white70),
          onPressed: () {},
        ),
        TextButton(
          onPressed: () => setState(() => _showTaskList = !_showTaskList),
          child: Text('Tareas',
              style: TextStyle(
                color: _showTaskList ? AppColors.cyan : AppColors.blueLight,
                fontWeight: FontWeight.w700,
              )),
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white54, size: 20),
          onPressed: _fetchTasks,
          tooltip: 'Actualizar',
        ),
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white54, size: 20),
          onPressed: _logout,
          tooltip: 'Cerrar sesión',
        ),
      ],
    );
  }

  Widget _buildHome() {
    final now = DateTime.now();
    final days = ['Domingo','Lunes','Martes','Miércoles','Jueves','Viernes','Sábado'];
    final dayName = days[now.weekday % 7].toUpperCase();
    final dateStr = '$dayName, ${now.day} DE ${_monthNames[now.month].toUpperCase()} DE ${now.year}';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$_greeting, $_username! 👋',
              style: const TextStyle(color: AppColors.textDark,
                  fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(dateStr, style: const TextStyle(color: AppColors.textMid, fontSize: 12)),
          const SizedBox(height: 20),

          LayoutBuilder(builder: (ctx, constraints) {
            final wide = constraints.maxWidth > 600;
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProgressCard(),
                  const SizedBox(width: 16),
                  Expanded(child: _buildCalendar()),
                  const SizedBox(width: 16),
                  SizedBox(width: 220, child: _buildPendingCard()),
                ],
              );
            }
            return Column(children: [
              _buildProgressCard(),
              const SizedBox(height: 16),
              _buildCalendar(),
              const SizedBox(height: 16),
              _buildPendingCard(),
            ]);
          }),

          const SizedBox(height: 24),
          _buildSelectedDayTasks(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    return Container(
      width: 190,
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07),
            blurRadius: 16, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text('TU PROGRESO',
              style: TextStyle(color: AppColors.textDark,
                  fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1)),
        ),
        const SizedBox(height: 16),
        ArcProgressMeter(progress: _progress),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => setState(() => _showAddMenu = true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navyMid,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 4,
            ),
            child: const Text('TAREA',
                style: TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 2)),
          ),
        ),
      ]),
    );
  }

  Widget _buildCalendar() {
    final calDays = _calendarDays();
    final today = DateTime.now();
    final vy = _visibleMonth.year, vm = _visibleMonth.month;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.calendarBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2),
            blurRadius: 20, offset: const Offset(0, 8))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () => setState(() => _visibleMonth = DateTime(vy, vm - 1)),
              icon: const Icon(Icons.chevron_left, color: Colors.white70),
              padding: EdgeInsets.zero,
            ),
            Column(children: [
              Text(_monthNames[vm],
                  style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w700, fontSize: 16)),
              Text('$vy', style: const TextStyle(color: Colors.white38, fontSize: 12)),
            ]),
            IconButton(
              onPressed: () => setState(() => _visibleMonth = DateTime(vy, vm + 1)),
              icon: const Icon(Icons.chevron_right, color: Colors.white70),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: _weekdayLabels.map((l) => Expanded(
            child: Center(child: Text(l,
                style: const TextStyle(color: Colors.white38,
                    fontSize: 10, fontWeight: FontWeight.w700))),
          )).toList(),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: calDays.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7, crossAxisSpacing: 3, mainAxisSpacing: 3, childAspectRatio: 1,
          ),
          itemBuilder: (ctx, i) {
            final day = calDays[i];
            if (day == null) return const SizedBox.shrink();
            final isToday = _sameDay(day, today);
            final isSel = _sameDay(day, _selectedDate);
            final hasTasks = _tasks.any((t) => _sameDay(t.dueDate, day));
            return GestureDetector(
              onTap: () => setState(() => _selectedDate = DateTime(day.year, day.month, day.day)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: isSel ? AppColors.blue
                      : isToday ? AppColors.blue.withOpacity(0.3) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: isToday && !isSel
                      ? Border.all(color: AppColors.blueLight, width: 1) : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${day.day}',
                        style: TextStyle(
                          color: isSel || isToday ? Colors.white : Colors.white70,
                          fontWeight: isSel || isToday ? FontWeight.w700 : FontWeight.w400,
                          fontSize: 13,
                        )),
                    if (hasTasks) ...[
                      const SizedBox(height: 2),
                      Container(width: 4, height: 4,
                          decoration: BoxDecoration(
                            color: isSel ? Colors.white : AppColors.blueLight,
                            shape: BoxShape.circle,
                          )),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ]),
    );
  }

  Widget _buildPendingCard() {
    final pending = _todayTasks.where((t) => !t.isCompleted).toList();
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07),
            blurRadius: 16, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TAREAS PENDIENTES',
              style: TextStyle(color: AppColors.textDark,
                  fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1)),
          const SizedBox(height: 14),
          if (pending.isEmpty)
            const Text('¡Todo al día! 🎉',
                style: TextStyle(color: AppColors.textLight, fontSize: 13))
          else
            ...pending.asMap().entries.map((e) {
              final color = AppColors.priority(e.key);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(children: [
                  Container(width: 4, height: 36,
                      decoration: BoxDecoration(color: color,
                          borderRadius: BorderRadius.circular(4))),
                  const SizedBox(width: 10),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.value.title,
                          style: const TextStyle(color: AppColors.textDark,
                              fontSize: 13, fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis),
                      Text(e.value.dueTimeFormatted,
                          style: const TextStyle(color: AppColors.textLight, fontSize: 11)),
                    ],
                  )),
                ]),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildSelectedDayTasks() {
    final tasks = _selectedTasks;
    final label =
        '${_selectedDate.day.toString().padLeft(2,'0')}/${_selectedDate.month.toString().padLeft(2,'0')}/${_selectedDate.year}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Tareas del día',
                style: TextStyle(color: AppColors.textDark,
                    fontSize: 18, fontWeight: FontWeight.w800)),
            Text(label, style: const TextStyle(color: AppColors.textLight, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 12),
        if (tasks.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBg, borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
            ),
            child: const Text('No hay tareas para este día.',
                style: TextStyle(color: AppColors.textLight, fontSize: 14)),
          )
        else
          ...tasks.asMap().entries.map((e) => TaskCard(
            task: e.value,
            color: AppColors.priority(e.key),
            onToggle: () => _toggleTask(e.value.id!),
            onDelete: () => _deleteTask(e.value.id!),
          )),
      ],
    );
  }

  Widget _buildTaskList() {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Todas mis tareas',
                style: TextStyle(color: AppColors.textDark,
                    fontSize: 20, fontWeight: FontWeight.w800)),
            ElevatedButton.icon(
              onPressed: () => setState(() { _showTaskList = false; _showAddMenu = true; }),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Nueva'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
      Expanded(
        child: _tasks.isEmpty
            ? const Center(child: Text('No tienes tareas aún',
                style: TextStyle(color: AppColors.textLight, fontSize: 14)))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _tasks.length,
                itemBuilder: (ctx, i) => TaskCard(
                  task: _tasks[i],
                  color: AppColors.priority(i),
                  onToggle: () => _toggleTask(_tasks[i].id!),
                  onDelete: () => _deleteTask(_tasks[i].id!),
                ),
              ),
      ),
    ]);
  }

  Widget _buildSearchOverlay() {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: Container(
        color: AppColors.cardBg,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(children: [
          TextField(
            autofocus: true,
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Buscar tarea...',
              hintStyle: const TextStyle(color: AppColors.textLight),
              prefixIcon: const Icon(Icons.search, color: AppColors.blue),
              suffixIcon: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() {
                  _showSearch = false;
                  _searchQuery = '';
                }),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.blue, width: 1.5),
              ),
            ),
          ),
          ..._searchResults.map((t) => ListTile(
            leading: const Icon(Icons.task_alt, color: AppColors.blue),
            title: Text(t.title,
                style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600)),
            subtitle: Text(t.dueDateFormatted,
                style: const TextStyle(color: AppColors.textLight, fontSize: 11)),
            onTap: () => setState(() {
              _selectedDate = t.dueDate;
              _showSearch = false;
              _searchQuery = '';
              _showTaskList = false;
            }),
          )),
        ]),
      ),
    );
  }
}

extension _DrawerExtension on _AgendaPageState {
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppColors.navyMid,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.blueLight,
                    child: Text(
                      _username.isNotEmpty ? _username[0].toUpperCase() : 'U',
                      style: const TextStyle(color: Colors.white,
                          fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_username,
                            style: const TextStyle(color: Colors.white,
                                fontWeight: FontWeight.w700, fontSize: 16)),
                        const Text('DOCAVE',
                            style: TextStyle(color: AppColors.cyan,
                                fontSize: 12, letterSpacing: 2)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12),

            // Menú items
            _drawerItem(Icons.home_outlined, 'Inicio', () {
              Navigator.pop(context);
              setState(() => _showTaskList = false);
            }),
            _drawerItem(Icons.calendar_today_outlined, 'Calendario', () {
              Navigator.pop(context);
            }),
            _drawerItem(Icons.task_alt, 'Mis Tareas', () {
              Navigator.pop(context);
              setState(() => _showTaskList = true);
            }),
            _drawerItem(Icons.note_outlined, 'Notas rápidas', () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/notas');
            }),
            _drawerItem(Icons.notifications_outlined, 'Recordatorios', () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/recordatorios');
            }),
            _drawerItem(Icons.bar_chart, 'Estadísticas', () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/estadisticas');
            }),
            _drawerItem(Icons.person_outline, 'Mi Perfil', () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/perfil');
            }),

            const Spacer(),
            const Divider(color: Colors.white12),
            _drawerItem(Icons.logout, 'Cerrar sesión', _logout,
                color: Colors.redAccent),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String label, VoidCallback onTap,
      {Color color = Colors.white70}) {
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(label, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w500)),
      onTap: onTap,
      horizontalTitleGap: 8,
    );
  }
}