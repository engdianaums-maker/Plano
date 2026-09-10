import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String id;
  final String title;
  final String description;
  final bool isCompleted;
  final String assignedEmployee;
  final String category;
  final String taskStatus; // 'not_started', 'in_progress', 'paused', 'completed'
  final DateTime? createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final int elapsedSeconds;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.isCompleted,
    this.assignedEmployee = 'غير محدد',
    this.category = 'عام',
    this.taskStatus = 'not_started',
    this.createdAt,
    this.startedAt,
    this.completedAt,
    this.elapsedSeconds = 0,
  });

  factory Task.fromMap(Map<String, dynamic> map, String documentId) {
    // دالة مساعدة لتحويل التواريخ بأمان سواء كانت Timestamp أو String
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return Task(
      id: documentId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
      assignedEmployee: map['assignedEmployee'] ?? 'غير محدد',
      category: map['category'] ?? 'عام',
      taskStatus: map['taskStatus'] ?? 'not_started',
      createdAt: parseDate(map['createdAt']),
      startedAt: parseDate(map['startedAt']),
      completedAt: parseDate(map['completedAt']),
      elapsedSeconds: map['elapsedSeconds'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'assignedEmployee': assignedEmployee,
      'category': category,
      'taskStatus': taskStatus,
      'createdAt': createdAt?.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'elapsedSeconds': elapsedSeconds,
    };
  }

  Task copyWith({
    String? title,
    String? description,
    bool? isCompleted,
    String? assignedEmployee,
    String? category,
    String? taskStatus,
    DateTime? startedAt,
    DateTime? completedAt,
    int? elapsedSeconds,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      assignedEmployee: assignedEmployee ?? this.assignedEmployee,
      category: category ?? this.category,
      taskStatus: taskStatus ?? this.taskStatus,
      createdAt: createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
    );
  }
}