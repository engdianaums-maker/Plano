import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plano/features/auth/auth_repository.dart';
import 'package:plano/features/settings/settings_provider.dart';
import 'package:plano/features/settings/settings_screen.dart';
import 'package:plano/features/employees/employees_screen.dart';
import 'package:plano/features/reports/reports_screen.dart';
import 'package:plano/features/profile/profile_screen.dart';
import 'package:plano/features/tasks/tasks_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
    final user = ref.watch(authStateChangesProvider).value;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // المدير الخارق الأساسي
    if (user.email == 'flupro@gmail.com') {
      return _buildScaffold(context, ref, true, isArabic);
    }

    // مراقبة وثيقة المستخدم في فايربيس بشكل لحظي
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final String role = data['role'] ?? 'موظف عادي';
        final Map<String, dynamic> rawPerms = data['permissions'] ?? {};

        // الشرط الشامل: إذا كان دوره "مدير نظام" أو يملك صلاحية تخص الموظفين
        final bool isManagerRole = role == 'مدير نظام';
        final bool canManageEmployees = isManagerRole ||
            (rawPerms['add_employee'] == true) ||
            (rawPerms['edit_employee'] == true) ||
            (rawPerms['delete_employee'] == true);

        return _buildScaffold(context, ref, canManageEmployees, isArabic);
      },
    );
  }

  Widget _buildScaffold(BuildContext context, WidgetRef ref, bool canManageEmployees, bool isArabic) {
    final List<Widget> screens = canManageEmployees
        ? const [
            TasksScreen(),
            EmployeesScreen(),
            ReportsScreen(),
            ProfileScreen(),
          ]
        : const [
            TasksScreen(),
            ReportsScreen(),
            ProfileScreen(),
          ];

    final List<BottomNavigationBarItem> navItems = canManageEmployees
        ? [
            BottomNavigationBarItem(
              icon: const Icon(Icons.task_alt),
              label: isArabic ? 'المهام' : 'Tasks',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.group),
              label: isArabic ? 'الموظفون' : 'Employees',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.bar_chart),
              label: isArabic ? 'التقارير' : 'Reports',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person),
              label: isArabic ? 'حسابي' : 'Profile',
            ),
          ]
        : [
            BottomNavigationBarItem(
              icon: const Icon(Icons.task_alt),
              label: isArabic ? 'المهام' : 'Tasks',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.bar_chart),
              label: isArabic ? 'التقارير' : 'Reports',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person),
              label: isArabic ? 'حسابي' : 'Profile',
            ),
          ];

    if (_currentIndex >= screens.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF2979FF),
        unselectedItemColor: Colors.grey,
        items: navItems,
      ),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2979FF),
        elevation: 0,
        title: Text(
          canManageEmployees 
              ? (isArabic ? 'لوحة تحكم الإدارة (Plano)' : 'Management Dashboard') 
              : (isArabic ? 'لوحة تحكم الموظف (Plano)' : 'Employee Dashboard'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            tooltip: isArabic ? 'الإعدادات' : 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: isArabic ? 'تسجيل الخروج' : 'Logout',
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}