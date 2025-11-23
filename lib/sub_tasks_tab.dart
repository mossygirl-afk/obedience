import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'widgets/super_kawaii_bubble.dart';

class SubTasksTab extends StatelessWidget {
  const SubTasksTab({super.key});

  @override
  Widget build(BuildContext context) {
    final String myUid = FirebaseAuth.instance.currentUser!.uid;

    return Column(
      children: [
        const SizedBox(height: 20),

        // 🌸 Create Task (for sub → sends suggestion)
        ElevatedButton(
          onPressed: () {
            Navigator.pushNamed(context, '/createTask');
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

        const SizedBox(height: 20),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('tasks')
                .where('assignedTo', isEqualTo: myUid) // ✔ FIXED
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
                padding: const EdgeInsets.only(bottom: 40),
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final doc = tasks[index];
                  final task = doc.data() as Map<String, dynamic>;

                  final String title = task['title'] ?? '';
                  final String description = task['description'] ?? '';
                  final int required = task['requiredCount'] ?? 1;
                  final int current = task['currentCount'] ?? 0;

                  final bool isComplete = current >= required;

                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 350,
                        minWidth: 260,
                        maxHeight: 230,
                      ),

                      child: SuperKawaiiBubble(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 18,
                        ),

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,

                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFB8479B),
                              ),
                            ),

                            const SizedBox(height: 6),

                            Text(
                              description,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                            ),

                            const SizedBox(height: 10),

                            Text(
                              "Progress: $current / $required",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFB8479B),
                              ),
                            ),

                            const SizedBox(height: 14),

                            Row(
                              children: [
                                // ➖ Decrease
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

                                // ➕ Increase
                                IconButton(
                                  onPressed: () {
                                    FirebaseFirestore.instance
                                        .collection('tasks')
                                        .doc(doc.id)
                                        .update({'currentCount': current + 1});
                                  },
                                  icon: const Icon(
                                    Icons.add_circle_outline,
                                    color: Color(0xFFB8479B),
                                  ),
                                ),

                                const Spacer(),

                                // ✔ Completion Indicator
                                Text(
                                  isComplete ? "Complete ✔" : "Incomplete ❌",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isComplete
                                        ? Colors.green
                                        : Colors.red,
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
    );
  }
}
