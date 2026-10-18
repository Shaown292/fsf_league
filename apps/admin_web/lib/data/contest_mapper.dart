import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fsf_league_core/fsf_league_core.dart';

abstract final class ContestMapper {
  /// Fields an admin may edit after publishing (plus rules while in draft).
  static Map<String, Object?> detailFields(Contest c) => {
    'title': c.title.trim(),
    'homeTeam': c.homeTeam.trim(),
    'awayTeam': c.awayTeam.trim(),
    'matchAt': Timestamp.fromDate(c.matchAt),
    'opensAt': Timestamp.fromDate(c.opensAt),
    'deadlineAt': Timestamp.fromDate(c.deadlineAt),
    'rules': c.rules.toMap(),
  };

  static Map<String, Object?> playersMap(Contest c) => {
    for (final p in c.players.values) p.id: p.toMap(),
  };

  /// Everything except updatedAt, so it can be tested without Firebase.
  static Map<String, Object?> plainFields(Contest c) => {
    ...detailFields(c),
    'status': c.status.code,
    'version': c.version,
    'players': playersMap(c),
  };

  static Map<String, Object?> toNewDoc(Contest c) => {
    ...plainFields(c),
    'updatedAt': FieldValue.serverTimestamp(),
  };

  /// One entry in meta/activeContests. Keep it small: users read this on
  /// every app open.
  static Map<String, Object?> toSummary(Contest c, {Object? deadline}) => {
    'title': c.title.trim(),
    'homeTeam': c.homeTeam.trim(),
    'awayTeam': c.awayTeam.trim(),
    'matchAt': Timestamp.fromDate(c.matchAt),
    'opensAt': Timestamp.fromDate(c.opensAt),
    'deadlineAt': deadline ?? Timestamp.fromDate(c.deadlineAt),
    'status': c.status.code,
    'version': c.version,
  };

  static Contest fromDoc(String id, Map<String, dynamic> d) {
    DateTime time(String key) {
      final v = d[key];
      if (v is Timestamp) return v.toDate();
      throw FormatException('"$key" is missing or not a time');
    }

    final status = ContestStatus.tryParse(d['status']);
    if (status == null) {
      throw FormatException('unknown status "${d['status']}"');
    }
    final rawRules = d['rules'];
    if (rawRules is! Map) throw const FormatException('"rules" is missing');

    final players = <String, ContestPlayer>{};
    final rawPlayers = (d['players'] as Map?)?.cast<String, dynamic>() ?? {};
    rawPlayers.forEach((key, value) {
      players[key] =
          ContestPlayer.fromMap(key, (value as Map).cast<String, dynamic>());
    });

    return Contest(
      id: id,
      title: d['title'] as String? ?? '',
      homeTeam: d['homeTeam'] as String? ?? '',
      awayTeam: d['awayTeam'] as String? ?? '',
      matchAt: time('matchAt'),
      opensAt: time('opensAt'),
      deadlineAt: time('deadlineAt'),
      status: status,
      version: (d['version'] as num?)?.toInt() ?? 1,
      rules: ContestRules.fromMap(rawRules.cast<String, dynamic>()),
      players: players,
    );
  }
}