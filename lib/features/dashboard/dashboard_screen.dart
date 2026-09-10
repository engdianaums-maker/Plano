import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  // استخدام IndexedStack يحافظ على حالة كل شاشة عند التنقل بينها عبر الشريط السفلي
  final List<Widget> _screens = const [
    TasksScreen(),
    EmployeesScreen(),
    ReportsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
    final currentUser = ref.watch(authStateChangesProvider).value;
    final bool isManager = currentUser?.email == 'flupro@gmail.com';

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF2979FF),
        unselectedItemColor: Colors.grey,
        items: [
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
        ],
      ),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2979FF),
        elevation: 0,
        title: Text(
          isManager 
              ? (isArabic ? 'لوحة تحكم المدير (PROFLU)' : 'Manager Dashboard') 
              : (isArabic ? 'لوحة تحكم الموظف (PROFLU)' : 'Employee Dashboard'),
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