import 'contest.dart';
import 'contest_player.dart';
import 'contest_status.dart';
import 'money.dart';
import 'position.dart';

abstract final class ContestValidator {
  static List<String> detailsProblems(Contest c) {
    final p = <String>[];
    final title = c.title.trim();
    if (title.isEmpty) {
      p.add('Enter a title.');
    } else if (title.length > 80) {
      p.add('The title can be at most 80 characters.');
    }
    for (final team in [c.homeTeam.trim(), c.awayTeam.trim()]) {
      if (team.isEmpty || team.length > 40) {
        p.add('Team names must be 1 to 40 characters.');
        break;
      }
    }
    if (c.homeTeam.trim().toLowerCase() == c.awayTeam.trim().toLowerCase()) {
      p.add('Home and away teams must be different.');
    }
    if (!c.opensAt.isBefore(c.deadlineAt)) {
      p.add('Entries must open before the deadline.');
    }
    if (c.deadlineAt.isAfter(c.matchAt)) {
      p.add('The deadline must be at or before kickoff.');
    }
    p.addAll(c.rules.problems());
    return p;
  }

  /// Everything that must be true before users can see and enter a contest.
  static List<String> publishProblems(Contest c, DateTime now) {
    final problems = detailsProblems(c);
    if (!c.deadlineAt.isAfter(now)) {
      problems.add('The deadline is already in the past.');
    }

    for (final entry in c.players.entries) {
      final player = entry.value;
      final label = player.name.isEmpty ? entry.key : player.name;
      if (entry.key != player.id) problems.add('$label has a mismatched id.');
      for (final issue in player.problems()) {
        problems.add('$label $issue.');
      }
    }

    // Feasibility checks only make sense when the rules themselves are valid.
    if (c.rules.problems().isNotEmpty) return problems;

    final available = [
      for (final p in c.players.values)
        if (p.status == PlayerStatus.available) p,
    ];
    if (available.length < c.rules.squadSize) {
      problems.add('Add at least ${c.rules.squadSize} available players '
          '(there are ${available.length}).');
    }

    var cheapest = 0;
    var positionsOk = true;
    for (final pos in Position.values) {
      final need = c.rules.positions[pos] ?? 0;
      final prices = [
        for (final p in available)
          if (p.position == pos) p.price,
      ]..sort();
      if (prices.length < need) {
        positionsOk = false;
        problems.add('Add at least $need ${pos.code} players '
            '(there are ${prices.length}).');
      } else {
        cheapest += prices.take(need).fold(0, (a, b) => a + b);
      }
    }
    if (positionsOk && cheapest > c.rules.budget) {
      problems.add('Even the cheapest valid squad costs '
          '${Money.format(cheapest)}, above the budget of '
          '${Money.format(c.rules.budget)}.');
    }

    final max = c.rules.maxPerClub;
    if (max > 0) {
      final clubs = {for (final p in available) p.club}.length;
      if (clubs * max < c.rules.squadSize) {
        problems.add('With at most $max players per club, '
            '${c.rules.squadSize} players need at least '
            '${(c.rules.squadSize / max).ceil()} clubs (there are $clubs).');
      }
    }
    return problems;
  }

  /// Once published, users may have entries built on these fields.
  static List<String> editProblems(Contest current, Contest updated) {
    final problems = detailsProblems(updated);
    if (current.status != ContestStatus.draft) {
      if (!current.rules.sameAs(updated.rules)) {
        problems.add('Rules cannot change after a contest is published.');
      }
      if (current.homeTeam != updated.homeTeam ||
          current.awayTeam != updated.awayTeam) {
        problems.add('Team names cannot change after a contest is published.');
      }
      if (!current.opensAt.isAtSameMomentAs(updated.opensAt)) {
        problems.add('The opening time cannot change after publishing.');
      }
    }
    return problems;
  }
}