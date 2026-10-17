class SleepLog {
  const SleepLog({required this.nightOf, required this.hours});

  final DateTime nightOf;
  final double hours;

  Map<String, dynamic> toJson() => {
        'nightOf': nightOf.toIso8601String(),
        'hours': hours,
      };

  factory SleepLog.fromJson(Map<String, dynamic> json) {
    return SleepLog(
      nightOf: DateTime.tryParse(json['nightOf'] as String? ?? '') ?? DateTime.now(),
      hours: (json['hours'] as num?)?.toDouble() ?? 0,
    );
  }
}
