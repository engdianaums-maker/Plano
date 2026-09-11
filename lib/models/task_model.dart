class Task {
  final String id;
  final String title;
  final String description;
  final String assignedEmployee;
  final String category;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final int elapsedSeconds;
  final String taskStatus;
  final bool isModified;
  final DateTime? lastModifiedAt;
  final String modificationLog;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.assignedEmployee,
    this.category = 'عام',
    required this.isCompleted,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.elapsedSeconds = 0,
    this.taskStatus = 'not_started',
    this.isModified = false,
    this.lastModifiedAt,
    this.modificationLog = '',
  });

  // دالة مسؤولة عن تحويل أي نوع تاريخ بأمان تام بدون أخطاء
  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    try {
      // إذا كان كائن Timestamp الخاص بفايربيس
      return (value as dynamic).toDate();
    } catch (_) {
      try {
        // إذا كان نص عادي (String)
        return DateTime.parse(value.toString());
      } catch (_) {
        return null;
      }
    }
  }

  factory Task.fromMap(Map<String, dynamic> map, String documentId) {
    return Task(
      id: documentId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      assignedEmployee: map['assignedEmployee'] ?? '',
      category: map['category'] ?? 'عام',
      isCompleted: map['isCompleted'] ?? false,
      createdAt: _parseDate(map['createdAt']) ?? DateTime.now(),
      startedAt: _parseDate(map['startedAt']),
      completedAt: _parseDate(map['completedAt']),
      elapsedSeconds: map['elapsedSeconds'] ?? 0,
      taskStatus: map['taskStatus'] ?? 'not_started',
      isModified: map['isModified'] ?? false,
      lastModifiedAt: _parseDate(map['lastModifiedAt']),
      modificationLog: map['modificationLog'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'assignedEmployee': assignedEmployee,
      'category': category,
      'isCompleted': isCompleted,
      'createdAt': createdAt,
      'startedAt': startedAt,
      'completedAt': completedAt,
      'elapsedSeconds': elapsedSeconds,
      'taskStatus': taskStatus,
      'isModified': isModified,
      'lastModifiedAt': lastModifiedAt,
      'modificationLog': modificationLog,
    };
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? assignedEmployee,
    String? category,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
    int? elapsedSeconds,
    String? taskStatus,
    bool? isModified,
    DateTime? lastModifiedAt,
    String? modificationLog,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      assignedEmployee: assignedEmployee ?? this.assignedEmployee,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      taskStatus: taskStatus ?? this.taskStatus,
      isModified: isModified ?? this.isModified,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      modificationLog: modificationLog ?? this.modificationLog,
    );
  }
}