import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'create_task_screen.dart';
import 'edit_task_screen.dart';
import 'widgets/super_kawaii_bubble.dart';

class DomDashboard extends StatelessWidget {
  const DomDashboard({super.key});

  /// DAILY RESET CHECKER – same timing logic, but NO points given here
  Future<void> _checkDailyReset(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;

    if (data['type'] != 'daily') return;
    if (data['resetMode'] != 'auto') return;

    final lastReset = data['lastReset'];
    final int hour = data['dailyResetHour'] ?? 0;
    final int minute = data['dailyResetMinute'] ?? 0;

    final now = DateTime.now();
    final resetToday = DateTime(now.year, now.month, now.day, hour, minute);

    DateTime last;

    if (lastReset == null) {
      last = resetToday.subtract(const Duration(days: 1));
    } else if (lastReset is Timestamp) {
      last = lastReset.toDate();
    } else if (lastReset is String) {
      try {
        last = DateTime.parse(lastReset);
      } catch (_) {
        last = resetToday.subtract(const Duration(days: 1));
      }
    } else {
      return;
    }

    final lastSlot = DateTime(last.year, last.month, last.day, hour, minute);
    final bool shouldReset =
        now.isAfter(resetToday) && lastSlot.isBefore(resetToday);

    if (!shouldReset) return;

    await FirebaseFirestore.instance.collection('tasks').doc(doc.id).update({
      'currentCount': 0,
      'lastReset': Timestamp.fromDate(now),
    });
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Dom Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),

          // CREATE TASK BUTTON
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateTaskScreen()),
              );
            },
            child: const Text("Create Task"),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('tasks')
                  .where('assignedBy', isEqualTo: uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No tasks yet 💗",
                      style: TextStyle(fontSize: 18, color: Color(0xFFB8479B)),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 8,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    _checkDailyReset(doc);

                    final title = data['title'] ?? "";
                    final description = data['description'] ?? "";
                    final required = data['requiredCount'] ?? 1;
                    final current = data['currentCount'] ?? 0;

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                EditTaskScreen(taskId: doc.id, taskData: data),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 14.0),
                        child: SuperKawaiiBubble(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // title
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFB8479B),
                                ),
                              ),
                              const SizedBox(height: 6),

                              Text(description),
                              const SizedBox(height: 10),

                              // progress
                              Text(
                                "Progress: $current / $required",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFB8479B),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // buttons row
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: current > 0
                                        ? () {
                                            FirebaseFirestore.instance
                                                .collection('tasks')
                                                .doc(doc.id)
                                                .update({
                                                  'currentCount': current - 1,
                                                });
                                          }
                                        : null,
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                      color: Color(0xFFB8479B),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      FirebaseFirestore.instance
                                          .collection('tasks')
                                          .doc(doc.id)
                                          .update({
                                            'currentCount': current + 1,
                                          });
                                    },
                                    icon: const Icon(
                                      Icons.add_circle_outline,
                                      color: Color(0xFFB8479B),
                                    ),
                                  ),
                                  const Spacer(),

                                  // Manual reset button for manual-reset tasks
                                  if (data['resetMode'] == 'manual')
                                    ElevatedButton(
                                      onPressed: () {
                                        FirebaseFirestore.instance
                                            .collection('tasks')
                                            .doc(doc.id)
                                            .update({'currentCount': 0});
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.purpleAccent,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        "Reset",
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
