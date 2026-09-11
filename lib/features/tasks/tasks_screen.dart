import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'task_service.dart';
import '../../models/task_model.dart';
import '../auth/auth_repository.dart';
import '../settings/settings_provider.dart';
import '../employees/employees_screen.dart';
import '../reports/reports_screen.dart';

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
  
  String _searchQuery = '';
  String _selectedStatusFilter = 'all';

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
    final permissionsAsync = ref.watch(userDetailedPermissionsProvider);
    final userRoleAsync = ref.watch(userRoleProvider);
    final currentUser = ref.watch(authStateChangesProvider).value;

    final tasksAsync = ref.watch(tasksStreamProvider);
    final taskService = ref.watch(taskServiceProvider);
    final employees = ref.watch(employeesProvider);

    return permissionsAsync.when(
      data: (permissions) {
        return userRoleAsync.when(
          data: (role) {
            final bool isManagerAccount = currentUser?.email == 'flupro@gmail.com' || role == 'مدير نظام';
            
            final bool canViewAllTasks = (permissions['add_task'] == true) || 
                                       (permissions['delete_task'] == true) || 
                                       (permissions['view_comprehensive_reports'] == true) || 
                                       isManagerAccount;
                                       
            final bool canAddTask = permissions['add_task'] == true || isManagerAccount;
            final bool canEditTask = permissions['edit_task'] == true || isManagerAccount;
            final bool canDeleteTask = permissions['delete_task'] == true || isManagerAccount;

            String currentEmployeeName = '';
            if (currentUser != null) {
              final matchedEmp = employees.firstWhere(
                (e) => e.email == currentUser.email,
                orElse: () => Employee(
                  id: '',
                  name: currentUser.email ?? '',
                  email: currentUser.email ?? '',
                  role: '',
                  permissions: {},
                ),
              );
              currentEmployeeName = matchedEmp.name;
            }

            return Scaffold(
              appBar: AppBar(
                title: Text(
                  isArabic ? 'إدارة المهام والأوقات' : 'Tasks & Time Tracker',
                ),
                backgroundColor: const Color(0xFF2979FF),
                foregroundColor: Colors.white,
              ),
              body: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    color: Colors.grey.shade100,
                    child: Column(
                      children: [
                        TextField(
                          onChanged: (val) => setState(() => _searchQuery = val),
                          decoration: InputDecoration(
                            hintText: isArabic ? 'بحث باسم الموظف أو عنوان المهمة...' : 'Search by employee or task title...',
                            prefixIcon: const Icon(Icons.search, color: Color(0xFF2979FF)),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterChip('all', isArabic ? 'الكل' : 'All'),
                              _buildFilterChip('completed', isArabic ? 'تم الإنجاز' : 'Completed'),
                              _buildFilterChip('in_progress', isArabic ? 'قيد التنفيذ' : 'In Progress'),
                              _buildFilterChip('paused', isArabic ? 'متوقفة' : 'Paused'),
                              _buildFilterChip('not_started', isArabic ? 'لم تبدأ' : 'Not Started'),
                              _buildFilterChip('modified', isArabic ? 'تم النقل/معدلة' : 'Transferred/Modified'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: tasksAsync.when(
                      data: (allTasks) {
                        var tasks = canViewAllTasks
                            ? allTasks
                            : allTasks.where((task) => task.assignedEmployee == currentEmployeeName).toList();

                        if (_searchQuery.trim().isNotEmpty) {
                          final query = _searchQuery.trim().toLowerCase();
                          tasks = tasks.where((t) =>
                              t.title.toLowerCase().contains(query) ||
                              t.assignedEmployee.toLowerCase().contains(query) ||
                              t.description.toLowerCase().contains(query)).toList();
                        }

                        if (_selectedStatusFilter != 'all') {
                          tasks = tasks.where((t) {
                            if (_selectedStatusFilter == 'completed') return t.isCompleted || t.taskStatus == 'completed';
                            if (_selectedStatusFilter == 'in_progress') return t.taskStatus == 'in_progress';
                            if (_selectedStatusFilter == 'paused') return t.taskStatus == 'paused';
                            if (_selectedStatusFilter == 'not_started') return t.taskStatus == 'not_started';
                            if (_selectedStatusFilter == 'modified') return t.isModified;
                            return true;
                          }).toList();
                        }

                        if (tasks.isEmpty) {
                          return Center(
                            child: Text(
                              isArabic ? 'لا توجد مهام مطابقة للبحث' : 'No matching tasks found',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: tasks.length,
                          itemBuilder: (context, index) {
                            final task = tasks[index];
                            final isRunning = _activeTimers.containsKey(task.id);
                            final seconds = _elapsedSeconds[task.id] ?? task.elapsedSeconds;
                            final isCompleted = task.taskStatus == 'completed' || task.isCompleted;

                            final bool isAssignedToMe = task.assignedEmployee == currentEmployeeName || isManagerAccount;

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
                                        if (isAssignedToMe)
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
                                                          ? 'تم إنجاز المهمة بنجاح'
                                                          : 'Task completed successfully',
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
                                    if (task.isModified && task.modificationLog.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          task.modificationLog,
                                          style: const TextStyle(fontSize: 12, color: Colors.blueAccent),
                                        ),
                                      ),
                                    ],
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
                                            if (isAssignedToMe) ...[
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
                                              const SizedBox(width: 4),
                                            ],
                                            if (canEditTask)
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.edit_outlined,
                                                  color: Colors.blue,
                                                ),
                                                tooltip: isArabic ? 'تعديل المهمة' : 'Edit Task',
                                                onPressed: () => _showTaskDialog(
                                                  context,
                                                  ref,
                                                  taskService,
                                                  isArabic,
                                                  existingTask: task,
                                                ),
                                              ),
                                            if (canDeleteTask)
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.delete_outline,
                                                  color: Colors.red,
                                                ),
                                                tooltip: isArabic ? 'حذف المهمة' : 'Delete Task',
                                                onPressed: () async =>
                                                    await taskService.deleteTask(task.id),
                                              ),
                                            if (!isAssignedToMe && !canEditTask && !canDeleteTask) ...[
                                              Text(
                                                isArabic ? 'للمراقبة فقط' : 'Monitor only',
                                                style: TextStyle(
                                                  color: Colors.grey.shade500,
                                                  fontSize: 12,
                                                  fontStyle: FontStyle.italic,
                                                ),
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
                  ),
                ],
              ),
              floatingActionButton: canAddTask
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
          },
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (_, __) => const Scaffold(body: Center(child: Text('Error'))),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const Scaffold(body: Center(child: Text('Error'))),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedStatusFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black87)),
        selected: isSelected,
        selectedColor: const Color(0xFF2979FF),
        backgroundColor: Colors.white,
        onSelected: (selected) {
          setState(() => _selectedStatusFilter = value);
        },
      ),
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
    
    // جلب الموظفين وتصفية المعتمدين فقط لإسناد المهام
    final allEmployees = ref.read(employeesProvider);
    final employees = allEmployees.where((e) => e.isApproved).toList();

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
                        ? 'الموظف المسؤول (المعتمدون فقط)'
                        : 'Assigned Employee (Approved Only)',
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
                    bool employeeChanged = existingTask.assignedEmployee != selectedEmployee;
                    
                    if (employeeChanged) {
                      final oldTaskRecord = existingTask.copyWith(
                        id: '',
                        modificationLog: isArabic 
                            ? 'تمت تأدية جزء بواسطة ${existingTask.assignedEmployee} (${(existingTask.elapsedSeconds / 60).toStringAsFixed(1)} دقيقة) ثم نقلت' 
                            : 'Partially done by ${existingTask.assignedEmployee} then reassigned',
                        isModified: true,
                      );
                      await taskService.addTask(oldTaskRecord);

                      final newAssignedTask = existingTask.copyWith(
                        title: titleController.text.trim(),
                        description: descController.text.trim(),
                        assignedEmployee: selectedEmployee,
                        elapsedSeconds: 0,
                        startedAt: null,
                        completedAt: null,
                        isCompleted: false,
                        taskStatus: 'not_started',
                        isModified: true,
                        lastModifiedAt: DateTime.now(),
                        modificationLog: isArabic 
                            ? 'استلمها الموظف الجديد $selectedEmployee من ${existingTask.assignedEmployee}' 
                            : 'Assigned to new employee $selectedEmployee from ${existingTask.assignedEmployee}',
                      );
                      await taskService.updateTask(newAssignedTask);
                    } else {
                      final updated = existingTask.copyWith(
                        title: titleController.text.trim(),
                        description: descController.text.trim(),
                        isModified: true,
                        lastModifiedAt: DateTime.now(),
                        modificationLog: isArabic ? 'تم تعديل تفاصيل المهمة' : 'Task details updated',
                      );
                      await taskService.updateTask(updated);
                    }
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