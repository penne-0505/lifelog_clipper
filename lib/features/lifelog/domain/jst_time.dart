const Duration jstOffset = Duration(hours: 9);
const String jstTimezone = 'Asia/Tokyo';

DateTime toJst(DateTime value) => value.toUtc().add(jstOffset);

DateTime fromJst(DateTime value) => value.toUtc().subtract(jstOffset);

DateTime truncateToSeconds(DateTime value) {
  final int seconds = value.millisecondsSinceEpoch ~/ 1000;
  return DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);
}

String formatJstDateTime(DateTime jst) {
  final String date = formatJstDate(jst);
  final String hour = _pad2(jst.hour);
  final String minute = _pad2(jst.minute);
  final String second = _pad2(jst.second);
  return '${date}T$hour:$minute:$second+09:00';
}

String formatJstDate(DateTime jst) {
  final String year = jst.year.toString().padLeft(4, '0');
  final String month = _pad2(jst.month);
  final String day = _pad2(jst.day);
  return '$year-$month-$day';
}

bool isSameJstDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String _pad2(int value) => value.toString().padLeft(2, '0');
