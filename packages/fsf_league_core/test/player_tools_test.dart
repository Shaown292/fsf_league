import 'package:flutter_test/flutter_test.dart';
import 'package:fsf_league_core/fsf_league_core.dart';

ContestPlayer _p(String id, String name, String club) => ContestPlayer(
  id: id,
  name: name,
  position: Position.mid,
  club: club,
  price: 50,
);

void main() {
  group('PlayerRoster', () {
    test('nextId starts at p01 and skips used ids', () {
      expect(PlayerRoster.nextId(const []), 'p01');
      expect(PlayerRoster.nextId(const ['p01', 'p02']), 'p03');
      expect(PlayerRoster.nextId(const ['p05', 'custom']), 'p06');
    });

    test('duplicates are detected case-insensitively', () {
      final problems = PlayerRoster.problems({
        'p01': _p('p01', 'Saka', 'ARS'),
        'p02': _p('p02', ' saka ', 'ars'),
      });
      expect(problems.join(), contains('twice'));
    });

    test('same name at a different club is allowed', () {
      expect(
        PlayerRoster.problems({
          'p01': _p('p01', 'Saka', 'ARS'),
          'p02': _p('p02', 'Saka', 'LIV'),
        }),
        isEmpty,
      );
    });

    test('too many players is reported', () {
      final many = {
        for (var i = 1; i <= PlayerRoster.maxPlayers + 1; i++)
          'p$i': _p('p$i', 'Player $i', 'C$i'),
      };
      expect(PlayerRoster.problems(many).join(), contains('at most'));
    });
  });

  group('PlayerListParser', () {
    test('parses comma separated lines', () {
      final r = PlayerListParser.parse('Saka, MID, ARS, 10.0');
      expect(r.errors, isEmpty);
      expect(r.drafts.single.price, 100);
      expect(r.drafts.single.position, Position.mid);
    });

    test('parses tab separated lines, headers, comments and blanks', () {
      final r = PlayerListParser.parse(
        'Name\tPosition\tClub\tPrice\n'
            '# a comment\n'
            '\n'
            'Raya\tgk\tARS\t£5.5m\n',
      );
      expect(r.errors, isEmpty);
      expect(r.drafts.single.name, 'Raya');
      expect(r.drafts.single.position, Position.gk);
      expect(r.drafts.single.price, 55);
    });

    test('reports line numbers for bad lines', () {
      final r = PlayerListParser.parse(
        'Saka, MID, ARS, 10.0\n'
            'Broken line\n'
            'Odd, XYZ, ARS, 5\n'
            'Cheap, DEF, ARS, abc\n',
      );
      expect(r.drafts.length, 1);
      expect(r.errors.length, 3);
      expect(r.errors[0], contains('Line 2'));
      expect(r.errors[1], contains('Line 3'));
      expect(r.errors[2], contains('Line 4'));
    });

    test('rejects a zero price', () {
      expect(PlayerListParser.parse('Free, FWD, ARS, 0').errors, isNotEmpty);
    });

    test('refuses a huge paste', () {
      final text = List.generate(
        PlayerListParser.maxRows + 1,
            (i) => 'P$i, MID, C, 5.0',
      ).join('\n');
      final r = PlayerListParser.parse(text);
      expect(r.drafts, isEmpty);
      expect(r.errors, isNotEmpty);
    });
  });

  group('LibraryPlayer', () {
    test('id ignores case and spacing', () {
      expect(LibraryPlayer.idFor('Bukayo Saka', 'ARS'), 'bukayo_saka__ars');
      expect(LibraryPlayer.idFor('  BUKAYO   saka ', 'Ars'), 'bukayo_saka__ars');
    });

    test('empty names fall back to safe ids', () {
      expect(LibraryPlayer.idFor('', ''), 'player__club');
    });

    test('Bangla names keep their letters', () {
      final id = LibraryPlayer.idFor('সাকা', 'আর্সেনাল');
      expect(id.startsWith('সাকা__'), isTrue);
    });

    test('round trips through a map', () {
      final p = LibraryPlayer.fromDraft(const PlayerDraft(
        name: 'Saka',
        position: Position.mid,
        club: 'ARS',
        price: 100,
      ));
      final back = LibraryPlayer.fromMap(p.id, p.toMap());
      expect(back.name, 'Saka');
      expect(back.defaultPrice, 100);
      expect(back.position, Position.mid);
    });
  });
}