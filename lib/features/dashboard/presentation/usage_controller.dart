import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/usage_alert_service.dart';
import '../domain/daily_usage.dart';

class UsageSnapshot {
  const UsageSnapshot({
    required this.week,
    required this.now,
    required this.hasUsageAccess,
  });

  final List<DailyUsage> week;
  final DateTime now;
  final bool hasUsageAccess;

  DailyUsage get today => week.last;
  bool get highUsage => hasUsageAccess && today.totalHours >= 4;
}

final usageControllerProvider =
    NotifierProvider<UsageController, UsageSnapshot>(UsageController.new);

class UsageController extends Notifier<UsageSnapshot>
    with WidgetsBindingObserver {
  Timer? _timer;
  bool _disposed = false;
  bool _refreshing = false;

  @override
  UsageSnapshot build() {
    _disposed = false;
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() {
      _disposed = true;
      _timer?.cancel();
      WidgetsBinding.instance.removeObserver(this);
    });
    _timer = Timer.periodic(const Duration(minutes: 5), (_) => _refresh());
    final now = DateTime.now();
    unawaited(_refresh());
    return UsageSnapshot(
      week: _emptyWeek(now),
      now: now,
      hasUsageAccess: false,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_refresh());
  }

  Future<void> _refresh() async {
    if (_refreshing || _disposed) return;
    _refreshing = true;
    try {
      final service = ref.read(usageAlertServiceProvider);
      final hasAccess = await service.hasUsageAccess;
      final records = hasAccess ? await service.getUsageWeek() : null;
      if (_disposed) return;

      final now = DateTime.now();
      final byDate = <DateTime, UsageDayRecord>{
        for (final record in records ?? <UsageDayRecord>[])
          DateTime(record.day.year, record.day.month, record.day.day): record,
      };
      final week = List<DailyUsage>.generate(7, (index) {
        final day = DateTime(now.year, now.month, now.day - (6 - index));
        final record = byDate[day];
        return DailyUsage(
          day: day,
          buckets: const {},
          totalHoursOverride: hasAccess ? (record?.totalHours ?? 0) : null,
        );
      }, growable: false);
      state = UsageSnapshot(
        week: week,
        now: now,
        hasUsageAccess: hasAccess && records != null,
      );
    } finally {
      _refreshing = false;
    }
  }

  List<DailyUsage> _emptyWeek(DateTime now) => List.generate(7, (index) {
        final day = DateTime(now.year, now.month, now.day - (6 - index));
        return DailyUsage(day: day, buckets: const {});
      }, growable: false);
}
