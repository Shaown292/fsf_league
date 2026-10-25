import 'money.dart';
import 'player_draft.dart';
import 'position.dart';

class PlayerListParseResult {
  const PlayerListParseResult(this.drafts, this.errors);
  final List<PlayerDraft> drafts;
  final List<String> errors;
}

/// Parses pasted lines: "name, position, club, price".
/// Tab-separated lines (copied from a spreadsheet) work too.
abstract final class PlayerListParser {
  static const maxRows = 200;

  static PlayerListParseResult parse(String text) {
    final drafts = <PlayerDraft>[];
    final errors = <String>[];
    final lines = text.split(RegExp(r'\r?\n'));

    for (var i = 0; i < lines.length; i++) {
      final raw = lines[i].trim();
      if (raw.isEmpty || raw.startsWith('#')) continue;

      final delimiter = raw.contains('\t') ? '\t' : ',';
      final cells = raw.split(delimiter).map((c) => c.trim()).toList();
      final n = i + 1;

      if (cells.length != 4) {
        errors.add('Line $n: expected name, position, club, price.');
        continue;
      }
      if (cells[0].toLowerCase() == 'name') continue; // header row

      final position = Position.tryParse(cells[1].toUpperCase());
      if (position == null) {
        errors.add('Line $n (${cells[0]}): position must be GK, DEF, MID or FWD.');
        continue;
      }

      final priceText = cells[3]
          .replaceAll('£', '')
          .replaceAll(RegExp(r'[mM]$'), '')
          .trim();
      final price = Money.parse(priceText);
      if (price == null) {
        errors.add('Line $n (${cells[0]}): price must look like 7.5.');
        continue;
      }

      final draft = PlayerDraft(
        name: cells[0],
        position: position,
        club: cells[2],
        price: price,
      );
      final issues = draft.toPlayer('tmp').problems();
      if (issues.isNotEmpty) {
        errors.add('Line $n (${cells[0]}): ${issues.join(', ')}.');
        continue;
      }
      drafts.add(draft);
    }

    if (drafts.length > maxRows) {
      errors.add('Too many players at once (the limit is $maxRows).');
      drafts.clear();
    }
    return PlayerListParseResult(drafts, errors);
  }
}