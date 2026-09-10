import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../tasks/tasks_screen.dart';
import '../settings/settings_provider.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
    final tasksAsync = ref.watch(tasksStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'تقارير الأداء والإحصائيات' : 'Performance Reports'),
        backgroundColor: const Color(0xFF2979FF),
        foregroundColor: Colors.white,
      ),
      body: tasksAsync.when(
        data: (tasks) {
          final totalTasks = tasks.length;
          final completedTasks = tasks.where((t) => t.isCompleted).length;
          final inProgressTasks = tasks.where((t) => !t.isCompleted).length;
          
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
                  isArabic ? 'نظرة عامة على النظام' : 'System Overview',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                      title: isArabic ? 'إجمالي المهام' : 'Total Tasks',
                      value: '$totalTasks',
                      icon: Icons.task_alt,
                      color: Colors.blue,
                    ),
                    _buildReportCard(
                      title: isArabic ? 'المهام المكتملة' : 'Completed',
                      value: '$completedTasks',
                      icon: Icons.check_circle,
                      color: Colors.green,
                    ),
                    _buildReportCard(
                      title: isArabic ? 'قيد التنفيذ' : 'In Progress',
                      value: '$inProgressTasks',
                      icon: Icons.hourglass_top,
                      color: Colors.orange,
                    ),
                    _buildReportCard(
                      title: isArabic ? 'إجمالي الساعات' : 'Total Hours',
                      value: '$totalHours س',
                      icon: Icons.access_time_filled,
                      color: Colors.purple,
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Text(
                  isArabic ? 'سجل الأداء والوقت المستغرق' : 'Performance & Time Log',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                tasks.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text(
                            isArabic ? 'لا توجد سجلات متاحة حالياً' : 'No records available',
                            style: TextStyle(color: Colors.grey.shade600),
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
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: task.isCompleted ? Colors.green.shade100 : Colors.orange.shade100,
                                child: Icon(
                                  task.isCompleted ? Icons.check : Icons.timer,
                                  color: task.isCompleted ? Colors.green : Colors.orange,
                                ),
                              ),
                              title: Text(task.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                '${isArabic ? 'المسؤول:' : 'Assigned:'} ${task.assignedEmployee}',
                                style: TextStyle(color: Colors.grey.shade600),
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
      ),
    );
  }

  Widget _buildReportCard({required String title, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}