import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, required this.user});
  final User user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FSF League Admin'),
        actions: [
          TextButton(
            onPressed: FirebaseAuth.instance.signOut,
            child: const Text('Sign out'),
          ),
        ],
      ),
      body: Center(child: Text('Signed in as ${user.email} (admin)')),
    );
  }
}