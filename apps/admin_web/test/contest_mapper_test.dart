import 'package:flutter_test/flutter_test.dart';
import 'package:fsf_league_admin/data/contest_mapper.dart';
import 'package:fsf_league_core/fsf_league_core.dart';

void main() {
  test('a contest survives the Firestore map shape', () {
    final contest = Contest(
      id: 'c1',
      title: 'Alpha vs Beta',
      homeTeam: 'Alpha',
      awayTeam: 'Beta',
      matchAt: DateTime.utc(2026, 11, 1, 20),
      opensAt: DateTime.utc(2026, 10, 25),
      deadlineAt: DateTime.utc(2026, 11, 1, 19),
      status: ContestStatus.published,
      version: 3,
      rules: ContestRules.standard5,
      players: const {
        'p1': ContestPlayer(
          id: 'p1',
          name: 'Keeper One',
          position: Position.gk,
          club: 'ALP',
          price: 45,
        ),
      },
    );

    final back = ContestMapper.fromDoc('c1', ContestMapper.plainFields(contest));

    expect(back.title, contest.title);
    expect(back.status, ContestStatus.published);
    expect(back.version, 3);
    expect(back.rules.sameAs(contest.rules), isTrue);
    expect(back.players['p1']!.price, 45);
    expect(back.deadlineAt.isAtSameMomentAs(contest.deadlineAt), isTrue);
  });

  test('a document with an unknown status is rejected, not guessed', () {
    final doc = {
      ...ContestMapper.plainFields(Contest(
        id: 'c1',
        title: 'T',
        homeTeam: 'A',
        awayTeam: 'B',
        matchAt: DateTime.utc(2026, 11, 1),
        opensAt: DateTime.utc(2026, 10, 1),
        deadlineAt: DateTime.utc(2026, 10, 31),
        status: ContestStatus.draft,
        version: 1,
        rules: ContestRules.standard5,
        players: const {},
      )),
      'status': 'NONSENSE',
    };
    expect(() => ContestMapper.fromDoc('c1', doc), throwsFormatException);
  });
}