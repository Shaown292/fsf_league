import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

sealed class AppFailure implements Exception {
  const AppFailure(this.message);
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure([
    super.message = 'No connection. Check your internet and try again.',
  ]);
}

final class AuthFailure extends AppFailure {
  const AuthFailure(super.message);
}

final class PermissionFailure extends AppFailure {
  const PermissionFailure([
    super.message = 'You do not have permission to do that.',
  ]);
}

final class UnknownFailure extends AppFailure {
  const UnknownFailure([
    super.message = 'Something went wrong. Please try again.',
  ]);
}

/// Converts SDK errors into user-safe failures. Raw errors never reach the UI.
AppFailure failureFromError(Object error) {
  if (error is AppFailure) return error;
  if (error is TimeoutException) return const NetworkFailure();

  // FirebaseAuthException extends FirebaseException, so check it first.
  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'invalid-email' => const AuthFailure('That email address looks invalid.'),
      'user-disabled' => const AuthFailure('This account has been disabled.'),
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' =>
      const AuthFailure('Email or password is incorrect.'),
      'email-already-in-use' =>
      const AuthFailure('An account with this email already exists.'),
      'weak-password' => const AuthFailure(
          'Choose a stronger password (at least 8 characters).'),
      'too-many-requests' => const AuthFailure(
          'Too many attempts. Please wait a few minutes and try again.'),
      'network-request-failed' => const NetworkFailure(),
      _ => _unknown(error),
    };
  }

  if (error is FirebaseException) {
    return switch (error.code) {
      'unavailable' || 'deadline-exceeded' => const NetworkFailure(),
      'permission-denied' => const PermissionFailure(),
      _ => _unknown(error),
    };
  }

  return _unknown(error);
}

AppFailure _unknown(Object error) {
  debugPrint('Unmapped error: $error');
  return const UnknownFailure();
}