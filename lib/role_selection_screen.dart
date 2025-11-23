import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  Future<void> _setRole(String role) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'role': role,
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Choose your role",
              style: TextStyle(fontSize: 28),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                _setRole("dom");
              },
              child: const Text("Dom"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _setRole("sub");
              },
              child: const Text("Sub"),
            ),
          ],
        ),
      ),
    );
  }
}
