import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'create_task_screen.dart';
import 'edit_task_screen.dart';
import 'widgets/super_kawaii_bubble.dart';

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

                    // 👇 IMPORTANT:
                    // No auto-reset or point awarding here anymore.

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
