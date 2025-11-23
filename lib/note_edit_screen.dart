import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NoteEditScreen extends StatefulWidget {
  final String? noteId;

  const NoteEditScreen({super.key, this.noteId});

  @override
  State<NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends State<NoteEditScreen> {
  final titleC = TextEditingController();
  final contentC = TextEditingController();

  bool loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.noteId != null) _loadNote();
  }

  Future<void> _loadNote() async {
    final snap = await FirebaseFirestore.instance
        .collection('notes')
        .doc(widget.noteId)
        .get();
    final data = snap.data()!;
    titleC.text = data['title'] ?? "";
    contentC.text = data['content'] ?? "";
  }

  Future<void> _save() async {
    setState(() => loading = true);

    final uid = FirebaseAuth.instance.currentUser!.uid;

    final title = titleC.text.trim();
    final content = contentC.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Title cannot be empty")));
      setState(() => loading = false);
      return;
    }

    if (widget.noteId == null) {
      // CREATE
      await FirebaseFirestore.instance.collection('notes').add({
        'title': title,
        'content': content,
        'createdAt': Timestamp.now(),
        'lastEditedBy': uid,
      });
    } else {
      // UPDATE
      await FirebaseFirestore.instance
          .collection('notes')
          .doc(widget.noteId)
          .update({
            'title': title,
            'content': content,
            'lastEditedBy': uid,
            'updatedAt': Timestamp.now(),
          });
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.noteId == null ? "New Note" : "Edit Note"),
        actions: [
          if (widget.noteId != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('notes')
                    .doc(widget.noteId)
                    .delete();
                if (mounted) Navigator.pop(context);
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: titleC,
              decoration: const InputDecoration(labelText: "Title"),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: contentC,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  labelText: "Write here…",
                  alignLabelWithHint: true,
                ),
              ),
            ),
            const SizedBox(height: 12),
            loading
                ? const CircularProgressIndicator()
                : ElevatedButton(onPressed: _save, child: const Text("Save")),
          ],
        ),
      ),
    );
  }
}
