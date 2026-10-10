import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'dashboard_page.dart';
import 'log_in_page.dart';

class AdminGate extends StatelessWidget {
  const AdminGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final user = snapshot.data;
        if (user == null) return const AdminLoginPage();
        return _AdminCheck(key: ValueKey(user.uid), user: user);
      },
    );
  }
}

/// Reads the custom claim. UI gating is only a convenience; the real
/// protection is the Firestore rules, which check the same claim.
class _AdminCheck extends StatefulWidget {
  const _AdminCheck({super.key, required this.user});
  final User user;

  @override
  State<_AdminCheck> createState() => _AdminCheckState();
}

class _AdminCheckState extends State<_AdminCheck> {
  late final Future<IdTokenResult> _token;

  @override
  void initState() {
    super.initState();
    // true = force refresh so a newly granted claim is picked up.
    _token = widget.user.getIdTokenResult(true);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<IdTokenResult>(
      future: _token,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return const _Blocked(message: 'Could not verify your account. Check your connection.');
        }
        final isAdmin = snapshot.data?.claims?['admin'] == true;
        return isAdmin
            ? DashboardPage(user: widget.user)
            : const _Blocked(message: 'This account is not an administrator.');
      },
    );
  }
}

class _Blocked extends StatelessWidget {
  const _Blocked({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: FirebaseAuth.instance.signOut,
              child: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}