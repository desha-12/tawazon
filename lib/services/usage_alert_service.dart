import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _usageAlertChannel = MethodChannel('com.example.tawazon/usage_alerts');

final usageAlertServiceProvider = Provider<UsageAlertService>((ref) {
  return UsageAlertService();
});

class UsageDayRecord {
  const UsageDayRecord({required this.day, required this.totalMillis});

  final DateTime day;
  final int totalMillis;

  double get totalHours => totalMillis / 3600000;
}

/// Android bridge for notification permission, Usage Access, and the daily
/// phone-usage threshold alert.
class UsageAlertService {
  Future<bool> get isSupported async =>
      await _invoke<bool>('isSupported') ?? false;

  Future<bool> get isEnabled async =>
      await _invoke<bool>('isUsageAlertEnabled') ?? false;

  Future<bool> get hasNotificationPermission async =>
      await _invoke<bool>('hasNotificationPermission') ?? false;

  Future<bool> get hasUsageAccess async =>
      await _invoke<bool>('hasUsageAccess') ?? false;

  Future<bool> requestNotificationPermission() async =>
      await _invoke<bool>('requestNotificationPermission') ?? false;

  Future<bool> openNotificationSettings() async =>
      await _invoke<bool>('openNotificationSettings') ?? false;

  Future<bool> openUsageAccessSettings() async =>
      await _invoke<bool>('openUsageAccessSettings') ?? false;

  Future<bool> enable({int thresholdMinutes = 240}) async =>
      await _invoke<bool>(
        'enableUsageAlert',
        <String, Object>{'thresholdMinutes': thresholdMinutes},
      ) ??
      false;

  Future<void> disable() async {
    await _invoke<bool>('disableUsageAlert');
  }

  Future<List<UsageDayRecord>?> getUsageWeek() async {
    final rows = await _invoke<List<dynamic>>('getUsageWeek');
    if (rows == null) return null;
    try {
      return rows.map((row) {
        final values = Map<Object?, Object?>.from(row as Map);
        final dayMillis = values['dayMillis'] as num;
        final totalMillis = values['totalMillis'] as num;
        return UsageDayRecord(
          day: DateTime.fromMillisecondsSinceEpoch(dayMillis.toInt()).toLocal(),
          totalMillis: totalMillis.toInt(),
        );
      }).toList(growable: false);
    } on TypeError {
      return null;
    }
  }

  Future<T?> _invoke<T>(String method, [Object? arguments]) async {
    try {
      return await _usageAlertChannel.invokeMethod<T>(method, arguments);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}