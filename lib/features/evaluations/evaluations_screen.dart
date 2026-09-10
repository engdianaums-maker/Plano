import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

final evaluationsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('evaluations')
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  });
});

class EvaluationsScreen extends ConsumerWidget {
  const EvaluationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final evaluationsAsync = ref.watch(evaluationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تقييمات الموظفين'),
        backgroundColor: const Color(0xFF4364F7),
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: const Color(0xFFF7F9FC),
        child: evaluationsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF4364F7)),
          ),
          error: (error, stack) => Center(
            child: Text('حدث خطأ: $error', style: const TextStyle(color: Colors.red)),
          ),
          data: (evaluations) {
            if (evaluations.isEmpty) {
              return const Center(
                child: Text(
                  'لا توجد تقييمات مسجلة حالياً.',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: evaluations.length,
              itemBuilder: (context, index) {
                final eval = evaluations[index];
                final double score = (eval['averageScore'] ?? 0.0).toDouble();

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'تقييم أداء رقم: ${index + 1}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3142)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'المعدل: ${score.toStringAsFixed(1)} / 5',
                                style: const TextStyle(color: Color(0xFF4364F7), fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildScoreItem('الجودة', eval['quality'] ?? 0),
                            _buildScoreItem('الدقة', eval['accuracy'] ?? 0),
                            _buildScoreItem('السرعة', eval['speed'] ?? 0),
                            _buildScoreItem('الالتزام', eval['deadlineAdherence'] ?? 0),
                            _buildScoreItem('التعاون', eval['cooperation'] ?? 0),
                          ],
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF4364F7),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showAddEvaluationDialog(context),
      ),
    );
  }

  Widget _buildScoreItem(String label, dynamic score) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text('$score', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3142))),
      ],
    );
  }

  void _showAddEvaluationDialog(BuildContext context) {
    double quality = 5;
    double accuracy = 5;
    double speed = 5;
    double deadline = 5;
    double cooperation = 5;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('إضافة تقييم جديد للموظف'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSlider('جودة العمل', quality, (val) => setStateDialog(() => quality = val)),
                    _buildSlider('الدقة', accuracy, (val) => setStateDialog(() => accuracy = val)),
                    _buildSlider('السرعة', speed, (val) => setStateDialog(() => speed = val)),
                    _buildSlider('الالتزام بالموعد', deadline, (val) => setStateDialog(() => deadline = val)),
                    _buildSlider('التعاون', cooperation, (val) => setStateDialog(() => cooperation = val)),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4364F7)),
                  onPressed: () async {
                    double average = (quality + accuracy + speed + deadline + cooperation) / 5;
                    
                    await FirebaseFirestore.instance.collection('evaluations').add({
                      'quality': quality.toInt(),
                      'accuracy': accuracy.toInt(),
                      'speed': speed.toInt(),
                      'deadlineAdherence': deadline.toInt(),
                      'cooperation': cooperation.toInt(),
                      'averageScore': average,
                      'createdAt': DateTime.now().toIso8601String(),
                    });

                    Navigator.pop(context);
                  },
                  child: const Text('حفظ التقييم', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSlider(String label, double value, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            Text('${value.toInt()} / 5', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4364F7))),
          ],
        ),
        Slider(
          value: value,
          min: 1,
          max: 5,
          divisions: 4,
          activeColor: const Color(0xFF4364F7),
          onChanged: onChanged,
        ),
      ],
    );
  }
}