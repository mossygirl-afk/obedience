import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController requiredCountController = TextEditingController();
  final TextEditingController pointsRewardController = TextEditingController();
  final TextEditingController pointsPenaltyController = TextEditingController();

  bool loading = false;

  Future<void> createTask() async {
    setState(() => loading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      final userSnap =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      final userData = userSnap.data() as Map<String, dynamic>?;

      final String? role = userData?['role'];
      final String? partnerUid = userData?['partnerUid'];

      final String title = titleController.text.trim();
      final String category = categoryController.text.trim().isEmpty
          ? 'General'
          : categoryController.text.trim();
      final String description = descriptionController.text.trim();

      final int requiredCount =
          int.tryParse(requiredCountController.text.trim()) ?? 1;
      final int pointsReward =
          int.tryParse(pointsRewardController.text.trim()) ?? 0;
      final int pointsPenalty =
          int.tryParse(pointsPenaltyController.text.trim()) ?? 0;

      if (title.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter a task title.")),
        );
        return;
      }

      if (role == 'sub' && partnerUid != null && partnerUid.isNotEmpty) {
        await FirebaseFirestore.instance.collection('taskSuggestions').add({
          'title': title,
          'category': category,
          'description': description,
          'requiredCount': requiredCount,
          'pointsReward': pointsReward,
          'pointsPenalty': pointsPenalty,
          'taskType': 'daily',
          'resetMode': 'manual',
          'requestedBy': uid,
          'domUid': partnerUid,
          'requestedAt': Timestamp.now(),
          'status': 'pending',
        });

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Task suggestion sent to Dom for approval!"),
            ),
          );
        }

        return;
      }

      late final String assignedToUid;
      late final String assignedByUid;

      if (role == 'dom' && partnerUid != null && partnerUid.isNotEmpty) {
        assignedByUid = uid;
        assignedToUid = partnerUid;
      } else {
        assignedByUid = uid;
        assignedToUid = uid;
      }

      await FirebaseFirestore.instance.collection('tasks').add({
        'title': title,
        'category': category,
        'description': description,
        'requiredCount': requiredCount,
        'currentCount': 0,
        'pointsReward': pointsReward,
        'pointsPenalty': pointsPenalty,
        'type': 'daily',
        'resetMode': 'manual',
        'assignedTo': assignedToUid,
        'assignedBy': assignedByUid,
        'createdAt': Timestamp.now(),
      });

      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    categoryController.dispose();
    descriptionController.dispose();
    requiredCountController.dispose();
    pointsRewardController.dispose();
    pointsPenaltyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Daily Task")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Task Title"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(
                labelText: "Category",
                hintText: "Morning, Evening, Chores, etc.",
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: "Description"),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: requiredCountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Minimum required count",
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pointsRewardController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Points for Completion",
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pointsPenaltyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Points Lost if Not Completed",
              ),
            ),
            const SizedBox(height: 25),
            if (!loading)
              ElevatedButton(
                onPressed: createTask,
                child: const Text("Create Task"),
              ),
            if (loading) const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
