import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_repository.dart';
import '../settings/settings_provider.dart';

class Employee {
  final String id;
  final String name;
  final String email;
  final String role;

  Employee({required this.id, required this.name, required this.email, required this.role});

  Employee copyWith({String? name, String? email, String? role}) {
    return Employee(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
    );
  }
}

class EmployeesNotifier extends Notifier<List<Employee>> {
  @override
  List<Employee> build() {
    return [
      Employee(id: '1', name: 'أحمد محمد', email: 'ahmed@proflu.com', role: 'مطور واجهات'),
      Employee(id: '2', name: 'سارة خالد', email: 'sara@proflu.com', role: 'مصممة UI/UX'),
    ];
  }

  void addEmployee(String name, String email, String role) {
    final newEmp = Employee(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      email: email,
      role: role,
    );
    state = [...state, newEmp];
  }

  void updateEmployee(String id, String name, String email, String role) {
    state = state.map((emp) {
      if (emp.id == id) {
        return emp.copyWith(name: name, email: email, role: role);
      }
      return emp;
    }).toList();
  }

  void deleteEmployee(String id) {
    state = state.where((emp) => emp.id != id).toList();
  }
}

final employeesProvider = NotifierProvider<EmployeesNotifier, List<Employee>>(() {
  return EmployeesNotifier();
});

class EmployeesScreen extends ConsumerWidget {
  const EmployeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
    final currentUser = ref.watch(authStateChangesProvider).value;
    final bool isManager = currentUser?.email == 'flupro@gmail.com';
    final employees = ref.watch(employeesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: employees.isEmpty
          ? Center(child: Text(isArabic ? 'لا يوجد موظفون' : 'No employees', style: TextStyle(color: theme.colorScheme.onSurface)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: employees.length,
              itemBuilder: (context, index) {
                final emp = employees[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF2979FF).withValues(alpha: 0.15),
                      child: Text(emp.name[0], style: const TextStyle(color: Color(0xFF2979FF), fontWeight: FontWeight.bold)),
                    ),
                    title: Text(emp.name, style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                    subtitle: Text('${emp.email} • ${emp.role}', style: TextStyle(color: Colors.grey.shade500)),
                    trailing: isManager
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                onPressed: () => _showEmployeeDialog(context, ref, isArabic, existingEmployee: emp),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => ref.read(employeesProvider.notifier).deleteEmployee(emp.id),
                              ),
                            ],
                          )
                        : null,
                  ),
                );
              },
            ),
      floatingActionButton: isManager
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFF2979FF),
              foregroundColor: Colors.white,
              onPressed: () => _showEmployeeDialog(context, ref, isArabic),
              icon: const Icon(Icons.person_add),
              label: Text(isArabic ? 'إضافة موظف' : 'Add Employee'),
            )
          : null,
    );
  }

  void _showEmployeeDialog(BuildContext context, WidgetRef ref, bool isArabic, {Employee? existingEmployee}) {
    final nameController = TextEditingController(text: existingEmployee?.name ?? '');
    final emailController = TextEditingController(text: existingEmployee?.email ?? '');
    final roleController = TextEditingController(text: existingEmployee?.role ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existingEmployee == null 
            ? (isArabic ? 'إضافة موظف جديد' : 'Add Employee') 
            : (isArabic ? 'تعديل بيانات الموظف' : 'Edit Employee')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: isArabic ? 'الاسم' : 'Name')),
            const SizedBox(height: 10),
            TextField(controller: emailController, decoration: InputDecoration(labelText: isArabic ? 'البريد' : 'Email')),
            const SizedBox(height: 10),
            TextField(controller: roleController, decoration: InputDecoration(labelText: isArabic ? 'الدور الوظيفي' : 'Role')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isArabic ? 'إلغاء' : 'Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2979FF), foregroundColor: Colors.white),
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                if (existingEmployee == null) {
                  ref.read(employeesProvider.notifier).addEmployee(
                        nameController.text.trim(),
                        emailController.text.trim(),
                        roleController.text.trim(),
                      );
                } else {
                  ref.read(employeesProvider.notifier).updateEmployee(
                        existingEmployee.id,
                        nameController.text.trim(),
                        emailController.text.trim(),
                        roleController.text.trim(),
                      );
                }
                Navigator.pop(ctx);
              }
            },
            child: Text(isArabic ? 'حفظ' : 'Save'),
          ),
        ],
      ),
    );
  }
}