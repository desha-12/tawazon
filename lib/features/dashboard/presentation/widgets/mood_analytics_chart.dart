import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/preferences_service.dart';
import '../../../ai_coach/domain/coach_message.dart';

class MoodAnalyticsChart extends ConsumerWidget {
  const MoodAnalyticsChart({super.key, required this.localeCode});

  final String localeCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings(localeCode);
    final cutoff =
        DateUtils.dateOnly(DateTime.now()).subtract(const Duration(days: 6));
    final dayMoods = <DateTime, Mood>{};
    final dayTimes = <DateTime, DateTime>{};
    final counts = {for (final mood in Mood.values) mood: 0};

    for (final entry in ref.watch(moodLogsProvider)) {
      final at = DateTime.tryParse(entry['at'] as String? ?? '');
      final moodName = entry['mood'] as String?;
      if (at == null || at.isBefore(cutoff) || moodName == null) continue;
      final mood =
          Mood.values.where((value) => value.name == moodName).firstOrNull;
      if (mood == null) continue;
      counts[mood] = counts[mood]! + 1;
      final day = DateUtils.dateOnly(at);
      if (at.isAfter(dayTimes[day] ?? DateTime.fromMillisecondsSinceEpoch(0))) {
        dayMoods[day] = mood;
        dayTimes[day] = at;
      }
    }

    final total = counts.values.fold<int>(0, (sum, count) => sum + count);
    if (total == 0) {
      return Text(strings.moodAnalyticsEmpty,
          style: const TextStyle(color: AppColors.muted));
    }

    final maxCount = counts.values.reduce((a, b) => a > b ? a : b);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$total ${strings.moodCount}',
            style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        const SizedBox(height: 8),
        SizedBox(
          height: 148,
          child: BarChart(
            BarChartData(
              maxY: (maxCount + 1).toDouble(),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final mood = Mood.values[groupIndex];
                    return BarTooltipItem(
                      '${_label(strings, mood)}\n${rod.toY.toInt()} ${strings.moodCount}',
                      TextStyle(
                        color: _color(mood),
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, _) {
                      final index = value.toInt();
                      if (index < 0 || index >= Mood.values.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 7),
                        child: Text(
                          _label(strings, Mood.values[index]),
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: [
                for (var index = 0; index < Mood.values.length; index++)
                  BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: counts[Mood.values[index]]!.toDouble(),
                        width: 24,
                        borderRadius: BorderRadius.circular(5),
                        color: _color(Mood.values[index]),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var offset = 6; offset >= 0; offset--)
              Expanded(
                child: _MoodDay(
                  date: DateUtils.dateOnly(DateTime.now())
                      .subtract(Duration(days: offset)),
                  mood: dayMoods[DateUtils.dateOnly(DateTime.now())
                      .subtract(Duration(days: offset))],
                  localeCode: localeCode,
                  strings: strings,
                ),
              ),
          ],
        ),
      ],
    );
  }

  String _label(AppStrings strings, Mood mood) => switch (mood) {
        Mood.calm => strings.moodCalm,
        Mood.restless => strings.moodRestless,
        Mood.tired => strings.moodTired,
        Mood.scattered => strings.moodScattered,
      };

  Color _color(Mood mood) => switch (mood) {
        Mood.calm => AppColors.mint,
        Mood.restless => AppColors.amber,
        Mood.tired => AppColors.sky,
        Mood.scattered => const Color(0xFFE88979),
      };
}

class _MoodDay extends StatelessWidget {
  const _MoodDay({
    required this.date,
    required this.mood,
    required this.localeCode,
    required this.strings,
  });

  final DateTime date;
  final Mood? mood;
  final String localeCode;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final label = mood == null
        ? strings.moodAnalyticsEmpty
        : switch (mood!) {
            Mood.calm => strings.moodCalm,
            Mood.restless => strings.moodRestless,
            Mood.tired => strings.moodTired,
            Mood.scattered => strings.moodScattered,
          };
    final color = switch (mood) {
      Mood.calm => AppColors.mint,
      Mood.restless => AppColors.amber,
      Mood.tired => AppColors.sky,
      Mood.scattered => const Color(0xFFE88979),
      null => AppColors.muted.withValues(alpha: 0.35),
    };

    return Tooltip(
      message: '${DateFormat.yMMMd(localeCode).format(date)}: $label',
      child: Column(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(height: 5),
          Text(DateFormat.E(localeCode).format(date),
              style: const TextStyle(color: AppColors.muted, fontSize: 9)),
        ],
      ),
    );
  }
}
