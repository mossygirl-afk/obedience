import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'rewards_admin_screen.dart';
import 'create_task_screen.dart';
import 'edit_task_screen.dart';
import 'widgets/super_kawaii_bubble.dart';
import 'pairing_screen.dart';
import 'reward_requests_screen.dart';

class DomDashboard extends StatelessWidget {
  const DomDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Dom Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.card_giftcard),
            tooltip: 'Reward Requests',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RewardRequestsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.star),
            tooltip: 'Manage Rewards',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RewardsAdminScreen()),
              );
            },
          ),
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
          const SizedBox(height: 2),

          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateTaskScreen()),
              );
            },
            child: const Text("Create Task"),
          ),

          const SizedBox(height: 2),

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
                  padding: EdgeInsets.zero,
                  itemCount: docs.length,

                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    final title = data['title'] ?? "";
                    final description = data['description'] ?? "";
                    final required = data['requiredCount'] ?? 1;
                    final current = data['currentCount'] ?? 0;

                    final bool isComplete = current >= required;
                    final int reward = data['pointsReward'] ?? 0;
                    final int penalty = data['pointsPenalty'] ?? 0;
                    final String? subUid = data['assignedTo'];

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
                        padding: EdgeInsets.zero,
                        child: SuperKawaiiBubble(
                          margin: const EdgeInsets.symmetric(
                            vertical: 2,
                            horizontal: 8,
                          ),
                          padding: const EdgeInsets.all(8),

                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                              Text(description),
                              const SizedBox(height: 2),

                              Text(
                                isComplete ? "Complete ✔" : "Incomplete ❌",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isComplete ? Colors.green : Colors.red,
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

                                  if (data['resetMode'] == 'manual')
                                    ElevatedButton(
                                      onPressed: () async {
                                        if (subUid != null) {
                                          if (isComplete && reward > 0) {
                                            await FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(subUid)
                                                .update({
                                                  'points':
                                                      FieldValue.increment(
                                                        reward,
                                                      ),
                                                });
                                          } else if (!isComplete &&
                                              penalty > 0) {
                                            await FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(subUid)
                                                .update({
                                                  'points':
                                                      FieldValue.increment(
                                                        -penalty,
                                                      ),
                                                });
                                          }
                                        }

                                        FirebaseFirestore.instance
                                            .collection('tasks')
                                            .doc(doc.id)
                                            .update({'currentCount': 0});
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.purpleAccent,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.all(2),
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
