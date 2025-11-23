import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'widgets/super_kawaii_bubble.dart';

class SubRewardsScreen extends StatelessWidget {
  const SubRewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Rewards Center",
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
            .doc(uid)
            .snapshots(),
        builder: (context, userSnap) {
          if (!userSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = userSnap.data!.data() as Map<String, dynamic>? ?? {};

          final int points = (userData['points'] ?? 0) is int
              ? userData['points']
              : (userData['points'] as num).toInt();

          final String? partnerUid = userData['partnerUid'];
          final String? role = userData['role'];

          if (role != 'sub') {
            return const Center(
              child: Text(
                "Only subs can use this screen.",
                style: TextStyle(fontSize: 18, color: Colors.redAccent),
              ),
            );
          }

          if (partnerUid == null || partnerUid.isEmpty) {
            return const Center(
              child: Text(
                "You must be paired with a Dom to view rewards 💗",
                style: TextStyle(fontSize: 18, color: Color(0xFFB8479B)),
              ),
            );
          }

          // Load the dom’s rewards
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('rewards')
                .where('ownerUid', isEqualTo: partnerUid)
                .orderBy('createdAt', descending: false)
                .snapshots(),
            builder: (context, rewardsSnap) {
              if (!rewardsSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final rewards = rewardsSnap.data!.docs;

              return Column(
                children: [
                  const SizedBox(height: 4),

                  const Text(
                    "Your Points",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFB8479B),
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    "$points",
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7F2A5F),
                    ),
                  ),

                  const SizedBox(height: 4),

                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,

                      children: [
                        // DOM’S REWARDS LIST
                        ...rewards.map((r) {
                          final data = r.data() as Map<String, dynamic>;

                          final String title = data['title'] ?? 'Untitled';
                          final String description = data['description'] ?? '';
                          final String emoji = data['emoji'] ?? '✨';
                          final int cost = (data['cost'] ?? 0) is int
                              ? data['cost']
                              : (data['cost'] as num).toInt();

                          final bool affordable = points >= cost;

                          return Padding(
                            padding: EdgeInsets.zero,
                            child: SuperKawaiiBubble(
                              margin: const EdgeInsets.symmetric(
                                vertical: 0,
                                horizontal:
                                    8, // tighter horizontally too if you want
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
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFB8479B),
                                          ),
                                        ),
                                        if (description.isNotEmpty)
                                          Text(description),
                                        const SizedBox(height: 4),
                                        Text("$cost pts"),
                                      ],
                                    ),
                                  ),

                                  ElevatedButton(
                                    onPressed: affordable
                                        ? () async {
                                            // subtract points immediately
                                            await FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(uid)
                                                .update({
                                                  'points':
                                                      FieldValue.increment(
                                                        -cost,
                                                      ),
                                                });

                                            // create request
                                            await FirebaseFirestore.instance
                                                .collection('rewardRequests')
                                                .add({
                                                  'domUid': partnerUid,
                                                  'subUid': uid,
                                                  'rewardName': title,
                                                  'emoji': emoji,
                                                  'cost': cost,
                                                  'status': 'pending',
                                                  'requestedAt':
                                                      Timestamp.now(),
                                                });

                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  "Requested: $emoji $title",
                                                ),
                                              ),
                                            );
                                          }
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: affordable
                                          ? const Color(0xFFFF8ED1)
                                          : Colors.grey,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text("Request"),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),

                        const SizedBox(height: 4),

                        // ADD NEW REWARD SUGGESTION BUTTON
                        Center(
                          child: SizedBox(
                            width:
                                300, // ← adjust this number smaller/bigger as you prefer
                            child: ElevatedButton(
                              onPressed: () {
                                _showSuggestionDialog(context, uid, partnerUid);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(
                                  255,
                                  255,
                                  0,
                                  221,
                                ),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 4, // ← narrower interior spacing
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: const Text(
                                "Suggest New Reward",
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // Suggestion Dialog
  void _showSuggestionDialog(
    BuildContext context,
    String subUid,
    String domUid,
  ) {
    final titleC = TextEditingController();
    final descC = TextEditingController();
    final emojiC = TextEditingController(text: '✨');
    final costC = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Suggest a Reward"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: titleC,
                  decoration: const InputDecoration(labelText: "Name"),
                ),
                TextField(
                  controller: descC,
                  decoration: const InputDecoration(labelText: "Description"),
                ),
                TextField(
                  controller: emojiC,
                  decoration: const InputDecoration(labelText: "Emoji"),
                ),
                TextField(
                  controller: costC,
                  decoration: const InputDecoration(labelText: "Cost"),
                  keyboardType: TextInputType.number,
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
                final name = titleC.text.trim();
                final desc = descC.text.trim();
                final emoji = emojiC.text.trim().isEmpty
                    ? '✨'
                    : emojiC.text.trim();
                final int cost = int.tryParse(costC.text.trim()) ?? 0;

                if (name.isEmpty || cost <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please enter a name and a positive cost."),
                    ),
                  );
                  return;
                }

                await FirebaseFirestore.instance
                    .collection('rewardSuggestions')
                    .add({
                      'domUid': domUid,
                      'subUid': subUid,
                      'title': name,
                      'description': desc,
                      'emoji': emoji,
                      'cost': cost,
                      'status': 'pending',
                      'requestedAt': Timestamp.now(),
                    });

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Suggestion sent!")),
                );
              },
              child: const Text("Submit"),
            ),
          ],
        );
      },
    );
  }
}
