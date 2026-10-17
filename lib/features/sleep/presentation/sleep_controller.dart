import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/preferences_service.dart';
import '../../dashboard/presentation/usage_controller.dart';
import '../domain/sleep_log.dart';

final sleepLogsProvider = NotifierProvider<SleepController, List<SleepLog>>(SleepController.new);

class SleepController extends Notifier<List<SleepLog>> {
  @override
  List<SleepLog> build() {
    return ref
        .read(preferencesServiceProvider)
        .sleepLogs()
        .map(SleepLog.fromJson)
        .toList()
      ..sort((a, b) => a.nightOf.compareTo(b.nightOf));
  }

  Future<void> add(double hours) async {
    final night = DateTime.now().subtract(const Duration(hours: 6));
    final day = DateTime(night.year, night.month, night.day);
    final next = [
      ...state.where((e) => e.nightOf != day),
      SleepLog(nightOf: day, hours: hours),
    ]..sort((a, b) => a.nightOf.compareTo(b.nightOf));
    state = next;
    await ref.read(preferencesServiceProvider).writeSleepLogs(next.map((e) => e.toJson()).toList());
  }

  double? get latestHours => state.isEmpty ? null : state.last.hours;
}

class SleepCorrelation {
  const SleepCorrelation({
    required this.message,
    required this.shortSleepAvgUsage,
    required this.restedAvgUsage,
  });

  final String message;
  final double? shortSleepAvgUsage;
  final double? restedAvgUsage;
}

final sleepCorrelationProvider = Provider<SleepCorrelation>((ref) {
  final logs = ref.watch(sleepLogsProvider);
  final week = ref.watch(usageControllerProvider).week;
  final arabic = ref.watch(preferencesServiceProvider).locale().languageCode == 'ar';

  double? avgFor(bool Function(SleepLog) test) {
    final hours = <double>[];
    for (final log in logs.where(test)) {
      for (final day in week) {
        if (day.day.year == log.nightOf.year &&
            day.day.month == log.nightOf.month &&
            day.day.day == log.nightOf.day) {
          hours.add(day.totalHours);
        }
      }
    }
    if (hours.isEmpty) return null;
    return hours.reduce((a, b) => a + b) / hours.length;
  }

  final shortU = avgFor((l) => l.hours < 6.5);
  final restU = avgFor((l) => l.hours >= 7);

  String message;
  if (logs.isEmpty) {
    message = arabic
        ? 'سجّل ليلة واحدة على الأقل لنرى إن كان النوم يهدّئ الشاشة.'
        : 'Log at least one night so we can see whether sleep quiets the screen.';
  } else if (shortU != null && restU != null) {
    final delta = ((shortU - restU) / restU * 100).round();
    message = arabic
        ? 'في الليالي الأقصَر من ٦.٥ ساعات، يرتفع وقت الشاشة بنحو $delta٪ مقارنة بالليالي المرتاحة.'
        : 'On nights under 6.5 hours, screen time runs about $delta% higher than well-rested days.';
  } else {
    message = arabic
        ? 'ما زلنا نجمع ليالي كافية للمقارنة. استمر في التسجيل.'
        : 'Still gathering enough nights to compare. Keep logging.';
  }

  return SleepCorrelation(
    message: message,
    shortSleepAvgUsage: shortU,
    restedAvgUsage: restU,
  );
});
