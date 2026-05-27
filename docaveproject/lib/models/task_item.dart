import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TaskItem {
  final int? id;
  final String title;
  final String description;
  final DateTime dueDate;
  final TimeOfDay dueTime;
  final bool isCompleted;
  final String category;

  TaskItem({
    this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.dueTime,
    this.isCompleted = false,
    this.category = 'Personal',
  });

  String get dueDateFormatted => DateFormat('dd/MM/yyyy').format(dueDate);

  String get dueTimeFormatted {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, dueTime.hour, dueTime.minute);
    return DateFormat.Hm().format(dt);
  }

  TaskItem copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? dueDate,
    TimeOfDay? dueTime,
    bool? isCompleted,
    String? category,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      isCompleted: isCompleted ?? this.isCompleted,
      category: category ?? this.category,
    );
  }

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    // Parsear tiempo correctamente aunque venga como "18:00:00.000000"
    final timeStr = (json['due_time'] as String).split('.')[0]; // quita microsegundos
    final timeParts = timeStr.split(':');

    // Parsear fecha como local, no UTC
    DateTime parsedDate;
    if (json['due_date'] != null) {
      final parts = (json['due_date'] as String).split('-');
      parsedDate = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    } else {
      parsedDate = DateTime.now();
    }

    return TaskItem(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      dueDate: parsedDate,
      dueTime: TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      ),
      isCompleted: json['is_completed'] ?? false,
      category: json['tags'] ?? json['category_name'] ?? 'Personal',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'due_date': DateFormat('yyyy-MM-dd').format(dueDate),
      'due_time': '${dueTime.hour.toString().padLeft(2, '0')}:${dueTime.minute.toString().padLeft(2, '0')}',
      'is_completed': isCompleted,
      'category': category,
    };
  }
}
