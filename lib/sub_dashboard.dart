import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'create_task_screen.dart';
import 'widgets/super_kawaii_bubble.dart';
import 'pairing_screen.dart';

class SubDashboard extends StatelessWidget {
  const SubDashboard({super.key});

  String _categoryOf(Map<String, dynamic> data) {
    final raw = data['category'];
    if (raw == null || raw.toString().trim().isEmpty) {
      return 'General';
    }
    return raw.toString().trim();
  }

  void _showTaskEditSheet({
    required BuildContext context,
    required String taskId,
    required String taskTitle,
    required String existingComment,
    required String existingCategory,
  }) {
    final commentController = TextEditingController(text: existingComment);
    final categoryController = TextEditingController(text: existingCategory);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFE6F2),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  taskTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7F2A5F),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(
                    labelText: "Category",
                    hintText: "Morning, Night, Chores, etc.",
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: commentController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: "Comment for Dom",
                    hintText: "Add a note about this task...",
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          await FirebaseFirestore.instance
                              .collection('tasks')
                              .doc(taskId)
                              .update({
                            'subComment': FieldValue.delete(),
                            'subCommentUpdatedAt': FieldValue.delete(),
                          });

                          if (context.mounted) Navigator.pop(context);
                        },
                        child: const Text(
                          "Clear Comment",
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final comment = commentController.text.trim();
                          final category =
                              categoryController.text.trim().isEmpty
                                  ? "General"
                                  : categoryController.text.trim();

                          final updateData = <String, dynamic>{
                            'category': category,
                          };

                          if (comment.isEmpty) {
                            updateData['subComment'] = FieldValue.delete();
                            updateData['subCommentUpdatedAt'] =
                                FieldValue.delete();
                          } else {
                            updateData['subComment'] = comment;
                            updateData['subCommentUpdatedAt'] = Timestamp.now();
                          }

                          await FirebaseFirestore.instance
                              .collection('tasks')
                              .doc(taskId)
                              .update(updateData);

                          if (context.mounted) Navigator.pop(context);
                        },
                        child: const Text("Save"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
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

                final categories = tasks
                    .map((doc) =>
                        _categoryOf(doc.data() as Map<String, dynamic>))
                    .toSet()
                    .toList();

                categories.sort((a, b) {
                  if (a == 'General') return -1;
                  if (b == 'General') return 1;
                  return a.toLowerCase().compareTo(b.toLowerCase());
                });

                return DefaultTabController(
                  length: categories.length,
                  child: Column(
                    children: [
                      TabBar(
                        isScrollable: true,
                        labelColor: const Color(0xFF7F2A5F),
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: const Color(0xFFFF8ED1),
                        tabs: categories
                            .map((category) => Tab(text: category))
                            .toList(),
                      ),
                      Expanded(
                        child: TabBarView(
                          children: categories.map((category) {
                            final categoryTasks = tasks.where((doc) {
                              final task = doc.data() as Map<String, dynamic>;
                              return _categoryOf(task) == category;
                            }).toList();

                            return ListView.builder(
                              padding: const EdgeInsets.only(bottom: 5),
                              itemCount: categoryTasks.length,
                              itemBuilder: (context, index) {
                                final doc = categoryTasks[index];
                                final task = doc.data() as Map<String, dynamic>;

                                final title = task['title'] ?? '';
                                final description = task['description'] ?? '';
                                final required = task['requiredCount'] ?? 1;
                                final current = task['currentCount'] ?? 0;
                                final isComplete = current >= required;
                                final String existingComment =
                                    task['subComment'] ?? '';
                                final String existingCategory =
                                    _categoryOf(task);

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 5),
                                  child: Center(
                                    child: FractionallySizedBox(
                                      widthFactor: 1,
                                      child: GestureDetector(
                                        onTap: () {
                                          _showTaskEditSheet(
                                            context: context,
                                            taskId: doc.id,
                                            taskTitle: title,
                                            existingComment: existingComment,
                                            existingCategory: existingCategory,
                                          );
                                        },
                                        child: SuperKawaiiBubble(
                                          margin: const EdgeInsets.symmetric(
                                            vertical: 0.1,
                                            horizontal: 10,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 4,
                                            horizontal: 14,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      title,
                                                      style: const TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            Color(0xFFB8479B),
                                                      ),
                                                    ),
                                                  ),
                                                  if (existingComment
                                                      .trim()
                                                      .isNotEmpty)
                                                    const Icon(
                                                      Icons.comment,
                                                      size: 20,
                                                      color: Color(0xFF7F2A5F),
                                                    ),
                                                ],
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
                                                isComplete
                                                    ? "Complete ✔"
                                                    : "Incomplete ❌",
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
                                                            final newCount =
                                                                current - 1;
                                                            await FirebaseFirestore
                                                                .instance
                                                                .collection(
                                                                    'tasks')
                                                                .doc(doc.id)
                                                                .update({
                                                              'currentCount':
                                                                  newCount,
                                                            });
                                                          }
                                                        : null,
                                                    icon: const Icon(
                                                      Icons
                                                          .remove_circle_outline,
                                                      color: Color(0xFFB8479B),
                                                    ),
                                                  ),
                                                  IconButton(
                                                    onPressed: () async {
                                                      final newCount =
                                                          current + 1;
                                                      await FirebaseFirestore
                                                          .instance
                                                          .collection('tasks')
                                                          .doc(doc.id)
                                                          .update({
                                                        'currentCount':
                                                            newCount,
                                                      });
                                                    },
                                                    icon: const Icon(
                                                      Icons.add_circle_outline,
                                                      color: Color(0xFFB8479B),
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
