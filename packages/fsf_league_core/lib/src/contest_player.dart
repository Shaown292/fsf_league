import 'position.dart';

enum PlayerStatus {
  available('available'),
  unavailable('unavailable');

  const PlayerStatus(this.code);
  final String code;

  static PlayerStatus? tryParse(Object? code) {
    for (final s in values) {
      if (s.code == code) return s;
    }
    return null;
  }
}

class ContestPlayer {
  const ContestPlayer({
    required this.id,
    required this.name,
    required this.position,
    required this.club,
    required this.price,
    this.status = PlayerStatus.available,
  });

  final String id;
  final String name;
  final Position position;
  final String club;

  /// Tenths of a million.
  final int price;
  final PlayerStatus status;

  static final _idPattern = RegExp(r'^[A-Za-z0-9_]{1,20}$');

  List<String> problems() {
    final p = <String>[];
    if (!_idPattern.hasMatch(id)) p.add('has an invalid id');
    if (name.trim().isEmpty || name.trim().length > 40) {
      p.add('needs a name of 1 to 40 characters');
    }
    if (club.trim().isEmpty || club.trim().length > 20) {
      p.add('needs a club of 1 to 20 characters');
    }
    if (price <= 0) p.add('needs a price above 0');
    return p;
  }

  Map<String, Object> toMap() => {
    'name': name.trim(),
    'position': position.code,
    'club': club.trim(),
    'price': price,
    'status': status.code,
  };

  factory ContestPlayer.fromMap(String id, Map<String, dynamic> m) {
    final position = Position.tryParse(m['position']);
    if (position == null) {
      throw FormatException('player $id has an unknown position');
    }
    return ContestPlayer(
      id: id,
      name: m['name'] as String? ?? '',
      position: position,
      club: m['club'] as String? ?? '',
      price: (m['price'] as num).toInt(),
      status: PlayerStatus.tryParse(m['status']) ?? PlayerStatus.available,
    );
  }
}