import 'contest_player.dart';

abstract final class PlayerRoster {
  /// Keeps the contest document small: users read it on every contest open.
  static const maxPlayers = 60;

  static final _idNumber = RegExp(r'^p(\d+)$');

  static String _norm(String s) =>
      s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  static String keyOfParts(String name, String club) =>
      '${_norm(name)}|${_norm(club)}';

  static String keyOf(ContestPlayer p) => keyOfParts(p.name, p.club);

  /// Next free id of the form p01, p02, ...
  static String nextId(Iterable<String> existing) {
    final taken = existing.toSet();
    var max = 0;
    for (final id in taken) {
      final m = _idNumber.firstMatch(id);
      final n = m == null ? null : int.tryParse(m.group(1)!);
      if (n != null && n > max) max = n;
    }
    var n = max + 1;
    while (true) {
      final id = 'p${n.toString().padLeft(2, '0')}';
      if (!taken.contains(id)) return id;
      n++;
    }
  }

  static List<String> problems(Map<String, ContestPlayer> players) {
    final out = <String>[];
    if (players.length > maxPlayers) {
      out.add('A contest can have at most $maxPlayers players '
          '(there are ${players.length}).');
    }
    final seen = <String>{};
    for (final p in players.values) {
      if (!seen.add(keyOf(p))) {
        out.add('${p.name} appears twice for ${p.club}.');
      }
    }
    return out;
  }
}