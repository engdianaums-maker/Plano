import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/auth_repository.dart';
import '../settings/settings_provider.dart';

class Employee {
  final String id;
  final String name;
  final String email;
  final String role;
  final Map<String, bool> permissions;
  final bool isApproved;

  Employee({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.permissions,
    this.isApproved = false,
  });

  Employee copyWith({
    String? name,
    String? email,
    String? role,
    Map<String, bool>? permissions,
    bool? isApproved,
  }) {
    return Employee(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      isApproved: isApproved ?? this.isApproved,
    );
  }
}

class EmployeesNotifier extends Notifier<List<Employee>> {
  @override
  List<Employee> build() {
    _fetchUsersFromFirestore();
    return [];
  }

  Future<void> _fetchUsersFromFirestore() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    final loadedEmployees = snapshot.docs.map((doc) {
      final data = doc.data();
      
      Map<String, dynamic> rawPerms = data['permissions'] ?? {};
      Map<String, bool> parsedPerms = {
        'add_employee': rawPerms['add_employee'] ?? false,
        'edit_employee': rawPerms['edit_employee'] ?? false,
        'delete_employee': rawPerms['delete_employee'] ?? false,
        'add_task': rawPerms['add_task'] ?? false,
        'edit_task': rawPerms['edit_task'] ?? false,
        'delete_task': rawPerms['delete_task'] ?? false,
        'view_comprehensive_reports': rawPerms['view_comprehensive_reports'] ?? false,
        'view_personal_reports_only': rawPerms['view_personal_reports_only'] ?? true,
      };

      return Employee(
        id: doc.id,
        name: data['name'] ?? '',
        email: data['email'] ?? '',
        role: data['role'] ?? 'موظف عادي',
        permissions: parsedPerms,
        isApproved: data['isApproved'] ?? false,
      );
    }).toList();
    state = loadedEmployees;
  }

  Future<void> approveEmployee(String id, String role, Map<String, bool> permissions) async {
    await FirebaseFirestore.instance.collection('users').doc(id).update({
      'isApproved': true,
      'role': role,
      'permissions': permissions,
    });
    state = state.map((emp) {
      if (emp.id == id) {
        return emp.copyWith(isApproved: true, role: role, permissions: permissions);
      }
      return emp;
    }).toList();
  }

  // إلغاء الاعتماد وإزالته من القائمة مع بقائه في النظام
  Future<void> unapproveEmployee(String id) async {
    await FirebaseFirestore.instance.collection('users').doc(id).update({
      'isApproved': false,
    });
    state = state.map((emp) {
      if (emp.id == id) {
        return emp.copyWith(isApproved: false);
      }
      return emp;
    }).toList();
  }

  Future<void> updateEmployee(String id, String name, String email, String role, Map<String, bool> permissions) async {
    await FirebaseFirestore.instance.collection('users').doc(id).update({
      'name': name,
      'email': email,
      'role': role,
      'permissions': permissions,
    });
    state = state.map((emp) {
      if (emp.id == id) {
        return emp.copyWith(name: name, email: email, role: role, permissions: permissions);
      }
      return emp;
    }).toList();
  }

  Future<void> deleteEmployee(String id) async {
    await FirebaseFirestore.instance.collection('users').doc(id).delete();
    state = state.where((emp) => emp.id != id).toList();
  }
}

final employeesProvider = NotifierProvider<EmployeesNotifier, List<Employee>>(() {
  return EmployeesNotifier();
});

class EmployeesScreen extends ConsumerStatefulWidget {
  const EmployeesScreen({super.key});

  @override
  ConsumerState<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends ConsumerState<EmployeesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  String _searchQuery = '';
  String _selectedRoleFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
    final currentUser = ref.watch(authStateChangesProvider).value;
    final employees = ref.watch(employeesProvider);
    final theme = Theme.of(context);

    final bool isManagerAccount = currentUser?.email == 'flupro@gmail.com';
    
    bool canManage = isManagerAccount;
    if (!isManagerAccount && currentUser != null) {
      final currentEmp = employees.firstWhere(
        (e) => e.email == currentUser.email,
        orElse: () => Employee(id: '', name: '', email: '', role: '', permissions: {}),
      );
      canManage = currentEmp.role == 'مدير نظام' ||
          (currentEmp.permissions['add_employee'] == true) ||
          (currentEmp.permissions['edit_employee'] == true) ||
          (currentEmp.permissions['delete_employee'] == true);
    }

    var filteredList = employees.where((e) {
      final matchesSearch = _searchQuery.isEmpty ||
          e.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.email.toLowerCase().contains(_searchQuery.toLowerCase());

      bool matchesRole = true;
      if (_selectedRoleFilter == 'manager') {
        matchesRole = e.role == 'مدير نظام';
      } else if (_selectedRoleFilter == 'normal') {
        matchesRole = e.role != 'مدير نظام';
      }

      return matchesSearch && matchesRole;
    }).toList();

    final approvedEmployees = filteredList.where((e) => e.isApproved).toList();
    final pendingEmployees = employees.where((e) => !e.isApproved).toList();

    return Scaffold(
      appBar: canManage ? TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF2979FF),
        unselectedLabelColor: Colors.grey,
        indicatorColor: const Color(0xFF2979FF),
        tabs: [
          Tab(text: isArabic ? 'الموظفون المعتمدون' : 'Approved Employees'),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(isArabic ? 'طلبات الانتظار' : 'Pending Requests'),
                if (pendingEmployees.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: Colors.orange,
                    child: Text(
                      '${pendingEmployees.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ) : null,
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
                    hintText: isArabic ? 'بحث باسم الموظف أو البريد الإلكتروني...' : 'Search by employee name or email...',
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
                Row(
                  children: [
                    Text(
                      isArabic ? 'فلتر الدور: ' : 'Role Filter: ',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    _buildRoleChip('all', isArabic ? 'الكل' : 'All'),
                    const SizedBox(width: 6),
                    _buildRoleChip('manager', isArabic ? 'مدير' : 'Manager'),
                    const SizedBox(width: 6),
                    _buildRoleChip('normal', isArabic ? 'موظف عادي' : 'Normal Employee'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: canManage ? TabBarView(
              controller: _tabController,
              children: [
                _buildEmployeesList(approvedEmployees, canManage, isArabic, theme),
                _buildEmployeesList(pendingEmployees, canManage, isArabic, theme),
              ],
            ) : _buildEmployeesList(approvedEmployees, canManage, isArabic, theme),
          ),
        ],
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFF2979FF),
              foregroundColor: Colors.white,
              onPressed: () => _showEmployeeDialog(context, ref, isArabic),
              icon: const Icon(Icons.person_add),
              label: Text(isArabic ? 'اختيار واعتماد موظف' : 'Select & Add Employee'),
            )
          : null,
    );
  }

  Widget _buildRoleChip(String value, String label) {
    final isSelected = _selectedRoleFilter == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black87)),
      selected: isSelected,
      selectedColor: const Color(0xFF2979FF),
      backgroundColor: Colors.white,
      onSelected: (selected) {
        setState(() => _selectedRoleFilter = value);
      },
    );
  }

  Widget _buildEmployeesList(List<Employee> list, bool canManage, bool isArabic, ThemeData theme) {
    if (list.isEmpty) {
      return Center(
        child: Text(
          isArabic ? 'لا توجد بيانات مطابقة' : 'No data available',
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final emp = list[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF2979FF).withValues(alpha: 0.15),
              child: Text(
                emp.name.isNotEmpty ? emp.name[0] : '?',
                style: const TextStyle(color: Color(0xFF2979FF), fontWeight: FontWeight.bold),
              ),
            ),
            title: Row(
              children: [
                Text(emp.name, style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                if (!emp.isApproved) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isArabic ? 'بانتظار الموافقة' : 'Pending',
                      style: const TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
            subtitle: Text('${emp.email} • ${emp.role}', style: TextStyle(color: Colors.grey.shade500)),
            trailing: canManage
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!emp.isApproved)
                        IconButton(
                          icon: const Icon(Icons.check_circle, color: Colors.green),
                          tooltip: isArabic ? 'موافقة وتحديد الصلاحيات' : 'Approve & Set Permissions',
                          onPressed: () => _showApprovalRoleDialog(context, ref, emp, isArabic),
                        ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                        onPressed: () => _showEmployeeDialog(context, ref, isArabic, existingEmployee: emp),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        tooltip: isArabic ? 'خيارات الحذف أو الإزالة' : 'Delete or Remove options',
                        onPressed: () => _showDeleteOptionsDialog(context, ref, emp, isArabic),
                      ),
                    ],
                  )
                : null,
          ),
        );
      },
    );
  }

  void _showDeleteOptionsDialog(BuildContext context, WidgetRef ref, Employee emp, bool isArabic) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isArabic ? 'خيارات الحذف للموظف' : 'Employee Removal Options'),
        content: Text(
          isArabic 
              ? 'هل تريد إزالة الموظف من القائمة (مع إبقائه في النظام ليتم اعتماده لاحقاً)، أم حذفه نهائياً من فايربيس؟' 
              : 'Do you want to remove him from the list, or delete him permanently from Firebase?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(foregroundColor: Colors.orange),
            onPressed: () {
              ref.read(employeesProvider.notifier).unapproveEmployee(emp.id);
              Navigator.pop(ctx);
            },
            child: Text(isArabic ? 'إزالة من القائمة فقط' : 'Remove from list'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              ref.read(employeesProvider.notifier).deleteEmployee(emp.id);
              Navigator.pop(ctx);
            },
            child: Text(isArabic ? 'حذف نهائي' : 'Delete Permanently'),
          ),
        ],
      ),
    );
  }

  void _showApprovalRoleDialog(BuildContext context, WidgetRef ref, Employee emp, bool isArabic) {
    final List<String> availableRoles = ['موظف عادي', 'مدير نظام'];
    String selectedRole = emp.role.isNotEmpty ? emp.role : availableRoles[0];

    Map<String, bool> permissions = Map.from(emp.permissions);
    if (permissions.isEmpty) {
      permissions = {
        'add_employee': selectedRole == 'مدير نظام',
        'edit_employee': selectedRole == 'مدير نظام',
        'delete_employee': selectedRole == 'مدير نظام',
        'add_task': selectedRole == 'مدير نظام',
        'edit_task': selectedRole == 'مدير نظام',
        'delete_task': selectedRole == 'مدير نظام',
        'view_comprehensive_reports': selectedRole == 'مدير نظام',
        'view_personal_reports_only': selectedRole != 'مدير نظام',
      };
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(isArabic ? 'تحديد الصلاحيات والموافقة' : 'Approve & Set Permissions'),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${isArabic ? 'الموظف:' : 'Employee:'} ${emp.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: InputDecoration(labelText: isArabic ? 'الدور العام' : 'General Role'),
                    items: availableRoles.map((role) {
                      return DropdownMenuItem(value: role, child: Text(role));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setStateDialog(() {
                          selectedRole = val;
                          bool isMgr = val == 'مدير نظام';
                          permissions['add_employee'] = isMgr;
                          permissions['edit_employee'] = isMgr;
                          permissions['delete_employee'] = isMgr;
                          permissions['add_task'] = isMgr;
                          permissions['edit_task'] = isMgr;
                          permissions['delete_task'] = isMgr;
                          permissions['view_comprehensive_reports'] = isMgr;
                          permissions['view_personal_reports_only'] = !isMgr;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isArabic ? 'صلاحيات التحكم المخصصة:' : 'Detailed Permissions:',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueAccent),
                  ),
                  const SizedBox(height: 8),
                  _buildPermissionCheckbox('add_employee', isArabic ? 'إضافة موظف' : 'Add Employee', permissions, setStateDialog),
                  _buildPermissionCheckbox('edit_employee', isArabic ? 'تعديل موظف' : 'Edit Employee', permissions, setStateDialog),
                  _buildPermissionCheckbox('delete_employee', isArabic ? 'حذف موظف' : 'Delete Employee', permissions, setStateDialog),
                  _buildPermissionCheckbox('add_task', isArabic ? 'إضافة مهمة' : 'Add Task', permissions, setStateDialog),
                  _buildPermissionCheckbox('edit_task', isArabic ? 'تعديل مهمة' : 'Edit Task', permissions, setStateDialog),
                  _buildPermissionCheckbox('delete_task', isArabic ? 'حذف مهمة' : 'Delete Task', permissions, setStateDialog),
                  _buildPermissionCheckbox('view_comprehensive_reports', isArabic ? 'رؤية تقارير كاملة' : 'Comprehensive Reports', permissions, setStateDialog),
                  _buildPermissionCheckbox('view_personal_reports_only', isArabic ? 'رؤية تقارير خاصة بالمقاطع الخاصة بالموظف فقط' : 'Personal Reports Only', permissions, setStateDialog),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isArabic ? 'إلغاء' : 'Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2979FF), foregroundColor: Colors.white),
              onPressed: () async {
                await ref.read(employeesProvider.notifier).approveEmployee(emp.id, selectedRole, permissions);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(isArabic ? 'موافقة واعتماد' : 'Approve'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEmployeeDialog(BuildContext context, WidgetRef ref, bool isArabic, {Employee? existingEmployee}) {
    final allEmployees = ref.read(employeesProvider);
    
    String selectedEmail = existingEmployee?.email ?? (allEmployees.isNotEmpty ? allEmployees[0].email : '');
    String selectedName = existingEmployee?.name ?? (allEmployees.isNotEmpty ? allEmployees[0].name : '');

    final List<String> availableRoles = ['موظف عادي', 'مدير نظام'];
    String selectedRole = existingEmployee?.role.isNotEmpty == true ? existingEmployee!.role : availableRoles[0];

    Map<String, bool> permissions = Map.from(existingEmployee?.permissions ?? {
      'add_employee': selectedRole == 'مدير نظام',
      'edit_employee': selectedRole == 'مدير نظام',
      'delete_employee': selectedRole == 'مدير نظام',
      'add_task': selectedRole == 'مدير نظام',
      'edit_task': selectedRole == 'مدير نظام',
      'delete_task': selectedRole == 'مدير نظام',
      'view_comprehensive_reports': selectedRole == 'مدير نظام',
      'view_personal_reports_only': selectedRole != 'مدير نظام',
    });

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(existingEmployee == null 
              ? (isArabic ? 'اختيار واعتماد موظف من النظام' : 'Select & Approve Employee') 
              : (isArabic ? 'تعديل صلاحيات الموظف' : 'Edit Employee Permissions')),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (existingEmployee == null) ...[
                    Text(
                      isArabic ? 'اختر الموظف المسجل في النظام:' : 'Select registered employee:',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedEmail.isNotEmpty ? selectedEmail : null,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: allEmployees.map((emp) {
                        return DropdownMenuItem(
                          value: emp.email,
                          child: Text('${emp.name} (${emp.email})'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          final chosen = allEmployees.firstWhere((e) => e.email == val);
                          setStateDialog(() {
                            selectedEmail = chosen.email;
                            selectedName = chosen.name;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16.0),
                  ] else ...[
                    Text('${isArabic ? 'الموظف:' : 'Employee:'} $selectedName', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('${isArabic ? 'البريد:' : 'Email:'} $selectedEmail', style: TextStyle(color: Colors.grey.shade600)),
                    const SizedBox(height: 16.0),
                  ],
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: InputDecoration(labelText: isArabic ? 'الدور العام' : 'General Role'),
                    items: availableRoles.map((role) {
                      return DropdownMenuItem(value: role, child: Text(role));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setStateDialog(() {
                          selectedRole = val;
                          bool isMgr = val == 'مدير نظام';
                          permissions['add_employee'] = isMgr;
                          permissions['edit_employee'] = isMgr;
                          permissions['delete_employee'] = isMgr;
                          permissions['add_task'] = isMgr;
                          permissions['edit_task'] = isMgr;
                          permissions['delete_task'] = isMgr;
                          permissions['view_comprehensive_reports'] = isMgr;
                          permissions['view_personal_reports_only'] = !isMgr;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isArabic ? 'صلاحيات التحكم المخصصة:' : 'Detailed Permissions:',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueAccent),
                  ),
                  const SizedBox(height: 8),
                  _buildPermissionCheckbox('add_employee', isArabic ? 'إضافة موظف' : 'Add Employee', permissions, setStateDialog),
                  _buildPermissionCheckbox('edit_employee', isArabic ? 'تعديل موظف' : 'Edit Employee', permissions, setStateDialog),
                  _buildPermissionCheckbox('delete_employee', isArabic ? 'حذف موظف' : 'Delete Employee', permissions, setStateDialog),
                  _buildPermissionCheckbox('add_task', isArabic ? 'إضافة مهمة' : 'Add Task', permissions, setStateDialog),
                  _buildPermissionCheckbox('edit_task', isArabic ? 'تعديل مهمة' : 'Edit Task', permissions, setStateDialog),
                  _buildPermissionCheckbox('delete_task', isArabic ? 'حذف مهمة' : 'Delete Task', permissions, setStateDialog),
                  _buildPermissionCheckbox('view_comprehensive_reports', isArabic ? 'رؤية تقارير كاملة' : 'Comprehensive Reports', permissions, setStateDialog),
                  _buildPermissionCheckbox('view_personal_reports_only', isArabic ? 'رؤية تقارير خاصة بالمقاطع الخاصة بالموظف فقط' : 'Personal Reports Only', permissions, setStateDialog),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isArabic ? 'إلغاء' : 'Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2979FF), foregroundColor: Colors.white),
              onPressed: () {
                if (selectedEmail.isNotEmpty) {
                  if (existingEmployee == null) {
                    final target = allEmployees.firstWhere((e) => e.email == selectedEmail);
                    ref.read(employeesProvider.notifier).approveEmployee(target.id, selectedRole, permissions);
                  } else {
                    ref.read(employeesProvider.notifier).updateEmployee(
                          existingEmployee.id,
                          selectedName,
                          selectedEmail,
                          selectedRole,
                          permissions,
                        );
                  }
                  Navigator.pop(ctx);
                }
              },
              child: Text(isArabic ? 'حفظ واعتماد' : 'Save & Approve'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionCheckbox(String key, String title, Map<String, bool> permissions, StateSetter setStateDialog) {
    return CheckboxListTile(
      title: Text(title, style: const TextStyle(fontSize: 13)),
      value: permissions[key] ?? false,
      onChanged: (val) => setStateDialog(() => permissions[key] = val ?? false),
      dense: true,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
    );
  }
}