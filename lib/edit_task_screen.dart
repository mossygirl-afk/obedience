import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditTaskScreen extends StatefulWidget {
  final String taskId;
  final Map<String, dynamic> taskData;

  const EditTaskScreen({
    super.key,
    required this.taskId,
    required this.taskData,
  });

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  late TextEditingController titleController;
  late TextEditingController categoryController;
  late TextEditingController descriptionController;
  late TextEditingController requiredCountController;
  late TextEditingController pointsRewardController;
  late TextEditingController pointsPenaltyController;

  bool loading = false;

  @override
  void initState() {
    super.initState();

    final data = widget.taskData;

    titleController = TextEditingController(text: data['title'] ?? "");
    categoryController = TextEditingController(
      text: data['category'] ?? "General",
    );
    descriptionController = TextEditingController(
      text: data['description'] ?? "",
    );
    requiredCountController = TextEditingController(
      text: "${data['requiredCount'] ?? 1}",
    );
    pointsRewardController = TextEditingController(
      text: "${data['pointsReward'] ?? 0}",
    );
    pointsPenaltyController = TextEditingController(
      text: "${data['pointsPenalty'] ?? 0}",
    );
  }

  Future<void> updateTask() async {
    setState(() => loading = true);

    final int requiredCount =
        int.tryParse(requiredCountController.text.trim()) ?? 1;
    final int pointsReward =
        int.tryParse(pointsRewardController.text.trim()) ?? 0;
    final int pointsPenalty =
        int.tryParse(pointsPenaltyController.text.trim()) ?? 0;

    final String category = categoryController.text.trim().isEmpty
        ? "General"
        : categoryController.text.trim();

    await FirebaseFirestore.instance
        .collection('tasks')
        .doc(widget.taskId)
        .update({
      'title': titleController.text.trim(),
      'category': category,
      'description': descriptionController.text.trim(),
      'requiredCount': requiredCount,
      'pointsReward': pointsReward,
      'pointsPenalty': pointsPenalty,
      'type': 'daily',
      'resetMode': 'manual',
      'dailyResetHour': FieldValue.delete(),
      'dailyResetMinute': FieldValue.delete(),
      'lastReset': FieldValue.delete(),
    });

    if (mounted) {
      setState(() => loading = false);
      Navigator.pop(context);
    }
  }

  Future<void> deleteTask() async {
    await FirebaseFirestore.instance
        .collection('tasks')
        .doc(widget.taskId)
        .delete();

    if (mounted) Navigator.pop(context);
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
      appBar: AppBar(
        title: const Text("Edit Daily Task"),
        actions: [
          IconButton(
            onPressed: deleteTask,
            icon: const Icon(Icons.delete),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Title"),
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
              maxLines: 3,
              decoration: const InputDecoration(labelText: "Description"),
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
                labelText: "Points Reward (complete)",
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pointsPenaltyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Points Penalty (un-complete)",
              ),
            ),
            const SizedBox(height: 25),
            if (!loading)
              ElevatedButton(
                onPressed: updateTask,
                child: const Text("Save Changes"),
              ),
            if (loading) const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
