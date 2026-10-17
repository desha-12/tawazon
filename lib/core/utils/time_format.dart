import 'package:intl/intl.dart';

String formatHours(double hours, {String localeCode = 'en'}) {
  final totalMinutes = (hours * 60).round();
  final h = totalMinutes ~/ 60;
  final m = totalMinutes.remainder(60);
  final arabic = localeCode.startsWith('ar');
  final number = NumberFormat.decimalPattern(localeCode);
  final hourUnit = arabic ? 'س' : 'h';
  final minuteUnit = arabic ? 'د' : 'm';
  if (h <= 0) return '${number.format(m)}$minuteUnit';
  if (m == 0) return '${number.format(h)}$hourUnit';
  return '${number.format(h)}$hourUnit ${number.format(m)}$minuteUnit';
}

String two(int n) => n.toString().padLeft(2, '0');

String clock(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60);
  if (h > 0) return '${two(h)}:${two(m)}:${two(s)}';
  return '${two(m)}:${two(s)}';
}
