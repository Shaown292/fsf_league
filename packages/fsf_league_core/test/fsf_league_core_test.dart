import 'package:flutter_test/flutter_test.dart';

import 'package:fsf_league_core/fsf_league_core.dart';

void main() {
  group('Usernames', () {
    test('accepts valid names', () {
      for (final name in ['abc', 'shaown_01', 'A_b_C_123', 'a' * 20]) {
        expect(Usernames.isValid(name), isTrue, reason: name);
      }
    });

    test('rejects invalid names', () {
      for (final name in ['ab', 'a' * 21, 'has space', 'dash-name', 'emoji😀', '']) {
        expect(Usernames.isValid(name), isFalse, reason: name);
      }
    });

    test('validate returns messages', () {
      expect(Usernames.validate(null), isNotNull);
      expect(Usernames.validate('ab'), isNotNull);
      expect(Usernames.validate(' good_name '), isNull);
    });
  });
}
