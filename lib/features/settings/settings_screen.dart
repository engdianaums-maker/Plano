import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_repository.dart';
import 'settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    final bool isDarkMode = themeMode == ThemeMode.dark;
    final bool isArabic = locale.languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'إعدادات النظام' : 'System Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            isArabic ? 'التفضيلات العامة' : 'General Preferences',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4364F7)),
          ),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(isArabic ? 'الوضع الداكن (Dark Mode)' : 'Dark Mode'),
                  subtitle: Text(isArabic ? 'تغيير مظهر التطبيق إلى الألوان الداكنة' : 'Switch app theme to dark colors'),
                  secondary: const Icon(Icons.dark_mode, color: Color(0xFF4364F7)),
                  value: isDarkMode,
                  onChanged: (val) {
                    ref.read(themeModeProvider.notifier).toggleTheme(val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isArabic ? 'اللغة والمنطقة' : 'Language & Region',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4364F7)),
          ),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.language, color: Color(0xFF4364F7)),
              title: Text(isArabic ? 'لغة التطبيق' : 'App Language'),
              subtitle: Text(isArabic ? 'العربية' : 'English'),
              trailing: DropdownButton<String>(
                value: isArabic ? 'العربية' : 'English',
                underline: const SizedBox(),
                items: ['العربية', 'English'].map((lang) {
                  return DropdownMenuItem(
                    value: lang,
                    child: Text(lang),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    if (val == 'العربية') {
                      ref.read(localeProvider.notifier).setLocale(const Locale('ar'));
                    } else {
                      ref.read(localeProvider.notifier).setLocale(const Locale('en'));
                    }
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isArabic ? 'حساب المستخدم' : 'User Account',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4364F7)),
          ),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline, color: Color(0xFF4364F7)),
                  title: Text(isArabic ? 'إصدار النظام' : 'System Version'),
                  trailing: const Text('PROFLU v1.0.0', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: Text(
                    isArabic ? 'تسجيل الخروج من الحساب' : 'Logout',
                    style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                  ),
                  onTap: () async {
                    final authRepo = ref.read(authRepositoryProvider);
                    await authRepo.signOut();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}