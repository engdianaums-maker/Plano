import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

final achievementsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('achievements')
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  });
});

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(achievementsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإنجازات والأوسمة'),
        backgroundColor: const Color(0xFF4364F7),
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: const Color(0xFFF7F9FC),
        child: achievementsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF4364F7)),
          ),
          error: (error, stack) => Center(
            child: Text('حدث خطأ: $error', style: const TextStyle(color: Colors.red)),
          ),
          data: (achievements) {
            // قائمة افتراضية للأوسمة والإنجازات في النظام التجاري
            final List<Map<String, dynamic>> defaultBadges = [
              {
                'title': 'البداية القوية',
                'description': 'إكمال أول مهمة بنجاح',
                'icon': Icons.star,
                'color': Colors.amber,
                'isUnlocked': achievements.any((a) => a['title'] == 'البداية القوية' || true), // افتراضي للعرض
              },
              {
                'title': 'محترف المهام',
                'description': 'إكمال 10 مهام بنجاح',
                'icon': Icons.military_tech,
                'color': Colors.blue,
                'isUnlocked': achievements.length >= 10,
              },
              {
                'title': 'سريع البرق',
                'description': 'إنجاز مهمة قبل الموعد النهائي',
                'icon': Icons.bolt,
                'color': Colors.orange,
                'isUnlocked': true,
              },
              {
                'title': 'مدير الوقت',
                'description': 'الالتزام بجميع مواعيد المهام الأسبوعية',
                'icon': Icons.timer,
                'color': Colors.green,
                'isUnlocked': false,
              },
            ];

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: defaultBadges.length,
              itemBuilder: (context, index) {
                final badge = defaultBadges[index];
                final bool isUnlocked = badge['isUnlocked'] as bool;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (badge['color'] as Color).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            badge['icon'] as IconData,
                            color: badge['color'] as Color,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                badge['title'] as String,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3142)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                badge['description'] as String,
                                style: const TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isUnlocked ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isUnlocked ? 'مكتسب' : 'مغلق',
                            style: TextStyle(
                              color: isUnlocked ? Colors.green : Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
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