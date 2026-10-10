import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/error/app_failure.dart';
import '../models/user_profile.dart';

class UserRepository {
  UserRepository(this._db);
  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _ref(String uid) =>
      _db.collection('users').doc(uid);

  /// Cache first (saves a billed read); falls back to the server.
  /// Returns null when the profile document does not exist yet.
  Future<UserProfile?> fetch(String uid) async {
    try {
      final cached = await _fromCache(uid);
      if (cached != null) return cached;
      final snap = await _ref(uid).get();
      return snap.exists ? UserProfile.fromMap(uid, snap.data()!) : null;
    } catch (e) {
      throw failureFromError(e);
    }
  }

  Future<UserProfile?> _fromCache(String uid) async {
    try {
      final snap = await _ref(uid).get(const GetOptions(source: Source.cache));
      return snap.exists ? UserProfile.fromMap(uid, snap.data()!) : null;
    } on FirebaseException {
      return null; // not cached yet
    }
  }

  /// Rules require exactly: username + createdAt == server time.
  Future<void> create({required String uid, required String username}) async {
    try {
      await _ref(uid).set({
        'username': username,
        'createdAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 15));
    } catch (e) {
      throw failureFromError(e);
    }
  }
}