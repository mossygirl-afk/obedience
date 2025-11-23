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
  late TextEditingController descriptionController;
  late TextEditingController requiredCountController;
  late TextEditingController pointsRewardController;
  late TextEditingController pointsPenaltyController;

  // DAILY ONLY
  String resetMode = 'manual';
  TimeOfDay? dailyResetTime;

  bool loading = false;

  @override
  void initState() {
    super.initState();

    final data = widget.taskData;

    titleController = TextEditingController(text: data['title'] ?? "");
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

    resetMode = data['resetMode'] ?? 'manual';

    if (data['dailyResetHour'] != null && data['dailyResetMinute'] != null) {
      dailyResetTime = TimeOfDay(
        hour: data['dailyResetHour'],
        minute: data['dailyResetMinute'],
      );
    }
  }

  Future<void> pickDailyResetTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: dailyResetTime ?? TimeOfDay.now(),
    );
    if (time == null) return;

    setState(() {
      dailyResetTime = time;
    });
  }

  Future<void> updateTask() async {
    setState(() => loading = true);

    int requiredCount = int.tryParse(requiredCountController.text) ?? 1;
    int pointsReward = int.tryParse(pointsRewardController.text) ?? 0;
    int pointsPenalty = int.tryParse(pointsPenaltyController.text) ?? 0;

    int? dailyHour;
    int? dailyMinute;

    if (resetMode == 'auto' && dailyResetTime != null) {
      dailyHour = dailyResetTime!.hour;
      dailyMinute = dailyResetTime!.minute;
    }

    await FirebaseFirestore.instance
        .collection('tasks')
        .doc(widget.taskId)
        .update({
          'title': titleController.text.trim(),
          'description': descriptionController.text.trim(),
          'requiredCount': requiredCount,
          'pointsReward': pointsReward,
          'pointsPenalty': pointsPenalty,
          'type': 'daily', // forced daily-only
          'resetMode': resetMode,
          'dailyResetHour': dailyHour,
          'dailyResetMinute': dailyMinute,
        });

    setState(() => loading = false);
    Navigator.pop(context);
  }

  Future<void> deleteTask() async {
    await FirebaseFirestore.instance
        .collection('tasks')
        .doc(widget.taskId)
        .delete();

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Daily Task"),
        actions: [
          IconButton(onPressed: deleteTask, icon: const Icon(Icons.delete)),
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
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: "Description"),
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
                labelText: "Points Reward (complete)",
              ),
            ),
            TextField(
              controller: pointsPenaltyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Points Penalty (un-complete)",
              ),
            ),

            const SizedBox(height: 20),
            const Text("Daily Reset Options", style: TextStyle(fontSize: 16)),

            RadioListTile(
              title: const Text("Manual Reset"),
              value: 'manual',
              groupValue: resetMode,
              onChanged: (v) => setState(() => resetMode = v!),
            ),
            RadioListTile(
              title: const Text("Auto Reset"),
              value: 'auto',
              groupValue: resetMode,
              onChanged: (v) => setState(() => resetMode = v!),
            ),

            if (resetMode == 'auto')
              ElevatedButton(
                onPressed: pickDailyResetTime,
                child: Text(
                  dailyResetTime == null
                      ? "Pick reset time"
                      : "Resets at ${dailyResetTime!.hour}:${dailyResetTime!.minute.toString().padLeft(2, '0')}",
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
