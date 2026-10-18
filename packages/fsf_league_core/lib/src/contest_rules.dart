import 'position.dart';

class ContestRules {
  const ContestRules({
    required this.budget,
    required this.squadSize,
    required this.positions,
    this.captainMultiplier = 2,
    this.maxPerClub = 0,
  });

  /// Tenths of a million (50.0 is stored as 500).
  final int budget;
  final int squadSize;
  final Map<Position, int> positions;
  final int captainMultiplier;

  /// 0 means no limit.
  final int maxPerClub;

  static const standard5 = ContestRules(
    budget: 500,
    squadSize: 5,
    positions: {
      Position.gk: 1,
      Position.def: 2,
      Position.mid: 1,
      Position.fwd: 1,
    },
  );

  int get positionTotal => positions.values.fold(0, (a, b) => a + b);

  List<String> problems() {
    final p = <String>[];
    if (budget <= 0) p.add('The budget must be greater than 0.');
    if (squadSize < 1 || squadSize > 11) {
      p.add('The squad size must be between 1 and 11.');
    }
    for (final pos in Position.values) {
      if ((positions[pos] ?? 0) < 0) {
        p.add('${pos.code} cannot be negative.');
      }
    }
    if (positionTotal != squadSize) {
      p.add('The positions add up to $positionTotal, '
          'but the squad size is $squadSize.');
    }
    if (captainMultiplier < 1 || captainMultiplier > 3) {
      p.add('The captain multiplier must be 1, 2 or 3.');
    }
    if (maxPerClub < 0) p.add('Max per club cannot be negative.');
    return p;
  }

  bool sameAs(ContestRules o) {
    if (budget != o.budget ||
        squadSize != o.squadSize ||
        captainMultiplier != o.captainMultiplier ||
        maxPerClub != o.maxPerClub) {
      return false;
    }
    for (final pos in Position.values) {
      if ((positions[pos] ?? 0) != (o.positions[pos] ?? 0)) return false;
    }
    return true;
  }

  Map<String, Object> toMap() => {
    'budget': budget,
    'squadSize': squadSize,
    'positions': {
      for (final e in positions.entries) e.key.code: e.value,
    },
    'captainMultiplier': captainMultiplier,
    'maxPerClub': maxPerClub,
  };

  factory ContestRules.fromMap(Map<String, dynamic> m) {
    final raw = (m['positions'] as Map).cast<String, dynamic>();
    return ContestRules(
      budget: (m['budget'] as num).toInt(),
      squadSize: (m['squadSize'] as num).toInt(),
      positions: {
        for (final pos in Position.values)
          pos: (raw[pos.code] as num?)?.toInt() ?? 0,
      },
      captainMultiplier: (m['captainMultiplier'] as num?)?.toInt() ?? 2,
      maxPerClub: (m['maxPerClub'] as num?)?.toInt() ?? 0,
    );
  }
}