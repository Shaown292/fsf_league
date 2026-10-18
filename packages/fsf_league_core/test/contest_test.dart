import 'package:flutter_test/flutter_test.dart';
import 'package:fsf_league_core/fsf_league_core.dart';

Map<String, ContestPlayer> _players() {
  const specs = <(Position, int)>[
    (Position.gk, 40),
    (Position.gk, 55),
    (Position.def, 45),
    (Position.def, 50),
    (Position.def, 65),
    (Position.mid, 60),
    (Position.mid, 100),
    (Position.fwd, 70),
    (Position.fwd, 120),
  ];
  final out = <String, ContestPlayer>{};
  for (var i = 0; i < specs.length; i++) {
    final id = 'p${i + 1}';
    out[id] = ContestPlayer(
      id: id,
      name: 'Player ${i + 1}',
      position: specs[i].$1,
      club: i.isEven ? 'ALP' : 'BET',
      price: specs[i].$2,
    );
  }
  return out;
}

final _kickoff = DateTime.utc(2026, 11, 1, 20);
final _now = DateTime.utc(2026, 10, 26);

Contest _contest({
  ContestStatus status = ContestStatus.draft,
  ContestRules rules = ContestRules.standard5,
  Map<String, ContestPlayer>? players,
  DateTime? deadline,
}) {
  return Contest(
    id: 'c1',
    title: 'Alpha vs Beta',
    homeTeam: 'Alpha',
    awayTeam: 'Beta',
    matchAt: _kickoff,
    opensAt: DateTime.utc(2026, 10, 25),
    deadlineAt: deadline ?? _kickoff.subtract(const Duration(hours: 1)),
    status: status,
    version: 1,
    rules: rules,
    players: players ?? _players(),
  );
}

void main() {
  group('Money', () {
    test('parses and formats tenths', () {
      expect(Money.parse('50'), 500);
      expect(Money.parse('50.0'), 500);
      expect(Money.parse('7.5'), 75);
      expect(Money.format(500), '50.0');
      expect(Money.format(75), '7.5');
    });

    test('rejects bad input', () {
      for (final bad in ['', 'abc', '7.55', '-1', '1,5', '12345']) {
        expect(Money.parse(bad), isNull, reason: bad);
      }
    });
  });

  group('ContestRules', () {
    test('standard rules are valid', () {
      expect(ContestRules.standard5.problems(), isEmpty);
    });

    test('positions must add up to the squad size', () {
      const rules = ContestRules(
        budget: 500,
        squadSize: 5,
        positions: {Position.gk: 1, Position.def: 2, Position.mid: 1},
      );
      expect(rules.problems(), isNotEmpty);
    });

    test('captain multiplier is limited to 1 to 3', () {
      const rules = ContestRules(
        budget: 500,
        squadSize: 5,
        positions: {
          Position.gk: 1,
          Position.def: 2,
          Position.mid: 1,
          Position.fwd: 1,
        },
        captainMultiplier: 4,
      );
      expect(rules.problems(), isNotEmpty);
    });

    test('round trips through a map', () {
      final back = ContestRules.fromMap(ContestRules.standard5.toMap());
      expect(back.sameAs(ContestRules.standard5), isTrue);
    });
  });

  group('details validation', () {
    test('accepts a valid contest', () {
      expect(ContestValidator.detailsProblems(_contest()), isEmpty);
    });

    test('rejects a deadline after kickoff', () {
      final problems = ContestValidator.detailsProblems(
          _contest(deadline: _kickoff.add(const Duration(hours: 1))));
      expect(problems.join(), contains('kickoff'));
    });

    test('rejects identical teams', () {
      final c = _contest().copyWith(awayTeam: 'alpha');
      expect(ContestValidator.detailsProblems(c).join(), contains('different'));
    });
  });

  group('publish validation', () {
    test('a complete contest can be published', () {
      expect(ContestValidator.publishProblems(_contest(), _now), isEmpty);
    });

    test('fails when the deadline has passed', () {
      final problems = ContestValidator.publishProblems(
          _contest(), DateTime.utc(2026, 11, 2));
      expect(problems.join(), contains('past'));
    });

    test('fails when a position has too few players', () {
      final noDefenders = Map.fromEntries(
        _players().entries.where((e) => e.value.position != Position.def),
      );
      final problems = ContestValidator.publishProblems(
          _contest(players: noDefenders), _now);
      expect(problems.join(), contains('DEF'));
    });

    test('fails when the cheapest squad exceeds the budget', () {
      const tight = ContestRules(
        budget: 200,
        squadSize: 5,
        positions: {
          Position.gk: 1,
          Position.def: 2,
          Position.mid: 1,
          Position.fwd: 1,
        },
      );
      final problems =
      ContestValidator.publishProblems(_contest(rules: tight), _now);
      expect(problems.join(), contains('cheapest'));
    });

    test('unavailable players do not count', () {
      final players = _players().map((id, p) => MapEntry(
        id,
        p.position == Position.fwd
            ? ContestPlayer(
          id: p.id,
          name: p.name,
          position: p.position,
          club: p.club,
          price: p.price,
          status: PlayerStatus.unavailable,
        )
            : p,
      ));
      final problems =
      ContestValidator.publishProblems(_contest(players: players), _now);
      expect(problems.join(), contains('FWD'));
    });
  });

  group('edit validation', () {
    const otherRules = ContestRules(
      budget: 600,
      squadSize: 5,
      positions: {
        Position.gk: 1,
        Position.def: 2,
        Position.mid: 1,
        Position.fwd: 1,
      },
    );

    test('a draft may change its rules', () {
      final current = _contest();
      expect(
        ContestValidator.editProblems(
            current, current.copyWith(rules: otherRules)),
        isEmpty,
      );
    });

    test('a published contest may not change its rules', () {
      final current = _contest(status: ContestStatus.published);
      expect(
        ContestValidator.editProblems(
            current, current.copyWith(rules: otherRules)),
        isNotEmpty,
      );
    });

    test('a published contest may change title and deadline', () {
      final current = _contest(status: ContestStatus.published);
      final updated = current.copyWith(
        title: 'New title',
      );
      expect(ContestValidator.editProblems(current, updated), isEmpty);
    });
  });

  group('status transitions', () {
    test('allows the planned path', () {
      expect(ContestStatus.draft.canMoveTo(ContestStatus.published), isTrue);
      expect(ContestStatus.published.canMoveTo(ContestStatus.cancelled), isTrue);
    });

    test('blocks skipping steps and leaving final states', () {
      expect(ContestStatus.draft.canMoveTo(ContestStatus.completed), isFalse);
      expect(ContestStatus.completed.canMoveTo(ContestStatus.draft), isFalse);
      expect(ContestStatus.cancelled.canMoveTo(ContestStatus.published), isFalse);
    });
  });
}