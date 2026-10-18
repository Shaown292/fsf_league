import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:fsf_league_core/fsf_league_core.dart';

import '../core/admin_failure.dart';
import 'contest_mapper.dart';

class ContestPage {
  const ContestPage(this.contests, this.skipped);
  final List<Contest> contests;

  /// Documents that could not be parsed.
  final int skipped;
}

class ContestRepository {
  ContestRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _contests =>
      _db.collection('contests');
  DocumentReference<Map<String, dynamic>> get _feed =>
      _db.collection('meta').doc('activeContests');

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } catch (e) {
      throw adminFailureFrom(e);
    }
  }

  /// Newest 25 by kickoff. Costs up to 25 reads, so the UI loads it once.
  Future<ContestPage> list({int limit = 25}) => _guard(() async {
    final snap = await _contests
        .orderBy('matchAt', descending: true)
        .limit(limit)
        .get();
    final contests = <Contest>[];
    var skipped = 0;
    for (final doc in snap.docs) {
      try {
        contests.add(ContestMapper.fromDoc(doc.id, doc.data()));
      } on FormatException catch (e) {
        skipped++;
        debugPrint('Skipping contest ${doc.id}: ${e.message}');
      }
    }
    return ContestPage(contests, skipped);
  });

  Future<Contest> create(Contest draft) => _guard(() async {
    final problems = ContestValidator.detailsProblems(draft);
    if (problems.isNotEmpty) throw AdminFailure(problems.first);
    final ref = _contests.doc();
    final created = draft.copyWith(
      id: ref.id,
      status: ContestStatus.draft,
      version: 1,
      players: const <String, ContestPlayer>{},
    );
    await ref.set(ContestMapper.toNewDoc(created));
    return created;
  });

  Future<Contest> saveDetails(Contest edited, {required int expectedVersion}) =>
      _guard(() => _db.runTransaction<Contest>((tx) async {
        final ref = _contests.doc(edited.id);
        final current = await _read(tx, ref, expectedVersion);
        final next = edited.copyWith(
          status: current.status,
          players: current.players,
          version: current.version + 1,
        );
        final problems = ContestValidator.editProblems(current, next);
        if (problems.isNotEmpty) throw AdminFailure(problems.first);

        tx.update(ref, {
          ...ContestMapper.detailFields(next),
          'version': next.version,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        _writeFeed(tx, next);
        return next;
      }));

  Future<Contest> transition(
      String id,
      ContestStatus to, {
        required int expectedVersion,
      }) =>
      _guard(() => _db.runTransaction<Contest>((tx) async {
        final ref = _contests.doc(id);
        final current = await _read(tx, ref, expectedVersion);
        // Advisory check only: the server's rules use their own clock.
        final now = DateTime.now();

        if (!current.status.canMoveTo(to)) {
          throw AdminFailure(
              'A ${current.status.label.toLowerCase()} contest cannot become '
                  '${to.label.toLowerCase()}.');
        }
        if (to == ContestStatus.published) {
          final problems = ContestValidator.publishProblems(current, now);
          if (problems.isNotEmpty) throw AdminFailure(problems.first);
        }
        if (current.status == ContestStatus.published &&
            to == ContestStatus.draft &&
            !now.isBefore(current.opensAt)) {
          throw const AdminFailure(
              'This contest has opened, so entries may exist. Cancel it instead.');
        }

        final next = current.copyWith(status: to, version: current.version + 1);
        tx.update(ref, {
          'status': to.code,
          'version': next.version,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        _writeFeed(tx, next);
        return next;
      }));

  /// Closes entries now, using the server's clock.
  Future<Contest> lockNow(String id, {required int expectedVersion}) =>
      _guard(() => _db.runTransaction<Contest>((tx) async {
        final ref = _contests.doc(id);
        final current = await _read(tx, ref, expectedVersion);
        final now = DateTime.now();
        if (current.status != ContestStatus.published) {
          throw const AdminFailure('Only a published contest can be locked.');
        }
        if (now.isBefore(current.opensAt)) {
          throw const AdminFailure(
              'This contest has not opened yet. Unpublish or cancel it instead.');
        }

        // deadlineAt here is only a local approximation for display.
        final next = current.copyWith(
            deadlineAt: now, version: current.version + 1);
        tx.update(ref, {
          'deadlineAt': FieldValue.serverTimestamp(),
          'version': next.version,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        _writeFeed(tx, next, deadline: FieldValue.serverTimestamp());
        return next;
      }));

  Future<Contest> replacePlayers(
      String id,
      Map<String, ContestPlayer> players, {
        required int expectedVersion,
      }) =>
      _guard(() => _db.runTransaction<Contest>((tx) async {
        final ref = _contests.doc(id);
        final current = await _read(tx, ref, expectedVersion);
        if (current.status != ContestStatus.draft) {
          throw const AdminFailure('Players can only change while a contest is a draft.');
        }
        for (final e in players.entries) {
          if (e.key != e.value.id || e.value.problems().isNotEmpty) {
            throw AdminFailure('Player ${e.key} is invalid.');
          }
        }
        final next = current.copyWith(
            players: players, version: current.version + 1);
        tx.update(ref, {
          'players': ContestMapper.playersMap(next),
          'version': next.version,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return next;
      }));

  Future<void> deleteDraft(String id, {required int expectedVersion}) =>
      _guard(() => _db.runTransaction<void>((tx) async {
        final ref = _contests.doc(id);
        final current = await _read(tx, ref, expectedVersion);
        if (current.status != ContestStatus.draft) {
          throw const AdminFailure('Only a draft can be deleted. Cancel it instead.');
        }
        tx.delete(ref);
      }));

  // Reads must happen before any writes inside a transaction.
  Future<Contest> _read(
      Transaction tx,
      DocumentReference<Map<String, dynamic>> ref,
      int expectedVersion,
      ) async {
    final snap = await tx.get(ref);
    final data = snap.data();
    if (!snap.exists || data == null) {
      throw const AdminFailure('This contest no longer exists.');
    }
    final current = ContestMapper.fromDoc(snap.id, data);
    if (current.version != expectedVersion) {
      throw const AdminFailure(staleContestMessage);
    }
    return current;
  }

  /// Field-level merge into the feed map: no read, and serverTimestamp is
  /// allowed here because it sits in a map, not an array.
  void _writeFeed(Transaction tx, Contest c, {Object? deadline}) {
    tx.set(
      _feed,
      {
        'contests': {
          c.id: c.status == ContestStatus.draft
              ? FieldValue.delete()
              : ContestMapper.toSummary(c, deadline: deadline),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}