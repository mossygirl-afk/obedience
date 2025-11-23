import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'widgets/super_kawaii_bubble.dart';
import 'note_view_screen.dart';
import 'note_edit_screen.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Shared Notes",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF7F2A5F),
          ),
        ),
        backgroundColor: const Color(0xFFFFC5E8),
        centerTitle: true,
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFF8ED1),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NoteEditScreen()),
          );
        },
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notes')
            .orderBy('createdAt', descending: false) // 👈 NEWEST AT BOTTOM
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData)
            return const Center(child: CircularProgressIndicator());

          final docs = snap.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "No notes yet.\nTap + to create one 💕",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Color(0xFFB8479B)),
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final String title = data['title'] ?? "Untitled";

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NoteViewScreen(noteId: doc.id),
                    ),
                  );
                },
                child: SuperKawaiiBubble(
                  margin: EdgeInsets.zero,
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 16,
                  ),

                  // ⭐ BUBBLE HEIGHT BOOST HERE
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 70),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB8479B),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
