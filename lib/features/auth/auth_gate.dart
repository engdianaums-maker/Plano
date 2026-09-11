import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'login_screen.dart';
import '../dashboard/dashboard_screen.dart';
import 'pending_approval_screen.dart';
import 'auth_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const LoginScreen();
        }

        // المدير العام مستثنى ويدخل مباشرة
        if (user.email?.trim().toLowerCase() == 'flupro@gmail.com') {
          return const DashboardScreen();
        }

        // التحقق من حالة الموافقة من قاعدة البيانات
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.hasData && snapshot.data != null) {
              final data = snapshot.data!.data() as Map<String, dynamic>?;
              final isApproved = data?['isApproved'] ?? false;

              if (isApproved) {
                return const DashboardScreen();
              } else {
                return const PendingApprovalScreen();
              }
            }

            // إذا لم يوجد مستند، نعرض شاشة الانتظار كإجراء أمان
            return const PendingApprovalScreen();
          },
        );
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, stack) => Scaffold(
        body: Center(
          child: Text('حدث خطأ في المصادقة: $e'),
        ),
      ),
    );
  }
}