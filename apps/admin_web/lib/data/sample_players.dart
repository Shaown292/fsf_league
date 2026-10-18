import 'package:fsf_league_core/fsf_league_core.dart';

Map<String, ContestPlayer> samplePlayers() {
  const specs = <(String, Position, int)>[
    ('Keeper One', Position.gk, 45),
    ('Keeper Two', Position.gk, 50),
    ('Back One', Position.def, 50),
    ('Back Two', Position.def, 55),
    ('Back Three', Position.def, 60),
    ('Back Four', Position.def, 65),
    ('Mid One', Position.mid, 60),
    ('Mid Two', Position.mid, 80),
    ('Mid Three', Position.mid, 100),
    ('Mid Four', Position.mid, 120),
    ('Forward One', Position.fwd, 70),
    ('Forward Two', Position.fwd, 90),
    ('Forward Three', Position.fwd, 110),
    ('Forward Four', Position.fwd, 120),
  ];
  final out = <String, ContestPlayer>{};
  for (var i = 0; i < specs.length; i++) {
    final id = 'p${(i + 1).toString().padLeft(2, '0')}';
    out[id] = ContestPlayer(
      id: id,
      name: specs[i].$1,
      position: specs[i].$2,
      club: i.isEven ? 'ALP' : 'BET',
      price: specs[i].$3,
    );
  }
  return out;
}