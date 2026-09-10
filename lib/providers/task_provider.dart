import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';

final taskProvider = StreamNotifierProvider<TaskNotifier, List<Task>>(() {
  return TaskNotifier();
});

class TaskNotifier extends StreamNotifier<List<Task>> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<List<Task>> build() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('tasks')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Task.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Future<void> addTask(String title, String description, DateTime? dueDate, {String category = 'عام'}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final newTask = {
      'title': title,
      'description': description,
      'isCompleted': false,
      'createdAt': DateTime.now().toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'completedAt': null,
      'startedAt': null,
      'category': category,
      'taskStatus': 'not_started',
    };

    await _firestore.collection('users').doc(user.uid).collection('tasks').add(newTask);
  }

  Future<void> updateTask(String taskId, String title, String description, DateTime? dueDate, {String category = 'عام'}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final updateData = {
      'title': title,
      'description': description,
      'dueDate': dueDate?.toIso8601String(),
      'category': category,
    };

    await _firestore.collection('users').doc(user.uid).collection('tasks').doc(taskId).update(updateData);
  }

  // بدء المهمة وتسجيل وقت البدء وتغيير الحالة إلى قيد التنفيذ
  Future<void> startTask(String taskId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).collection('tasks').doc(taskId).update({
      'taskStatus': 'in_progress',
      'startedAt': DateTime.now().toIso8601String(),
    });
  }

  // إيقاف مؤقت للمهمة
  Future<void> pauseTask(String taskId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).collection('tasks').doc(taskId).update({
      'taskStatus': 'paused',
    });
  }

  // استئناف المهمة
  Future<void> resumeTask(String taskId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).collection('tasks').doc(taskId).update({
      'taskStatus': 'in_progress',
    });
  }

  // إنهاء المهمة وتحويلها إلى مرحلة المراجعة أو الإنجاز
  Future<void> completeTask(String taskId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).collection('tasks').doc(taskId).update({
      'isCompleted': true,
      'taskStatus': 'completed',
      'completedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> toggleTask(String taskId, bool currentStatus) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final newStatus = !currentStatus;
    final updateData = {
      'isCompleted': newStatus,
      'taskStatus': newStatus ? 'completed' : 'not_started',
      'completedAt': newStatus ? DateTime.now().toIso8601String() : null,
    };

    await _firestore.collection('users').doc(user.uid).collection('tasks').doc(taskId).update(updateData);
  }

  Future<void> deleteTask(String taskId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).collection('tasks').doc(taskId).delete();
  }
}