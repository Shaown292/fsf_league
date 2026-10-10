import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fsf_league/core/error/app_failure.dart';

void main() {
  test('wrong credentials map to a friendly auth failure', () {
    for (final code in ['wrong-password', 'user-not-found', 'invalid-credential']) {
      final f = failureFromError(FirebaseAuthException(code: code));
      expect(f, isA<AuthFailure>());
      expect(f.message, 'Email or password is incorrect.');
    }
  });

  test('network problems map to NetworkFailure', () {
    expect(failureFromError(FirebaseAuthException(code: 'network-request-failed')),
        isA<NetworkFailure>());
    expect(failureFromError(FirebaseException(plugin: 'cloud_firestore', code: 'unavailable')),
        isA<NetworkFailure>());
    expect(failureFromError(TimeoutException('slow')), isA<NetworkFailure>());
  });

  test('permission-denied maps to PermissionFailure', () {
    expect(
      failureFromError(
          FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied')),
      isA<PermissionFailure>(),
    );
  });

  test('unknown errors never leak raw text', () {
    final f = failureFromError(StateError('secret internals'));
    expect(f, isA<UnknownFailure>());
    expect(f.message.contains('secret'), isFalse);
  });
}