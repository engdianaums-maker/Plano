import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

final notificationsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('notifications')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  });
});

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('مركز الإشعارات'),
        backgroundColor: const Color(0xFF4364F7),
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: const Color(0xFFF7F9FC),
        child: notificationsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF4364F7)),
          ),
          error: (error, stack) => Center(
            child: Text('حدث خطأ: $error', style: const TextStyle(color: Colors.red)),
          ),
          data: (notifications) {
            if (notifications.isEmpty) {
              return const Center(
                child: Text(
                  'لا توجد إشعارات جديدة حالياً.',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notif = notifications[index];
                final bool isRead = notif['isRead'] ?? false;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: isRead ? Colors.grey.withValues(alpha: 0.1) : const Color(0xFF4364F7).withValues(alpha: 0.1),
                      child: Icon(
                        isRead ? Icons.notifications_none : Icons.notifications_active,
                        color: isRead ? Colors.grey : const Color(0xFF4364F7),
                      ),
                    ),
                    title: Text(
                      notif['title'] ?? 'إشعار جديد',
                      style: TextStyle(
                        fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                        fontSize: 16,
                        color: const Color(0xFF2D3142),
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Text(
                          notif['body'] ?? '',
                          style: const TextStyle(color: Colors.black54, fontSize: 14),
                        ),
                      ],
                    ),
                    trailing: !isRead
                        ? Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Color(0xFF4364F7),
                              shape: BoxShape.circle,
                            ),
                          )
                        : null,
                    onTap: () async {
                      // تحديد الإشعار كمقروء عند الضغط عليه
                      await FirebaseFirestore.instance
                          .collection('notifications')
                          .doc(notif['id'])
                          .update({'isRead': true});
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}