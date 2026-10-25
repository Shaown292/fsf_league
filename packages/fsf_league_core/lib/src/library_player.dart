import 'contest_player.dart';
import 'player_draft.dart';
import 'position.dart';

class LibraryPlayer {
  const LibraryPlayer({
    required this.id,
    required this.name,
    required this.position,
    required this.club,
    required this.defaultPrice,
  });

  final String id;
  final String name;
  final Position position;
  final String club;

  /// Tenths of a million.
  final int defaultPrice;

  /// Deterministic: the same name and club always map to the same document,
  /// so saving twice updates instead of duplicating. Keeps letters, marks and
  /// digits of any script (marks matter for Bangla vowel signs).
  static String idFor(String name, String club) {
    String slug(String s) => s
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^\p{L}\p{M}\p{N}]+', unicode: true), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final n = slug(name);
    final c = slug(club);
    return '${n.isEmpty ? 'player' : n}__${c.isEmpty ? 'club' : c}';
  }

  factory LibraryPlayer.fromDraft(PlayerDraft d) => LibraryPlayer(
    id: idFor(d.name, d.club),
    name: d.name.trim(),
    position: d.position,
    club: d.club.trim(),
    defaultPrice: d.price,
  );

  factory LibraryPlayer.fromPlayer(ContestPlayer p) => LibraryPlayer(
    id: idFor(p.name, p.club),
    name: p.name.trim(),
    position: p.position,
    club: p.club.trim(),
    defaultPrice: p.price,
  );

  PlayerDraft toDraft() => PlayerDraft(
    name: name,
    position: position,
    club: club,
    price: defaultPrice,
  );

  Map<String, Object> toMap() => {
    'name': name,
    'position': position.code,
    'club': club,
    'defaultPrice': defaultPrice,
  };

  factory LibraryPlayer.fromMap(String id, Map<String, dynamic> m) {
    final position = Position.tryParse(m['position']);
    if (position == null) {
      throw FormatException('library player $id has an unknown position');
    }
    return LibraryPlayer(
      id: id,
      name: m['name'] as String? ?? '',
      position: position,
      club: m['club'] as String? ?? '',
      defaultPrice: (m['defaultPrice'] as num?)?.toInt() ?? 0,
    );
  }
}