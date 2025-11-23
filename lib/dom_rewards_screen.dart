import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'widgets/super_kawaii_bubble.dart';

class DomRewardsScreen extends StatelessWidget {
  const DomRewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final domUid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Sub's Rewards",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF7F2A5F),
          ),
        ),
        backgroundColor: const Color(0xFFFFC5E8),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(domUid)
            .snapshots(),
        builder: (context, domSnap) {
          if (!domSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final domData = domSnap.data!.data() as Map<String, dynamic>? ?? {};

          final String? role = domData['role'] as String?;
          final String? partnerUid = domData['partnerUid'] as String?;

          if (role != 'dom') {
            return const Center(
              child: Text(
                "Only doms can use this screen.",
                style: TextStyle(fontSize: 18, color: Colors.redAccent),
              ),
            );
          }

          if (partnerUid == null || partnerUid.isEmpty) {
            return const Center(
              child: Text(
                "You must be paired with a sub to view their rewards 💗",
                style: TextStyle(fontSize: 18, color: Color(0xFFB8479B)),
              ),
            );
          }

          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(partnerUid)
                .snapshots(),
            builder: (context, subSnap) {
              if (!subSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final subData =
                  subSnap.data!.data() as Map<String, dynamic>? ?? {};

              final int subPoints = (subData['points'] ?? 0) is int
                  ? subData['points'] as int
                  : (subData['points'] as num).toInt();

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('rewards')
                    .where('ownerUid', isEqualTo: domUid)
                    .orderBy('createdAt', descending: false)
                    .snapshots(),
                builder: (context, rewardsSnap) {
                  if (!rewardsSnap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final rewards = rewardsSnap.data!.docs;

                  return Column(
                    children: [
                      const SizedBox(height: 8),
                      const Text(
                        "Sub's Points",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB8479B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "$subPoints",
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7F2A5F),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // ⭐ Adjust Points Button
                      ElevatedButton(
                        onPressed: () {
                          _showAdjustPointsDialog(
                            context: context,
                            subUid: partnerUid,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7F2A5F),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 22,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: const Text("Adjust Points"),
                      ),

                      const SizedBox(height: 12),

                      // ⭐ Create New Reward
                      ElevatedButton(
                        onPressed: () {
                          _showEditRewardDialog(
                            context: context,
                            domUid: domUid,
                            existingId: null,
                            existingData: null,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB8479B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: const Text("Create New Reward"),
                      ),

                      const SizedBox(height: 12),

                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 12,
                          ),
                          itemCount: rewards.length,
                          itemBuilder: (context, index) {
                            final rDoc = rewards[index];
                            final rData = rDoc.data() as Map<String, dynamic>;

                            final String title =
                                rData['title'] as String? ?? 'Untitled';
                            final String description =
                                rData['description'] as String? ?? '';
                            final String emoji =
                                rData['emoji'] as String? ?? '✨';
                            final int cost = (rData['cost'] ?? 0) is int
                                ? rData['cost'] as int
                                : ((rData['cost'] ?? 0) as num).toInt();

                            return Padding(
                              padding: EdgeInsets.zero, // removed spacing
                              child: SuperKawaiiBubble(
                                margin: const EdgeInsets.symmetric(
                                  vertical: 2,
                                  horizontal: 8,
                                ),
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                        ],
                                      ),
                                    ),

                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () {
                                        _showEditRewardDialog(
                                          context: context,
                                          domUid: domUid,
                                          existingId: rDoc.id,
                                          existingData: rData,
                                        );
                                      },
                                    ),

                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.redAccent,
                                      ),
                                      onPressed: () async {
                                        final ok = await _confirmDelete(
                                          context,
                                        );
                                        if (!ok) return;

                                        await FirebaseFirestore.instance
                                            .collection('rewards')
                                            .doc(rDoc.id)
                                            .delete();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // ⭐ Adjust Points Dialog (Give or Take)
  static void _showAdjustPointsDialog({
    required BuildContext context,
    required String subUid,
  }) {
    final controller = TextEditingController();
    String mode = "give"; // give or take

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Adjust Points"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ChoiceChip(
                        label: const Text("Give"),
                        selected: mode == "give",
                        onSelected: (v) {
                          setState(() => mode = "give");
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text("Take"),
                        selected: mode == "take",
                        onSelected: (v) {
                          setState(() => mode = "take");
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Amount",
                      hintText: "e.g. 10",
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final text = controller.text.trim();
                    final int value = int.tryParse(text) ?? 0;

                    if (value <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Enter a positive number of points."),
                        ),
                      );
                      return;
                    }

                    final adjustment = mode == "give" ? value : -value;

                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(subUid)
                        .update({'points': FieldValue.increment(adjustment)});

                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          mode == "give"
                              ? "Gave $value points."
                              : "Took $value points.",
                        ),
                      ),
                    );
                  },
                  child: const Text("Apply"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete reward?"),
          content: const Text("Are you sure?"),
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

  // reward editor
  static void _showEditRewardDialog({
    required BuildContext context,
    required String domUid,
    String? existingId,
    Map<String, dynamic>? existingData,
  }) {
    final titleController = TextEditingController(
      text: existingData?['title'] as String? ?? '',
    );
    final descriptionController = TextEditingController(
      text: existingData?['description'] as String? ?? '',
    );
    final costController = TextEditingController(
      text: (existingData?['cost'] ?? '').toString(),
    );
    final emojiController = TextEditingController(
      text: existingData?['emoji'] as String? ?? '✨',
    );

    final bool isEdit = existingId != null;

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
                  maxLines: 2,
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
                final name = titleController.text.trim();
                final costText = costController.text.trim();
                final emoji = emojiController.text.trim().isEmpty
                    ? "✨"
                    : emojiController.text.trim();
                final description = descriptionController.text.trim();

                if (name.isEmpty || costText.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please enter a name and cost."),
                    ),
                  );
                  return;
                }

                final int cost = int.tryParse(costText) ?? 0;

                if (cost <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Cost must be positive.")),
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
