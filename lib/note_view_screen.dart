import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'note_edit_screen.dart';

class NoteViewScreen extends StatelessWidget {
  final String noteId;

  const NoteViewScreen({super.key, required this.noteId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("View Note"),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NoteEditScreen(noteId: noteId),
                ),
              );
            },
          ),
        ],
      ),

      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('notes')
              .doc(noteId)
              .snapshots(),
          builder: (context, snap) {
            if (!snap.hasData)
              return const Center(child: CircularProgressIndicator());

            final data = snap.data!.data() as Map<String, dynamic>?;

            if (data == null) {
              return const Center(child: Text("Note not found."));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Text(
                data['content'] ?? "",
                style: const TextStyle(fontSize: 16),
              ),
            );
          },
        ),
      ),
    );
  }
}
