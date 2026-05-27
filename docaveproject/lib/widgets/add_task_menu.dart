import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AddTaskMenu extends StatefulWidget {
  final DateTime selectedDate;
  final void Function(String title, String description, TimeOfDay time, String category, String priority) onSave;
  final VoidCallback onClose;

  const AddTaskMenu({
    super.key,
    required this.selectedDate,
    required this.onSave,
    required this.onClose,
  });

  @override
  State<AddTaskMenu> createState() => _AddTaskMenuState();
}

class _AddTaskMenuState extends State<AddTaskMenu> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  TimeOfDay _time = TimeOfDay.now();
  String _category = 'Personal';
  String _priority = 'medium';

  static const _categories = ['Estudio', 'Trabajo', 'Personal', 'Salud', 'Otro'];
  static const _priorityOptions = {
    'high': 'Alta',
    'medium': 'Media',
    'low': 'Baja',
  };

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.blue),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _time = picked);
  }

  void _save() {
    if (_titleCtrl.text.trim().isEmpty) return;
    widget.onSave(_titleCtrl.text.trim(), _descCtrl.text.trim(), _time, _category, _priority);
  }

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${widget.selectedDate.day.toString().padLeft(2, '0')}/${widget.selectedDate.month.toString().padLeft(2, '0')}/${widget.selectedDate.year}';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 48, offset: const Offset(0, 16)),
        ],
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      padding: const EdgeInsets.all(22),
      width: 300,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '➕  Nueva tarea',
                style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w800, fontSize: 14),
              ),
              GestureDetector(
                onTap: widget.onClose,
                child: const Icon(Icons.close, color: AppColors.textLight, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Título
          _MiniField(controller: _titleCtrl, hint: 'Título *'),
          const SizedBox(height: 10),

          // Descripción
          _MiniField(controller: _descCtrl, hint: 'Descripción'),
          const SizedBox(height: 10),

          // Hora
          GestureDetector(
            onTap: _pickTime,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: AppColors.textLight),
                  const SizedBox(width: 8),
                  Text(
                    _time.format(context),
                    style: const TextStyle(color: AppColors.textDark, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Categoría
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _category,
                isExpanded: true,
                style: const TextStyle(color: AppColors.textDark, fontSize: 13),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _priority,
                isExpanded: true,
                style: const TextStyle(color: AppColors.textDark, fontSize: 13),
                items: _priorityOptions.entries
                    .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (v) => setState(() => _priority = v!),
              ),
            ),
          ),
          // Botón guardar
          SizedBox(
            width: double.infinity,
            height: 44,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.blue, AppColors.blueLight],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.blue.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'GUARDAR TAREA',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          Center(
            child: Text(
              'Se añadirá al: $dateStr',
              style: const TextStyle(color: AppColors.textLight, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const _MiniField({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: AppColors.textDark, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 13),
        filled: true,
        fillColor: AppColors.background,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.blue, width: 1.4),
        ),
      ),
    );
  }
}
