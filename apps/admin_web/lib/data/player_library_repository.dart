import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:fsf_league_core/fsf_league_core.dart';

import '../core/admin_failure.dart';

class PlayerLibraryRepository {
  PlayerLibraryRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('playerLibrary');

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } catch (e) {
      throw adminFailureFrom(e);
    }
  }

  /// Costs up to [limit] reads, so the controller loads it once and caches.
  Future<List<LibraryPlayer>> list({int limit = 500}) => _guard(() async {
    final snap = await _col.orderBy('name').limit(limit).get();
    final out = <LibraryPlayer>[];
    for (final doc in snap.docs) {
      try {
        out.add(LibraryPlayer.fromMap(doc.id, doc.data()));
      } on FormatException catch (e) {
        debugPrint('Skipping library player ${doc.id}: ${e.message}');
      }
    }
    return out;
  });

  Future<void> upsertAll(List<LibraryPlayer> players) => _guard(() async {
    for (var i = 0; i < players.length; i += 400) {
      final batch = _db.batch();
      for (final p in players.skip(i).take(400)) {
        batch.set(_col.doc(p.id), {
          ...p.toMap(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }
  });

  Future<void> delete(String id) => _guard(() => _col.doc(id).delete());
}