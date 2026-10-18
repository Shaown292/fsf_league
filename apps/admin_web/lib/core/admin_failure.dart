import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AdminFailure implements Exception {
  const AdminFailure(this.message);
  final String message;

  @override
  String toString() => 'AdminFailure: $message';
}

const staleContestMessage =
    'This contest was changed somewhere else. Reload the list and try again.';

AdminFailure adminFailureFrom(Object error) {
  if (error is AdminFailure) return error;
  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
        return const AdminFailure(
            'Permission denied. Sign out and back in to refresh your admin access.');
      case 'unavailable':
      case 'deadline-exceeded':
        return const AdminFailure('No connection. Check your internet and try again.');
      case 'aborted':
        return const AdminFailure('Another change happened at the same time. Try again.');
    }
  }
  if (error is FormatException) {
    return AdminFailure('A contest has invalid data: ${error.message}');
  }
  debugPrint('Unmapped admin error: $error');
  return const AdminFailure('Something went wrong. Please try again.');
}