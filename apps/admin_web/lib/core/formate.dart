const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Shown in the browser's time zone. Stored values are always UTC.
String formatDateTime(DateTime t) {
  final l = t.toLocal();
  final hh = l.hour.toString().padLeft(2, '0');
  final mm = l.minute.toString().padLeft(2, '0');
  return '${_weekdays[l.weekday - 1]} ${l.day} ${_months[l.month - 1]} ${l.year}, $hh:$mm';
}

String timezoneLabel() {
  final offset = DateTime.now().timeZoneOffset;
  final sign = offset.isNegative ? '-' : '+';
  final a = offset.abs();
  final hh = a.inHours.toString().padLeft(2, '0');
  final mm = (a.inMinutes % 60).toString().padLeft(2, '0');
  return 'UTC$sign$hh:$mm';
}