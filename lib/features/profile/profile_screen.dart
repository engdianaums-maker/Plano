import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_repository.dart';
import '../settings/settings_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
    final user = ref.watch(authStateChangesProvider).value;
    final bool isManager = user?.email == 'flupro@gmail.com';
    final theme = Theme.of(context);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: const Color(0xFF2979FF).withValues(alpha: 0.15),
                child: const Icon(Icons.person, size: 60, color: Color(0xFF2979FF)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isManager ? (isArabic ? 'مدير النظام (Manager)' : 'Manager') : (isArabic ? 'موظف' : 'Employee'),
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
            ),
            const SizedBox(height: 6),
            Text(user?.email ?? 'N/A', style: TextStyle(fontSize: 15, color: Colors.grey.shade500)),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.email_outlined, color: Color(0xFF2979FF)),
                    title: Text(isArabic ? 'البريد الإلكتروني' : 'Email', style: TextStyle(color: theme.colorScheme.onSurface)),
                    subtitle: Text(user?.email ?? 'N/A', style: TextStyle(color: Colors.grey.shade500)),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.admin_panel_settings_outlined, color: Color(0xFF2979FF)),
                    title: Text(isArabic ? 'نوع الحساب والصلاحيات' : 'Account Type', style: TextStyle(color: theme.colorScheme.onSurface)),
                    subtitle: Text(
                      isManager 
                          ? (isArabic ? 'مدير (صلاحيات كاملة الإضافة والتعديل والحذف)' : 'Admin Access') 
                          : (isArabic ? 'موظف (عرض وتتبع فقط)' : 'Employee Access'),
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () async => await ref.read(authRepositoryProvider).signOut(),
                icon: const Icon(Icons.logout),
                label: Text(isArabic ? 'تسجيل الخروج' : 'Logout', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}