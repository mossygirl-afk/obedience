import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'widgets/super_kawaii_bubble.dart';

class RewardsAdminScreen extends StatelessWidget {
  const RewardsAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final domUid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Manage Rewards",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SECTION 2 — Incoming reward suggestions from subs
            const Text(
              "Reward Suggestions From Sub",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFB8479B),
              ),
            ),
            const SizedBox(height: 4),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('rewardSuggestions')
                  .where('domUid', isEqualTo: domUid)
                  .where('status', isEqualTo: 'pending')
                  .orderBy('requestedAt', descending: true)
                  .snapshots(),
              builder: (context, suggestionSnap) {
                if (!suggestionSnap.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final docs = suggestionSnap.data!.docs;

                if (docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      "No pending suggestions right now 💕",
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final sDoc = docs[index];
                    final sData = sDoc.data() as Map<String, dynamic>;

                    final String title = sData['title'] ?? 'Unnamed';
                    final String emoji = sData['emoji'] ?? '✨';
                    final String description = sData['description'] ?? '';
                    final int cost = (sData['cost'] ?? 0) is int
                        ? sData['cost']
                        : (sData['cost'] as num).toInt();

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: SuperKawaiiBubble(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "$emoji $title",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFB8479B),
                              ),
                            ),
                            if (description.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                description,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                            const SizedBox(height: 2),
                            Text(
                              "$cost pts",
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                ElevatedButton(
                                  onPressed: () async {
                                    final batch = FirebaseFirestore.instance
                                        .batch();

                                    final rewardsRef = FirebaseFirestore
                                        .instance
                                        .collection('rewards')
                                        .doc();

                                    batch.set(rewardsRef, {
                                      'ownerUid': domUid,
                                      'title': title,
                                      'description': description,
                                      'emoji': emoji,
                                      'cost': cost,
                                      'createdAt': Timestamp.now(),
                                    });

                                    batch.update(
                                      FirebaseFirestore.instance
                                          .collection('rewardSuggestions')
                                          .doc(sDoc.id),
                                      {
                                        'status': 'approved',
                                        'approvedAt': Timestamp.now(),
                                      },
                                    );

                                    await batch.commit();

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          "Added reward: $emoji $title",
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade400,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text("Approve"),
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: () async {
                                    await FirebaseFirestore.instance
                                        .collection('rewardSuggestions')
                                        .doc(sDoc.id)
                                        .update({'status': 'denied'});

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Suggestion denied."),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    "Deny",
                                    style: TextStyle(color: Colors.redAccent),
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
              },
            ),

            // ------------------------------------------------------
            // SECTION 3 — Task Suggestions From Sub  (NEW)
            // ------------------------------------------------------
            const SizedBox(height: 20),
            const Text(
              "Task Suggestions From Sub",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFB8479B),
              ),
            ),
            const SizedBox(height: 4),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('taskSuggestions')
                  .where('domUid', isEqualTo: domUid)
                  .where('status', isEqualTo: 'pending')
                  .orderBy('requestedAt', descending: true)
                  .snapshots(),
              builder: (context, taskSnap) {
                if (!taskSnap.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final docs = taskSnap.data!.docs;

                if (docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      "No pending task suggestions right now 💕",
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final tDoc = docs[index];
                    final data = tDoc.data() as Map<String, dynamic>;

                    final title = data['title'] ?? "Untitled";
                    final description = data['description'] ?? "";
                    final int requiredCount = data['requiredCount'] ?? 1;
                    final int reward = data['pointsReward'] ?? 0;
                    final int penalty = data['pointsPenalty'] ?? 0;
                    final String type = data['taskType'] ?? 'one_time';
                    final String resetMode = data['resetMode'] ?? 'manual';

                    final Timestamp? deadline = data['deadline'];
                    final int dailyHour = data['dailyResetHour'] ?? 0;
                    final int dailyMinute = data['dailyResetMinute'] ?? 0;
                    final String subUid = data['requestedBy'];

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: SuperKawaiiBubble(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "📝 $title",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFB8479B),
                              ),
                            ),
                            if (description.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(description),
                              ),
                            const SizedBox(height: 4),
                            Text("Required Count: $requiredCount"),
                            Text("Reward: $reward pts"),
                            Text("Penalty: $penalty pts"),
                            Text("Type: $type"),
                            Text("Reset Mode: $resetMode"),

                            if (type == 'one_time' && deadline != null)
                              Text("Deadline: ${deadline.toDate()}"),

                            if (type == 'daily')
                              Text(
                                "Resets at ${dailyHour.toString().padLeft(2, '0')}:${dailyMinute.toString().padLeft(2, '0')}",
                              ),

                            const SizedBox(height: 8),
                            Row(
                              children: [
                                ElevatedButton(
                                  onPressed: () async {
                                    await FirebaseFirestore.instance
                                        .collection('tasks')
                                        .add({
                                          'title': title,
                                          'description': description,
                                          'requiredCount': requiredCount,
                                          'currentCount': 0,
                                          'pointsReward': reward,
                                          'pointsPenalty': penalty,
                                          'type': type,
                                          'resetMode': resetMode,
                                          'deadline': deadline,
                                          'dailyResetHour': dailyHour,
                                          'dailyResetMinute': dailyMinute,
                                          'assignedTo': subUid,
                                          'assignedBy': domUid,
                                          'createdAt': Timestamp.now(),
                                          'lastReset': Timestamp.now(),
                                        });

                                    await FirebaseFirestore.instance
                                        .collection('taskSuggestions')
                                        .doc(tDoc.id)
                                        .update({
                                          'status': 'approved',
                                          'approvedAt': Timestamp.now(),
                                        });

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("Approved task: $title"),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade400,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text("Approve"),
                                ),
                                const SizedBox(width: 8),

                                TextButton(
                                  onPressed: () async {
                                    await FirebaseFirestore.instance
                                        .collection('taskSuggestions')
                                        .doc(tDoc.id)
                                        .update({'status': 'denied'});

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Task denied."),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    "Deny",
                                    style: TextStyle(color: Colors.redAccent),
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
              },
            ),
          ],
        ),
      ),
    );
  }

  // Confirm delete dialog
  static Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete reward?"),
          content: const Text("Are you sure you want to delete this reward?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                "Delete",
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  // Edit / Add reward dialog
  static void _showEditRewardDialog({
    required BuildContext context,
    required String domUid,
    String? existingId,
    Map<String, dynamic>? existingData,
  }) {
    final titleController = TextEditingController(
      text: existingData?['title'] ?? '',
    );
    final descriptionController = TextEditingController(
      text: existingData?['description'] ?? '',
    );
    final costController = TextEditingController(
      text: (existingData?['cost'] ?? '').toString(),
    );
    final emojiController = TextEditingController(
      text: existingData?['emoji'] ?? '✨',
    );

    final isEdit = existingId != null;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEdit ? "Edit Reward" : "Add Reward"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: "Reward name"),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: "Description (optional)",
                  ),
                ),
                TextField(
                  controller: costController,
                  decoration: const InputDecoration(labelText: "Cost (points)"),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: emojiController,
                  decoration: const InputDecoration(labelText: "Emoji"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final String name = titleController.text.trim();
                final String costText = costController.text.trim();
                final String emoji = emojiController.text.trim().isEmpty
                    ? "✨"
                    : emojiController.text.trim();
                final String description = descriptionController.text.trim();

                if (name.isEmpty || costText.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please enter at least a name and cost."),
                    ),
                  );
                  return;
                }

                final int cost = int.tryParse(costText) ?? 0;

                if (cost <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Cost must be a positive number."),
                    ),
                  );
                  return;
                }

                final rewardsColl = FirebaseFirestore.instance.collection(
                  'rewards',
                );

                if (isEdit) {
                  await rewardsColl.doc(existingId).update({
                    'title': name,
                    'description': description,
                    'emoji': emoji,
                    'cost': cost,
                  });
                } else {
                  await rewardsColl.add({
                    'ownerUid': domUid,
                    'title': name,
                    'description': description,
                    'emoji': emoji,
                    'cost': cost,
                    'createdAt': Timestamp.now(),
                  });
                }

                Navigator.pop(context);
              },
              child: Text(isEdit ? "Save" : "Create"),
            ),
          ],
        );
      },
    );
  }
}
