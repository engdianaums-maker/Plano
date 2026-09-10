import 'package:flutter/material.dart';
import '../../features/auth/auth_gate.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/employees/employees_screen.dart';
import '../../features/reports/reports_screen.dart';
import '../../features/settings/settings_screen.dart';

class AppRouter {
  static const String authGate = '/';
  static const String dashboard = '/dashboard';
  static const String employees = '/employees';
  static const String reports = '/reports';
  static const String settings = '/settings';

  static Route<dynamic> generateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case authGate:
        return MaterialPageRoute(builder: (_) => const AuthGate());
      case dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      case employees:
        return MaterialPageRoute(builder: (_) => const EmployeesScreen());
      case reports:
        return MaterialPageRoute(builder: (_) => const ReportsScreen());
      case settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(
              child: Text('الصفحة غير موجودة'),
            ),
          ),
        );
    }
  }
}