import 'contest_player.dart';
import 'contest_rules.dart';
import 'contest_status.dart';

class Contest {
  const Contest({
    required this.id,
    required this.title,
    required this.homeTeam,
    required this.awayTeam,
    required this.matchAt,
    required this.opensAt,
    required this.deadlineAt,
    required this.status,
    required this.version,
    required this.rules,
    required this.players,
  });

  final String id;
  final String title;
  final String homeTeam;
  final String awayTeam;
  final DateTime matchAt;
  final DateTime opensAt;
  final DateTime deadlineAt;
  final ContestStatus status;

  /// Increases on every admin change; used to detect stale edits and caches.
  final int version;
  final ContestRules rules;
  final Map<String, ContestPlayer> players;

  Contest copyWith({
    String? id,
    String? title,
    String? homeTeam,
    String? awayTeam,
    DateTime? matchAt,
    DateTime? opensAt,
    DateTime? deadlineAt,
    ContestStatus? status,
    int? version,
    ContestRules? rules,
    Map<String, ContestPlayer>? players,
  }) {
    return Contest(
      id: id ?? this.id,
      title: title ?? this.title,
      homeTeam: homeTeam ?? this.homeTeam,
      awayTeam: awayTeam ?? this.awayTeam,
      matchAt: matchAt ?? this.matchAt,
      opensAt: opensAt ?? this.opensAt,
      deadlineAt: deadlineAt ?? this.deadlineAt,
      status: status ?? this.status,
      version: version ?? this.version,
      rules: rules ?? this.rules,
      players: players ?? this.players,
    );
  }

  /// For display only. The server's rules decide who may actually enter.
  String displayLabel(DateTime now) {
    return switch (status) {
      ContestStatus.published => now.isBefore(opensAt)
          ? 'Published · opens soon'
          : now.isBefore(deadlineAt)
          ? 'Open'
          : 'Locked',
      _ => status.label,
    };
  }
}