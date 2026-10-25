import 'contest_player.dart';
import 'position.dart';

/// A player before it has an id: what the add/edit forms produce.
class PlayerDraft {
  const PlayerDraft({
    required this.name,
    required this.position,
    required this.club,
    required this.price,
    this.status = PlayerStatus.available,
  });

  final String name;
  final Position position;
  final String club;

  /// Tenths of a million.
  final int price;
  final PlayerStatus status;

  ContestPlayer toPlayer(String id) => ContestPlayer(
    id: id,
    name: name.trim(),
    position: position,
    club: club.trim(),
    price: price,
    status: status,
  );
}