import 'dart:math';

import '../features/dashboard/domain/daily_usage.dart';
import '../features/dashboard/domain/usage_category.dart';

class UsageSimulator {
  UsageSimulator({int? seed}) : _random = Random(seed ?? 42);

  final Random _random;

  List<DailyUsage> weekEnding(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return List.generate(7, (i) {
      final day = today.subtract(Duration(days: 6 - i));
      final weekend = day.weekday == DateTime.friday || day.weekday == DateTime.saturday;
      final social = _hours(weekend ? 1.8 : 1.1, weekend ? 3.4 : 2.2);
      final entertainment = _hours(weekend ? 1.4 : 0.6, weekend ? 2.8 : 1.6);
      final productivity = _hours(0.4, weekend ? 1.1 : 2.0);
      final system = _hours(0.2, 0.7);
      return DailyUsage(
        day: day,
        buckets: {
          UsageCategory.social: social,
          UsageCategory.entertainment: entertainment,
          UsageCategory.productivity: productivity,
          UsageCategory.system: system,
        },
      );
    });
  }

  DailyUsage liveOverlay(DailyUsage base, DateTime now) {
    final fraction = (now.hour * 60 + now.minute) / (24 * 60);
    final scaled = <UsageCategory, double>{};
    for (final entry in base.buckets.entries) {
      scaled[entry.key] = double.parse((entry.value * (0.35 + fraction * 0.7)).toStringAsFixed(2));
    }
    return DailyUsage(day: base.day, buckets: scaled);
  }

  double _hours(double min, double max) {
    return double.parse((min + _random.nextDouble() * (max - min)).toStringAsFixed(2));
  }
}
