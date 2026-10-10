import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.username,
    this.avatarId,
    this.createdAt,
  });

  final String uid;
  final String username;
  final int? avatarId;

  /// Null while a local write is still waiting for the server timestamp.
  final DateTime? createdAt;

  factory UserProfile.fromMap(String uid, Map<String, dynamic> data) {
    return UserProfile(
      uid: uid,
      username: data['username'] as String? ?? '',
      avatarId: data['avatarId'] as int?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}