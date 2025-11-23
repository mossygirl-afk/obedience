import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PairingScreen extends StatefulWidget {
  const PairingScreen({super.key});

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  bool loading = false;
  String? role;
  String? pairingCode;
  String? partnerUid;

  final TextEditingController joinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    final data = snap.data() as Map<String, dynamic>?;

    setState(() {
      role = data?['role'] as String?;
      pairingCode = data?['pairingCode'] as String?;
      partnerUid = data?['partnerUid'] as String?;
    });
  }

  String _generateRandomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<void> _createPairCode() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    if (role == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please choose a role (Dom/Sub) before pairing.'),
        ),
      );
      return;
    }

    setState(() => loading = true);

    final code = _generateRandomCode();

    // Create /pairCodes/{code}
    await FirebaseFirestore.instance.collection('pairCodes').doc(code).set({
      'code': code,
      'creatorUid': uid,
      'creatorRole': role,
      'partnerUid': null,
      'createdAt': Timestamp.now(),
    });

    // Save on this user
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'pairingCode': code,
    });

    setState(() {
      pairingCode = code;
      loading = false;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Pair code created: $code')));
  }

  Future<void> _joinPairCode() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final code = joinController.text.trim().toUpperCase();

    if (code.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a pair code first.')));
      return;
    }

    setState(() => loading = true);

    final pairRef = FirebaseFirestore.instance
        .collection('pairCodes')
        .doc(code);
    final snap = await pairRef.get();

    if (!snap.exists) {
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Code not found.')));
      return;
    }

    final data = snap.data() as Map<String, dynamic>;
    final creatorUid = data['creatorUid'] as String;
    final String? existingPartner = data['partnerUid'] as String?;

    if (creatorUid == uid) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You can't join your own code.")),
      );
      return;
    }

    if (existingPartner != null) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This code is already used.')),
      );
      return;
    }

    // Update pair document
    await pairRef.update({'partnerUid': uid});

    // Update both user docs with partnerUid + pairingCode
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'pairingCode': code,
      'partnerUid': creatorUid,
    });

    await FirebaseFirestore.instance.collection('users').doc(creatorUid).update(
      {'partnerUid': uid},
    );

    setState(() {
      pairingCode = code;
      partnerUid = creatorUid;
      loading = false;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Pairing successful!')));
  }

  Future<void> _unpair() async {
    if (partnerUid == null || partnerUid!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are not currently paired.')),
      );
      return;
    }

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final String? code = pairingCode;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unpair'),
        content: const Text(
          'Are you sure you want to unpair from your partner?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Unpair'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => loading = true);

    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final partnerRef = FirebaseFirestore.instance
        .collection('users')
        .doc(partnerUid);

    final batch = FirebaseFirestore.instance.batch();

    batch.update(userRef, {'partnerUid': null, 'pairingCode': null});
    batch.update(partnerRef, {'partnerUid': null});

    if (code != null && code.isNotEmpty) {
      final pairRef = FirebaseFirestore.instance
          .collection('pairCodes')
          .doc(code);
      batch.delete(pairRef);
    }

    await batch.commit();

    setState(() {
      partnerUid = null;
      pairingCode = null;
      loading = false;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Unpaired successfully.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pair with Partner')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your role: ${role ?? "not set"}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Current pair code: ${pairingCode ?? "none"}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Partner UID: ${partnerUid ?? "none"}',
                    style: const TextStyle(fontSize: 16),
                  ),

                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: _createPairCode,
                    child: const Text('Generate New Pair Code'),
                  ),

                  const SizedBox(height: 24),

                  const Divider(),

                  const SizedBox(height: 16),
                  const Text(
                    'Join a partner\'s code:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  TextField(
                    controller: joinController,
                    decoration: const InputDecoration(
                      labelText: 'Enter partner\'s code',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  ElevatedButton(
                    onPressed: _joinPairCode,
                    child: const Text('Join Code'),
                  ),

                  const SizedBox(height: 24),

                  if (partnerUid != null)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _unpair,
                      child: const Text('Unpair from current partner'),
                    ),
                ],
              ),
            ),
    );
  }
}
