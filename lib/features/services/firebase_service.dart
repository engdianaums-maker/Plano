import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  static final FirebaseAuth auth = FirebaseAuth.instance;
  static final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // جلب معرف المستخدم الحالي بشكل آمن
  static String? get currentUserId => auth.currentUser?.uid;

  // التحقق من حالة تسجيل الدخول
  static bool get isAuthenticated => auth.currentUser != null;
}