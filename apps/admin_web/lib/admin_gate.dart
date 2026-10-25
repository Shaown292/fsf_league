import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'core/app_mode.dart';
import 'features/shell/admin_shell.dart';
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

enum _Access { checking, admin, notAdmin, error }

/// UI gating is only a convenience; the real protection is the Firestore
/// rules, which check the same claim.
class _AdminCheck extends StatefulWidget {
  const _AdminCheck({super.key, required this.user});
  final User user;

  @override
  State<_AdminCheck> createState() => _AdminCheckState();
}

class _AdminCheckState extends State<_AdminCheck> {
  // The browser kept a session for a user the server no longer knows.
  static const _deadSession = {
    'user-not-found',
    'user-token-expired',
    'invalid-user-token',
    'user-disabled',
  };

  _Access _access = _Access.checking;
  Map<String, dynamic>? _claims;
  String? _error;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _check();
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    try {
      // true forces a refresh, so a newly granted claim is picked up.
      final token = await widget.user.getIdTokenResult(true);
      if (!mounted) return;
      final admin = token.claims?['admin'] == true;
      setState(() {
        _claims = token.claims;
        _error = null;
        _access = admin ? _Access.admin : _Access.notAdmin;
      });
      _updatePolling(keepPolling: !admin);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      if (_deadSession.contains(e.code)) {
        await FirebaseAuth.instance.signOut();
        return;
      }
      setState(() {
        _access = _Access.error;
        _error = e.code == 'network-request-failed'
            ? 'No connection. Check that the emulators or your internet are running.'
            : 'Could not verify your account (${e.code}).';
      });
      _updatePolling(keepPolling: useEmulator);
    }
  }

  // Only while the emulator is in use: a freshly started emulator may still
  // be getting its admin seeded, and this picks it up without a manual retry.
  void _updatePolling({required bool keepPolling}) {
    if (keepPolling && useEmulator) {
      _poll ??= Timer.periodic(const Duration(seconds: 3), (_) => _check());
    } else {
      _poll?.cancel();
      _poll = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return switch (_access) {
      _Access.checking =>
      const Scaffold(body: Center(child: CircularProgressIndicator())),
      _Access.admin => AdminShell(user: widget.user),
      _Access.notAdmin || _Access.error => _Blocked(
        user: widget.user,
        claims: _claims,
        error: _error,
        onCheckAgain: _check,
      ),
    };
  }
}

class _Blocked extends StatelessWidget {
  const _Blocked({
    required this.user,
    required this.claims,
    required this.error,
    required this.onCheckAgain,
  });

  final User user;
  final Map<String, dynamic>? claims;
  final String? error;
  final Future<void> Function() onCheckAgain;

  @override
  Widget build(BuildContext context) {
    final mode = useEmulator ? 'EMULATOR' : 'PRODUCTION';
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  error ?? 'This account is not an administrator.',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                Text('Mode: $mode'),
                Text('Signed in as: ${user.email} (${user.uid})'),
                Text('Claims: ${claims ?? 'none'}'),
                const SizedBox(height: 16),
                Text(
                  useEmulator
                      ? 'Start the emulators with dev.cmd. It creates the admin '
                      'automatically, and this page rechecks every few seconds.'
                      : 'Grant the admin claim with the production script, then '
                      'press "Check again".',
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    FilledButton(
                        onPressed: onCheckAgain, child: const Text('Check again')),
                    const SizedBox(width: 12),
                    OutlinedButton(
                        onPressed: FirebaseAuth.instance.signOut,
                        child: const Text('Sign out')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}