import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'widgets/super_kawaii_bubble.dart';

class RewardRequestsScreen extends StatelessWidget {
  const RewardRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String domUid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Reward Requests",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFFFFC5E8),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rewardRequests')
            .where('domUid', isEqualTo: domUid)
            .orderBy('requestedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "No reward requests 💗",
                style: TextStyle(fontSize: 18, color: Color(0xFFB8479B)),
              ),
            );
          }

          final now = DateTime.now();

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final String emoji = data['emoji'] ?? '';
              final String name = data['rewardName'] ?? '';
              final int cost = data['cost'] ?? 0;
              final String subUid = data['subUid'] ?? '';
              final String status = data['status'] ?? 'pending';

              final Timestamp ts = data['requestedAt'] ?? Timestamp.now();
              final DateTime requestedAt = ts.toDate();

              // AUTO-DELETE denied requests older than 5 days
              if (status == "denied") {
                final difference = now.difference(requestedAt).inDays;
                if (difference >= 5) {
                  FirebaseFirestore.instance
                      .collection('rewardRequests')
                      .doc(doc.id)
                      .delete();
                }
              }

              return SuperKawaiiBubble(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$emoji  $name",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB8479B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text("Cost: $cost pts"),
                    const SizedBox(height: 4),
                    Text("Status: $status"),
                    const SizedBox(height: 4),

                    // =============================
                    // PENDING → Approve / Deny
                    // =============================
                    if (status == 'pending')
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('rewardRequests')
                                  .doc(doc.id)
                                  .update({'status': 'approved'});
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            child: const Text("Approve"),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () async {
                              // Refund points to sub
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(subUid)
                                  .update({
                                    'points': FieldValue.increment(cost),
                                  });

                              await FirebaseFirestore.instance
                                  .collection('rewardRequests')
                                  .doc(doc.id)
                                  .update({'status': 'denied'});
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text("Deny"),
                          ),
                        ],
                      ),

                    // =============================
                    // APPROVED → Complete (Deletes)
                    // =============================
                    if (status == 'approved')
                      ElevatedButton(
                        onPressed: () async {
                          await FirebaseFirestore.instance
                              .collection('rewardRequests')
                              .doc(doc.id)
                              .delete();

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Reward request marked complete."),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("Complete"),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
