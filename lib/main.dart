import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'login_screen.dart';
import 'role_selection_screen.dart';
import 'main_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // 🌸 Global Kawaii Pink Theme
      theme: ThemeData(
        useMaterial3: true,

        scaffoldBackgroundColor: const Color(0xFFFFE6F2),

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF8ED1),
          primary: const Color(0xFFFF8ED1),
          secondary: const Color(0xFFFFD4EC),
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFFC5E8),
          foregroundColor: Color(0xFF7F2A5F),
          centerTitle: true,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF7F2A5F),
          ),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF8ED1),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(40),
            ),
            elevation: 8,
            shadowColor: Colors.pinkAccent.withOpacity(0.3),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFFFDFF4),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 20,
          ),
          labelStyle: const TextStyle(
            color: Color(0xFFB84F8D),
            fontWeight: FontWeight.w600,
          ),
          floatingLabelStyle: const TextStyle(
            color: Color(0xFFDE5AAF),
            fontWeight: FontWeight.bold,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Color(0xFFFF8ED1), width: 2),
          ),
        ),
      ),

      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // ⏳ waiting for auth
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // ❌ not logged in
        if (!authSnapshot.hasData) {
          return const LoginScreen();
        }

        final uid = authSnapshot.data!.uid;

        // ✅ logged in → watch user doc for role
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .snapshots(),
          builder: (context, roleSnapshot) {
            if (!roleSnapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final data = roleSnapshot.data!.data() as Map<String, dynamic>?;

            final role = data?['role'];

            // no role set yet
            if (role == null) {
              return const RoleSelectionScreen();
            }

            // ✅ role set → go to bottom navigation with Tasks + Rewards
            return MainNavigation(role: role);
          },
        );
      },
    );
  }
}
