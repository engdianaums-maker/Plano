import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'task_service.dart';
import '../../models/task_model.dart';
import '../auth/auth_repository.dart';
import '../settings/settings_provider.dart';
import '../employees/employees_screen.dart';

final taskServiceProvider = Provider<TaskService>((ref) => TaskService());

final tasksStreamProvider = StreamProvider<List<Task>>((ref) {
  return ref.watch(taskServiceProvider).getTasks();
});

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  final Map<String, Timer> _activeTimers = {};
  final Map<String, int> _elapsedSeconds = {};

  @override
  void dispose() {
    for (var timer in _activeTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }

  void _startTimer(Task task, TaskService taskService) {
    if (_activeTimers.containsKey(task.id)) return;
    _elapsedSeconds[task.id] = _elapsedSeconds[task.id] ?? task.elapsedSeconds;

    final now = DateTime.now();
    if (task.startedAt == null) {
      taskService.updateTask(
        task.copyWith(startedAt: now, taskStatus: 'in_progress'),
      );
    }

    _activeTimers[task.id] = Timer.periodic(const Duration(seconds: 1), (
      timer,
    ) {
      setState(() {
        _elapsedSeconds[task.id] = (_elapsedSeconds[task.id] ?? 0) + 1;
      });
    });
  }

  void _stopTimer(Task task, TaskService taskService) async {
    _activeTimers[task.id]?.cancel();
    _activeTimers.remove(task.id);
    final currentSeconds = _elapsedSeconds[task.id] ?? task.elapsedSeconds;
    await taskService.updateTask(
      task.copyWith(elapsedSeconds: currentSeconds, taskStatus: 'paused'),
    );
    setState(() {});
  }

  String _formatTime(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
    final currentUser = ref.watch(authStateChangesProvider).value;
    final bool isManager = currentUser?.email == 'flupro@gmail.com';

    final tasksAsync = ref.watch(tasksStreamProvider);
    final taskService = ref.watch(taskServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isArabic ? 'إدارة المهام والأوقات' : 'Tasks & Time Tracker',
        ),
        backgroundColor: const Color(0xFF2979FF),
        foregroundColor: Colors.white,
      ),
      body: tasksAsync.when(
        data: (tasks) {
          if (tasks.isEmpty) {
            return Center(
              child: Text(isArabic ? 'لا توجد مهام حالياً' : 'No tasks'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              final isRunning = _activeTimers.containsKey(task.id);
              final seconds = _elapsedSeconds[task.id] ?? task.elapsedSeconds;
              final isCompleted = task.taskStatus == 'completed';

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              task.title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                decoration: isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                          Checkbox(
                            value: isCompleted,
                            onChanged: (val) async {
                              final bool completed = val ?? false;
                              await taskService.updateTask(
                                task.copyWith(
                                  isCompleted: completed,
                                  taskStatus: completed
                                      ? 'completed'
                                      : 'in_progress',
                                  completedAt: completed
                                      ? DateTime.now()
                                      : null,
                                ),
                              );

                              if (completed && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isArabic
                                          ? 'تم إنجاز المهمة بنجاح وإشعار المدير بذلك'
                                          : 'Task completed successfully and manager notified',
                                    ),
                                    backgroundColor: Colors.green,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        task.description,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(
                            Icons.person,
                            size: 16,
                            color: Color(0xFF2979FF),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${isArabic ? 'الموظف المعين:' : 'Assigned:'} ${task.assignedEmployee}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent,
                            ),
                          ),
                        ],
                      ),
                      if (task.startedAt != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${isArabic ? 'وقت البدء:' : 'Started At:'} ${task.startedAt.toString().substring(0, 16)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.timer,
                                size: 20,
                                color: Color(0xFF2979FF),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatTime(seconds),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isRunning
                                      ? Colors.orange
                                      : const Color(0xFF2979FF),
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () {
                                  if (isRunning) {
                                    _stopTimer(task, taskService);
                                  } else {
                                    _startTimer(task, taskService);
                                  }
                                },
                                icon: Icon(
                                  isRunning ? Icons.pause : Icons.play_arrow,
                                  size: 18,
                                ),
                                label: Text(
                                  isRunning
                                      ? (isArabic ? 'إيقاف' : 'Pause')
                                      : (isArabic ? 'بدء' : 'Start'),
                                ),
                              ),
                              if (isManager) ...[
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () => _showTaskDialog(
                                    context,
                                    ref,
                                    taskService,
                                    isArabic,
                                    existingTask: task,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  onPressed: () async =>
                                      await taskService.deleteTask(task.id),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: isManager
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFF2979FF),
              foregroundColor: Colors.white,
              onPressed: () =>
                  _showTaskDialog(context, ref, taskService, isArabic),
              icon: const Icon(Icons.add),
              label: Text(isArabic ? 'إضافة مهمة' : 'Add Task'),
            )
          : null,
    );
  }

  void _showTaskDialog(
    BuildContext context,
    WidgetRef ref,
    TaskService taskService,
    bool isArabic, {
    Task? existingTask,
  }) {
    final titleController = TextEditingController(
      text: existingTask?.title ?? '',
    );
    final descController = TextEditingController(
      text: existingTask?.description ?? '',
    );
    final employees = ref.read(employeesProvider);
    String selectedEmployee =
        existingTask?.assignedEmployee ??
        (employees.isNotEmpty ? employees[0].name : 'غير محدد');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(
            existingTask == null
                ? (isArabic ? 'إضافة مهمة' : 'Add Task')
                : (isArabic ? 'تعديل المهمة' : 'Edit Task'),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: isArabic ? 'العنوان' : 'Title',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: InputDecoration(
                    labelText: isArabic ? 'الوصف' : 'Description',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: employees.any((e) => e.name == selectedEmployee)
                      ? selectedEmployee
                      : null,
                  decoration: InputDecoration(
                    labelText: isArabic
                        ? 'الموظف المسؤول'
                        : 'Assigned Employee',
                  ),
                  items: employees
                      .map(
                        (emp) => DropdownMenuItem(
                          value: emp.name,
                          child: Text(emp.name),
                        ),
                      )
                      .toList(),
                  onChanged: (val) =>
                      setStateDialog(() => selectedEmployee = val ?? ''),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(isArabic ? 'إلغاء' : 'Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2979FF),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (titleController.text.trim().isNotEmpty) {
                  if (existingTask == null) {
                    final newTask = Task(
                      id: '',
                      title: titleController.text.trim(),
                      description: descController.text.trim(),
                      assignedEmployee: selectedEmployee,
                      isCompleted: false,
                      createdAt: DateTime.now(),
                    );
                    await taskService.addTask(newTask);
                  } else {
                    final updated = existingTask.copyWith(
                      title: titleController.text.trim(),
                      description: descController.text.trim(),
                      assignedEmployee: selectedEmployee,
                    );
                    await taskService.updateTask(updated);
                  }
                  Navigator.pop(ctx);
                }
              },
              child: Text(isArabic ? 'حفظ' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}
