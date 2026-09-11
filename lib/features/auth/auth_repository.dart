import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    UserCredential credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (email.trim().toLowerCase() == 'flupro@gmail.com') {
      return;
    }

    final docRef = _firestore.collection('users').doc(credential.user?.uid);
    final doc = await docRef.get();

    if (!doc.exists) {
      await docRef.set({
        'uid': credential.user?.uid,
        'email': email,
        'name': email.split('@')[0],
        'role': 'موظف عادي',
        'isApproved': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    final isApproved = doc.data()?['isApproved'] ?? false;
    if (!isApproved) {
      await _auth.signOut();
      throw 'الحساب بانتظار موافقة المدير';
    }
  }

  Future<void> signUpWithEmailAndPassword(
    String email,
    String password,
    String name,
    String role,
  ) async {
    UserCredential credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;
    final bool isManagerAccount = email.trim().toLowerCase() == 'flupro@gmail.com' || role == 'مدير نظام';

    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'isApproved': isManagerAccount,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (!isManagerAccount) {
      await _auth.signOut();
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

// تعريف userRoleProvider هنا ليكون متاحاً في جميع شاشات التطبيق
final userRoleProvider = StreamProvider.autoDispose<String>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return Stream.value('موظف عادي');
  
  if (user.email == 'flupro@gmail.com') return Stream.value('مدير نظام');

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((doc) => doc.data()?['role'] ?? 'موظف عادي');
});