import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'login_screen.dart';
import 'role_selection_screen.dart';
import 'main_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyA8jVRFRxVAV1paLC0ump5vwtzZ0fAaVfI",
        authDomain: "obedienceapp-d420d.firebaseapp.com",
        projectId: "obedienceapp-d420d",
        storageBucket: "obedienceapp-d420d.firebasestorage.app",
        messagingSenderId: "543844282628",
        appId: "1:543844282628:web:64bc360bb41f056df92051",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

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

  /// Make sure we only run auto-resets once per app launch
  static bool _alreadyChecked = false;

  /// 🔁 AUTO RESET + AWARD / PENALTY (global, not per-screen)
  Future<void> _runAutoResets() async {
    final firestore = FirebaseFirestore.instance;
    final now = DateTime.now();

    // Grab all tasks that are auto-reset
    final tasksQuery = await firestore
        .collection('tasks')
        .where('resetMode', isEqualTo: 'auto')
        .get();

    for (final doc in tasksQuery.docs) {
      final data = doc.data();

      // Only daily tasks
      if (data['type'] != 'daily') continue;

      final int? hour = data['dailyResetHour'];
      final int? minute = data['dailyResetMinute'];

      // If task doesn't have a configured time, skip it
      if (hour == null || minute == null) continue;

      final DateTime todayReset = DateTime(
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      final dynamic lastResetRaw = data['lastReset'];

      DateTime lastResetTime;
      if (lastResetRaw is Timestamp) {
        lastResetTime = lastResetRaw.toDate();
      } else if (lastResetRaw is String) {
        try {
          lastResetTime = DateTime.parse(lastResetRaw);
        } catch (_) {
          lastResetTime = DateTime.fromMillisecondsSinceEpoch(0);
        }
      } else {
        // Never reset before
        lastResetTime = DateTime.fromMillisecondsSinceEpoch(0);
      }

      // ✅ This alone is enough to prevent double-awards
      final bool shouldReset =
          now.isAfter(todayReset) && lastResetTime.isBefore(todayReset);

      if (!shouldReset) continue;

      final int current = data['currentCount'] ?? 0;
      final int required = data['requiredCount'] ?? 1;
      final int reward = data['pointsReward'] ?? 0;
      final int penalty = data['pointsPenalty'] ?? 0;
      final String? subUid = data['assignedTo'];

      // 🎯 Same logic as manual: complete = reward, not complete = penalty
      if (subUid != null) {
        if (current >= required && reward > 0) {
          await firestore.collection('users').doc(subUid).update({
            'points': FieldValue.increment(reward),
          });
        } else if (current < required && penalty > 0) {
          await firestore.collection('users').doc(subUid).update({
            'points': FieldValue.increment(-penalty),
          });
        }
      }

      // Reset the task and bump lastReset
      await doc.reference.update({
        'currentCount': 0,
        'lastReset': Timestamp.fromDate(now),
      });
    }
  }

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

            final data =
                roleSnapshot.data!.data() as Map<String, dynamic>? ?? {};

            final role = data['role'];

            // no role set yet
            if (role == null) {
              return const RoleSelectionScreen();
            }

            // ⭐ Trigger auto reset exactly once per app launch
            if (!_alreadyChecked) {
              _alreadyChecked = true;
              _runAutoResets();
            }

            // 😊 go to main app
            return MainNavigation(role: role);
          },
        );
      },
    );
  }
}
