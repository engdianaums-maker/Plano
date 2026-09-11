import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../tasks/tasks_screen.dart';
import '../settings/settings_provider.dart';
import '../auth/auth_repository.dart';
import '../employees/employees_screen.dart';

final userDetailedPermissionsProvider = StreamProvider.autoDispose<Map<String, bool>>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return Stream.value({});
  
  if (user.email == 'flupro@gmail.com') {
    return Stream.value({
      'add_employee': true,
      'edit_employee': true,
      'delete_employee': true,
      'add_task': true,
      'edit_task': true,
      'delete_task': true,
      'view_comprehensive_reports': true,
      'view_personal_reports_only': false,
    });
  }

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((doc) {
        Map<String, dynamic> rawPerms = doc.data()?['permissions'] ?? {};
        return {
          'add_employee': rawPerms['add_employee'] ?? false,
          'edit_employee': rawPerms['edit_employee'] ?? false,
          'delete_employee': rawPerms['delete_employee'] ?? false,
          'add_task': rawPerms['add_task'] ?? false,
          'edit_task': rawPerms['edit_task'] ?? false,
          'delete_task': rawPerms['delete_task'] ?? false,
          'view_comprehensive_reports': rawPerms['view_comprehensive_reports'] ?? false,
          'view_personal_reports_only': rawPerms['view_personal_reports_only'] ?? true,
        };
      });
});

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String _selectedEmployeeFilter = 'all';
  String _selectedReportStatusFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
    final permissionsAsync = ref.watch(userDetailedPermissionsProvider);
    final employees = ref.watch(employeesProvider);
    final currentUser = ref.watch(authStateChangesProvider).value;

    return permissionsAsync.when(
      data: (permissions) {
        final bool showComprehensive = permissions['view_comprehensive_reports'] ?? false;
        final bool isManagerAccount = currentUser?.email == 'flupro@gmail.com';

        String currentEmployeeName = '';
        if (!showComprehensive && currentUser != null) {
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
            title: Text(isArabic ? 'تقارير الأداء والإحصائيات' : 'Performance Reports'),
            backgroundColor: const Color(0xFF2979FF),
            foregroundColor: Colors.white,
          ),
          body: Column(
            children: [
              // فلاتر التقارير (تظهر للمدير أو من لديه صلاحية تقارير شاملة)
              if (showComprehensive) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.grey.shade100,
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedEmployeeFilter,
                          decoration: InputDecoration(
                            labelText: isArabic ? 'تصفية حسب الموظف' : 'Filter by Employee',
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          items: [
                            DropdownMenuItem(value: 'all', child: Text(isArabic ? 'جميع الموظفين' : 'All Employees')),
                            ...employees.map((e) => DropdownMenuItem(value: e.name, child: Text(e.name))),
                          ],
                          onChanged: (val) => setState(() => _selectedEmployeeFilter = val ?? 'all'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedReportStatusFilter,
                          decoration: InputDecoration(
                            labelText: isArabic ? 'حالة المهام' : 'Task Status',
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          items: [
                            DropdownMenuItem(value: 'all', child: Text(isArabic ? 'جميع الحالات' : 'All Statuses')),
                            DropdownMenuItem(value: 'completed', child: Text(isArabic ? 'تم الإنجاز' : 'Completed')),
                            DropdownMenuItem(value: 'in_progress', child: Text(isArabic ? 'قيد التنفيذ' : 'In Progress')),
                            DropdownMenuItem(value: 'paused', child: Text(isArabic ? 'متوقفة' : 'Paused')),
                          ],
                          onChanged: (val) => setState(() => _selectedReportStatusFilter = val ?? 'all'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              Expanded(
                child: _ReportsContent(
                  showComprehensive: showComprehensive,
                  isManagerAccount: isManagerAccount,
                  currentEmployeeName: currentEmployeeName,
                  selectedEmployeeFilter: _selectedEmployeeFilter,
                  selectedReportStatusFilter: _selectedReportStatusFilter,
                  isArabic: isArabic,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Performance Reports')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Scaffold(
        appBar: AppBar(title: const Text('Performance Reports')),
        body: const Center(child: Text('Error loading permissions')),
      ),
    );
  }
}

class _ReportsContent extends ConsumerWidget {
  final bool showComprehensive;
  final bool isManagerAccount;
  final String currentEmployeeName;
  final String selectedEmployeeFilter;
  final String selectedReportStatusFilter;
  final bool isArabic;

  const _ReportsContent({
    required this.showComprehensive,
    required this.isManagerAccount,
    required this.currentEmployeeName,
    required this.selectedEmployeeFilter,
    required this.selectedReportStatusFilter,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksStreamProvider);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return tasksAsync.when(
      data: (allTasks) {
        // 1. تحديد الأساس (كل المهام إذا كان يملك صلاحية، أو مهامه الشخصية فقط)
        var tasks = showComprehensive
            ? allTasks
            : allTasks.where((task) => task.assignedEmployee == currentEmployeeName).toList();

        // 2. تطبيق فلتر الموظف المختار في التقارير
        if (showComprehensive && selectedEmployeeFilter != 'all') {
          tasks = tasks.where((t) => t.assignedEmployee == selectedEmployeeFilter).toList();
        }

        // 3. تطبيق فلتر حالة المهمة في التقارير
        if (selectedReportStatusFilter != 'all') {
          tasks = tasks.where((t) {
            if (selectedReportStatusFilter == 'completed') return t.isCompleted || t.taskStatus == 'completed';
            if (selectedReportStatusFilter == 'in_progress') return t.taskStatus == 'in_progress';
            if (selectedReportStatusFilter == 'paused') return t.taskStatus == 'paused';
            return true;
          }).toList();
        }

        final totalTasks = tasks.length;
        final completedTasks = tasks.where((t) => t.isCompleted || t.taskStatus == 'completed').length;
        final inProgressTasks = tasks.where((t) => !t.isCompleted && t.taskStatus != 'completed').length;
        
        int totalSeconds = 0;
        for (var t in tasks) {
          totalSeconds += t.elapsedSeconds;
        }
        final totalHours = (totalSeconds / 3600).toStringAsFixed(1);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isArabic ? 'نظرة عامة على الأداء' : 'Performance Overview',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.3,
                children: [
                  _buildReportCard(
                    context: context,
                    title: isArabic ? 'إجمالي المهام' : 'Total Tasks',
                    value: '$totalTasks',
                    icon: Icons.task_alt,
                    color: Colors.blue,
                  ),
                  _buildReportCard(
                    context: context,
                    title: isArabic ? 'المهام المكتملة' : 'Completed',
                    value: '$completedTasks',
                    icon: Icons.check_circle,
                    color: Colors.green,
                  ),
                  _buildReportCard(
                    context: context,
                    title: isArabic ? 'قيد التنفيذ' : 'In Progress',
                    value: '$inProgressTasks',
                    icon: Icons.hourglass_top,
                    color: Colors.orange,
                  ),
                  _buildReportCard(
                    context: context,
                    title: isArabic ? 'إجمالي الساعات' : 'Total Hours',
                    value: '$totalHours س',
                    icon: Icons.access_time_filled,
                    color: Colors.purple,
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Text(
                isArabic ? 'سجل الأداء والوقت المستغرق وفارق الأداء' : 'Performance, Time & Comparison Log',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              tasks.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          isArabic ? 'لا توجد سجلات مطابقة للفلتر' : 'No matching records',
                          style: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        final minutes = task.elapsedSeconds ~/ 60;
                        final isCompleted = task.isCompleted || task.taskStatus == 'completed';

                        String? timeDifferenceText;
                        if (isManagerAccount || showComprehensive) {
                          final sameTitleTasks = allTasks.where((t) => t.title == task.title && t.id != task.id).toList();
                          if (sameTitleTasks.isNotEmpty) {
                            final otherTask = sameTitleTasks.first;
                            final diffMinutes = (task.elapsedSeconds - otherTask.elapsedSeconds) ~/ 60;
                            final diffSign = diffMinutes >= 0 ? '+' : '';
                            timeDifferenceText = isArabic 
                                ? 'فارق الوقت عن ${otherTask.assignedEmployee}: $diffSign$diffMinutes دقيقة' 
                                : 'Time diff vs ${otherTask.assignedEmployee}: $diffSign$diffMinutes min';
                          }
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          color: theme.cardColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isCompleted 
                                  ? (isDarkMode ? Colors.green.shade900.withValues(alpha: 0.4) : Colors.green.shade100) 
                                  : (isDarkMode ? Colors.orange.shade900.withValues(alpha: 0.4) : Colors.orange.shade100),
                              child: Icon(
                                isCompleted ? Icons.check : Icons.timer,
                                color: isCompleted ? Colors.green : Colors.orange,
                              ),
                            ),
                            title: Text(
                              task.title, 
                              style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${isArabic ? 'المسؤول:' : 'Assigned:'} ${task.assignedEmployee}',
                                  style: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600),
                                ),
                                if (timeDifferenceText != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    timeDifferenceText,
                                    style: const TextStyle(fontSize: 11, color: Colors.blueAccent, fontWeight: FontWeight.w600),
                                  ),
                                ],
                                if (task.modificationLog.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    task.modificationLog,
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                                  ),
                                ],
                              ],
                            ),
                            trailing: Text(
                              '$minutes ${isArabic ? 'دقيقة' : 'min'}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2979FF)),
                            ),
                          ),
                        );
                      },
                    ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildReportCard({
    required BuildContext context,
    required String title, 
    required String value, 
    required IconData icon, 
    required Color color,
  }) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 12),
          Text(
            value, 
            style: TextStyle(
              fontSize: 22, 
              fontWeight: FontWeight.bold, 
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title, 
            style: TextStyle(
              fontSize: 13, 
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}