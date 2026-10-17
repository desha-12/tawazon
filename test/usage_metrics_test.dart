import 'package:flutter_test/flutter_test.dart';
import 'package:tawazon/features/dashboard/domain/daily_usage.dart';
import 'package:tawazon/features/dashboard/presentation/usage_controller.dart';
import 'package:tawazon/services/detox_advisor.dart';

void main() {
  group('real usage metrics', () {
    test('uses the Android total when no category buckets are available', () {
      final today = DailyUsage(
        day: DateTime(2026, 10, 17),
        buckets: const {},
        totalHoursOverride: 2.5,
      );

      expect(today.totalHours, 2.5);
    });

    test('triggers the high-usage state at four hours only with access', () {
      final days = List.generate(
        7,
        (index) => DailyUsage(
          day: DateTime(2026, 10, 11 + index),
          buckets: const {},
          totalHoursOverride: index == 6 ? 4 : 0,
        ),
      );

      expect(
        UsageSnapshot(
          week: days,
          now: DateTime(2026, 10, 17),
          hasUsageAccess: true,
        ).highUsage,
        isTrue,
      );
      expect(
        UsageSnapshot(
          week: days,
          now: DateTime(2026, 10, 17),
          hasUsageAccess: false,
        ).highUsage,
        isFalse,
      );
    });

    test('offline assistant does not invent screen time without permission', () {
      final answer = const DetoxAdvisor().reply(
        prompt: 'How much screen time did I use?',
        arabic: true,
        today: DailyUsage(day: DateTime(2026, 10, 17), buckets: const {}),
        hasUsageData: false,
        lastSleepHours: null,
        prayerAlerts: false,
        mood: null,
      );

      expect(answer, contains('لا أستطيع قراءة وقت استخدامك'));
      expect(answer, isNot(contains('0.0')));
    });
  });
}
