import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'create_task_screen.dart';
import 'widgets/super_kawaii_bubble.dart';
import 'pairing_screen.dart';

class SubDashboard extends StatelessWidget {
  const SubDashboard({super.key});

  // 🔁 AUTO DAILY RESET + AWARD / PENALTY
  void _checkDailyReset(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;

    if (data['type'] != 'daily') return;
    if (data['resetMode'] != 'auto') return;

    final lastReset = data['lastReset'];
    final int hour = data['dailyResetHour'] ?? 0;
    final int minute = data['dailyResetMinute'] ?? 0;

    final now = DateTime.now();
    final todayResetTime = DateTime(now.year, now.month, now.day, hour, minute);

    DateTime? last;

    if (lastReset == null) {
      last = DateTime.fromMillisecondsSinceEpoch(0);
    } else if (lastReset is Timestamp) {
      last = lastReset.toDate();
    } else if (lastReset is String) {
      try {
        last = DateTime.parse(lastReset);
      } catch (_) {
        last = DateTime.fromMillisecondsSinceEpoch(0);
      }
    }

    if (last == null) return;

    final bool shouldReset =
        now.isAfter(todayResetTime) && last.isBefore(todayResetTime);

    if (!shouldReset) return;

    final int current = data['currentCount'] ?? 0;
    final int required = data['requiredCount'] ?? 1;
    final int reward = data['pointsReward'] ?? 0;
    final int penalty = data['pointsPenalty'] ?? 0;

    final String? subUid = data['assignedTo'];

    if (subUid != null) {
      if (current >= required && reward > 0) {
        await FirebaseFirestore.instance.collection('users').doc(subUid).update(
          {'points': FieldValue.increment(reward)},
        );
      } else if (current < required && penalty > 0) {
        await FirebaseFirestore.instance.collection('users').doc(subUid).update(
          {'points': FieldValue.increment(-penalty)},
        );
      }
    }

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
          "Assigned Tasks",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF7F2A5F),
          ),
        ),
        backgroundColor: const Color(0xFFFFC5E8),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.link),
            tooltip: 'Pair with partner',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PairingScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),

          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateTaskScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF8ED1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(40),
              ),
              elevation: 10,
            ),
            child: const Text("Create Task", style: TextStyle(fontSize: 18)),
          ),

          const SizedBox(height: 16),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('tasks')
                  .where('assignedTo', isEqualTo: uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final tasks = snapshot.data!.docs;

                if (tasks.isEmpty) {
                  return const Center(
                    child: Text(
                      "No tasks assigned 💗",
                      style: TextStyle(fontSize: 18, color: Color(0xFFB8479B)),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 5),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final doc = tasks[index];
                    final task = doc.data() as Map<String, dynamic>;

                    _checkDailyReset(doc);

                    final title = task['title'] ?? '';
                    final description = task['description'] ?? '';
                    final required = task['requiredCount'] ?? 1;
                    final current = task['currentCount'] ?? 0;
                    final isComplete = current >= required;

                    final int pointsPenalty = task['pointsPenalty'] ?? 0;
                    final String subUid = task['assignedTo'] ?? uid;

                    return Padding(
                      padding: const EdgeInsets.only(
                        bottom: 5,
                      ), // ← half spacing
                      child: Center(
                        child: FractionallySizedBox(
                          widthFactor: 1,
                          child: SuperKawaiiBubble(
                            margin: const EdgeInsets.symmetric(
                              vertical: 0.1,
                              horizontal: 10,
                            ), // 👈 custom spacing
                            padding: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 14,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,

                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFB8479B),
                                  ),
                                ),
                                const SizedBox(height: 2),

                                Text(
                                  description,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 2),

                                Text(
                                  "Progress: $current / $required",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFB8479B),
                                  ),
                                ),
                                const SizedBox(height: 2),

                                Text(
                                  isComplete ? "Complete ✔" : "Incomplete ❌",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isComplete
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                                const SizedBox(height: 2),

                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: current > 0
                                          ? () async {
                                              final wasComplete =
                                                  current >= required;
                                              final newCount = current - 1;
                                              final willBeComplete =
                                                  newCount >= required;

                                              await FirebaseFirestore.instance
                                                  .collection('tasks')
                                                  .doc(doc.id)
                                                  .update({
                                                    'currentCount': newCount,
                                                  });

                                              if (wasComplete &&
                                                  !willBeComplete &&
                                                  pointsPenalty > 0) {
                                                await FirebaseFirestore.instance
                                                    .collection('users')
                                                    .doc(subUid)
                                                    .update({
                                                      'points':
                                                          FieldValue.increment(
                                                            -pointsPenalty,
                                                          ),
                                                    });
                                              }
                                            }
                                          : null,
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                        color: Color(0xFFB8479B),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () async {
                                        final newCount = current + 1;
                                        await FirebaseFirestore.instance
                                            .collection('tasks')
                                            .doc(doc.id)
                                            .update({'currentCount': newCount});
                                      },
                                      icon: const Icon(
                                        Icons.add_circle_outline,
                                        color: Color(0xFFB8479B),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
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
