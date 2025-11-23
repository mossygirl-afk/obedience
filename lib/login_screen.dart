import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool loading = false;

  Future<void> login() async {
    setState(() => loading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }

    setState(() => loading = false);
  }

  Future<void> register() async {
    setState(() => loading = true);

    try {
      // Create Firebase Auth account
      UserCredential userCred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      final uid = userCred.user!.uid;

      // Create Firestore user doc with default fields
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'role': null, // user chooses Dom/Sub later
        'points': 0,
        'pairingCode': null, // code they created or joined
        'partnerUid': null, // their linked partner (if any)
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Login", style: TextStyle(fontSize: 32)),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email"),
              ),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Password"),
              ),
              const SizedBox(height: 20),
              if (!loading)
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: login,
                      child: const Text("Sign In"),
                    ),
                    ElevatedButton(
                      onPressed: register,
                      child: const Text("Create Account"),
                    ),
                  ],
                ),
              if (loading) const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
