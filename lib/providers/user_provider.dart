import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

final userProvider = FutureProvider<AppUser?>((ref) async {
  final authUser = FirebaseAuth.instance.currentUser;
  if (authUser == null) return null;

  final doc = await FirebaseFirestore.instance.collection('users').doc(authUser.uid).get();
  if (!doc.exists) return null;

  return AppUser.fromMap(doc.data()!, doc.id);
});

final currentUserProvider = Provider<AppUser?>((ref) {
  final userAsync = ref.watch(userProvider);
  return userAsync.value;
});