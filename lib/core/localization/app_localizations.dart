import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const Map<String, Map<String, String>> _localizedValues = {
    'ar': {
      'appName': 'PROFLU',
      'dashboard': 'لوحة التحكم',
      'employees': 'الموظفون',
      'reports': 'التقارير',
      'settings': 'الإعدادات',
      'logout': 'تسجيل الخروج',
    },
    'en': {
      'appName': 'PROFLU',
      'dashboard': 'Dashboard',
      'employees': 'Employees',
      'reports': 'Reports',
      'settings': 'Settings',
      'logout': 'Logout',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
}