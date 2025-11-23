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
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController requiredCountController = TextEditingController();
  final TextEditingController pointsRewardController = TextEditingController();
  final TextEditingController pointsPenaltyController = TextEditingController();

  // DAILY ONLY
  String resetMode = 'manual'; // 'manual' or 'auto'
  TimeOfDay? dailyResetTime;

  bool loading = false;

  // Pick daily reset time (only for auto reset)
  Future<void> pickDailyResetTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;

    setState(() {
      dailyResetTime = time;
    });
  }

  Future<void> createTask() async {
    setState(() => loading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      // Load role + partner
      final userSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      final userData = userSnap.data() as Map<String, dynamic>?;

      final String? role = userData?['role'];
      final String? partnerUid = userData?['partnerUid'];

      // Collect input
      final String title = titleController.text.trim();
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

      // SUB → send task suggestion
      if (role == 'sub' && partnerUid != null && partnerUid.isNotEmpty) {
        await FirebaseFirestore.instance.collection('taskSuggestions').add({
          'title': title,
          'description': description,
          'requiredCount': requiredCount,
          'pointsReward': pointsReward,
          'pointsPenalty': pointsPenalty,
          'taskType': 'daily',
          'resetMode': resetMode,
          'requestedBy': uid,
          'domUid': partnerUid,
          'requestedAt': Timestamp.now(),
          'status': 'pending',
          'dailyResetHour': dailyResetTime?.hour,
          'dailyResetMinute': dailyResetTime?.minute,
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

      // DOM → create real task
      late final String assignedToUid;
      late final String assignedByUid;

      if (role == 'dom' && partnerUid != null && partnerUid.isNotEmpty) {
        assignedByUid = uid;
        assignedToUid = partnerUid;
      } else {
        assignedByUid = uid;
        assignedToUid = uid;
      }

      int? dailyHour;
      int? dailyMinute;

      if (resetMode == 'auto' && dailyResetTime != null) {
        dailyHour = dailyResetTime!.hour;
        dailyMinute = dailyResetTime!.minute;
      }

      // Create task
      await FirebaseFirestore.instance.collection('tasks').add({
        'title': title,
        'description': description,
        'requiredCount': requiredCount,
        'currentCount': 0,
        'pointsReward': pointsReward,
        'pointsPenalty': pointsPenalty,
        'type': 'daily',
        'resetMode': resetMode,
        'dailyResetHour': dailyHour,
        'dailyResetMinute': dailyMinute,
        'assignedTo': assignedToUid,
        'assignedBy': assignedByUid,
        'createdAt': Timestamp.now(),
        'lastReset': Timestamp.now(),
      });

      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => loading = false);
    }
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
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: "Description"),
              maxLines: 3,
            ),
            TextField(
              controller: requiredCountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Minimum required count",
              ),
            ),
            TextField(
              controller: pointsRewardController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Points for Completion",
              ),
            ),
            TextField(
              controller: pointsPenaltyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Points Lost if Not Completed",
              ),
            ),

            const SizedBox(height: 20),
            const Text("Daily Reset Options", style: TextStyle(fontSize: 16)),

            RadioListTile(
              title: const Text("Manual reset"),
              value: 'manual',
              groupValue: resetMode,
              onChanged: (value) => setState(() => resetMode = value!),
            ),
            RadioListTile(
              title: const Text("Auto-reset at chosen time"),
              value: 'auto',
              groupValue: resetMode,
              onChanged: (value) => setState(() => resetMode = value!),
            ),

            if (resetMode == 'auto')
              ElevatedButton(
                onPressed: pickDailyResetTime,
                child: Text(
                  dailyResetTime == null
                      ? "Pick daily reset time"
                      : "Resets at ${dailyResetTime!.hour}:${dailyResetTime!.minute.toString().padLeft(2, '0')}",
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
