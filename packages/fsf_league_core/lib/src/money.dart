/// Money is stored as integer tenths of a million: 50.0 is 500.
abstract final class Money {
  static String format(int tenths) => '${tenths ~/ 10}.${tenths % 10}';

  /// Accepts "50", "50.0", "7.5". Returns null for anything else.
  static int? parse(String input) {
    final m = RegExp(r'^(\d{1,4})(?:\.(\d))?$').firstMatch(input.trim());
    if (m == null) return null;
    return int.parse(m.group(1)!) * 10 + int.parse(m.group(2) ?? '0');
  }
}