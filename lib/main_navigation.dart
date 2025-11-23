import 'package:flutter/material.dart';

import 'dom_dashboard.dart';
import 'sub_dashboard.dart';
import 'sub_rewards_screen.dart';
import 'dom_rewards_screen.dart';
import 'notes_screen.dart'; // 👈 NEW

class MainNavigation extends StatefulWidget {
  final String role; // "dom" or "sub"

  const MainNavigation({super.key, required this.role});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int currentIndex = 0;

  late final List<Widget> screens; // 👈 stored once

  @override
  void initState() {
    super.initState();

    // Decide which screens to show based on role
    if (widget.role == "dom") {
      screens = [
        const DomDashboard(), // 0 → Tasks
        const DomRewardsScreen(), // 1 → Rewards (dom view)
        const NotesScreen(), // 2 → Rules / Notes (shared)
      ];
    } else {
      screens = [
        const SubDashboard(), // 0 → Tasks
        const SubRewardsScreen(), // 1 → Rewards (sub view)
        const NotesScreen(), // 2 → Rules / Notes (shared)
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => setState(() => currentIndex = index),

        selectedItemColor: const Color(0xFFFF8ED1),
        unselectedItemColor: Colors.grey,
        backgroundColor: const Color(0xFFFFC5E8),
        iconSize: 30,
        elevation: 12,
        type: BottomNavigationBarType.fixed,

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.checklist_rounded),
            label: "Tasks",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.card_giftcard_rounded),
            label: "Rewards",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.rule_rounded),
            label: "Rules",
          ),
        ],
      ),
    );
  }
}
