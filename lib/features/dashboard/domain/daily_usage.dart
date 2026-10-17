import 'usage_category.dart';

class DailyUsage {
  const DailyUsage({
    required this.day,
    required this.buckets,
    this.totalHoursOverride,
  });

  final DateTime day;
  final Map<UsageCategory, double> buckets;
  final double? totalHoursOverride;

  double get totalHours =>
      totalHoursOverride ?? buckets.values.fold(0, (a, b) => a + b);

  DailyUsage copyWith({
    DateTime? day,
    Map<UsageCategory, double>? buckets,
    double? totalHoursOverride,
  }) {
    return DailyUsage(
      day: day ?? this.day,
      buckets: buckets ?? this.buckets,
      totalHoursOverride: totalHoursOverride ?? this.totalHoursOverride,
    );
  }
}
