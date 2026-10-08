import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

const _useEmulator = bool.fromEnvironment('USE_EMULATOR');
// 10.0.2.2 is the host PC as seen from the Android emulator.
// For a physical phone, pass your PC's LAN IP via EMULATOR_HOST.
const _emulatorHost =
String.fromEnvironment('EMULATOR_HOST', defaultValue: '10.0.2.2');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (_useEmulator) {
    await FirebaseAuth.instance.useAuthEmulator(_emulatorHost, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(_emulatorHost, 8080);
  }

  runApp(const FsfLeagueApp());
}

class FsfLeagueApp extends StatelessWidget {
  const FsfLeagueApp({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(
    title: 'FSF League',
    home: SmokeTestPage(),
  );
}

class SmokeTestPage extends StatefulWidget {
  const SmokeTestPage({super.key});

  @override
  State<SmokeTestPage> createState() => _SmokeTestPageState();
}

class _SmokeTestPageState extends State<SmokeTestPage> {
  String _log = 'Tap a button';

  Future<void> _testAuth() async {
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: 'test${DateTime.now().millisecondsSinceEpoch}@example.com',
        password: 'password123',
      );
      setState(() => _log = 'Auth OK: ${cred.user?.uid}');
    } on FirebaseAuthException catch (e) {
      setState(() => _log = 'Auth failed: ${e.code}');
    }
  }

  Future<void> _testRulesDenied() async {
    try {
      await FirebaseFirestore.instance.collection('ping').get();
      setState(() => _log = 'UNEXPECTED: read succeeded, rules are open!');
    } on FirebaseException catch (e) {
      setState(() => _log = 'Rules OK (expected): ${e.code}');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('FSF League: Phase 1 smoke test')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        ElevatedButton(
            onPressed: _testAuth, child: const Text('Create test user')),
        ElevatedButton(
            onPressed: _testRulesDenied,
            child: const Text('Read Firestore (should be denied)')),
        const SizedBox(height: 24),
        Text(_log),
      ]),
    ),
  );
}