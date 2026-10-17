import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/time_format.dart';
import '../../domain/daily_usage.dart';

class UsageChart extends StatelessWidget {
  const UsageChart({super.key, required this.week, required this.localeCode});

  final List<DailyUsage> week;
  final String localeCode;

  @override
  Widget build(BuildContext context) {
    final maxY = week.fold<double>(0, (m, d) => d.totalHours > m ? d.totalHours : m);
    return SizedBox(
      height: 196,
      child: BarChart(
        BarChartData(
          maxY: (maxY + 1).clamp(5, 12),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final day = week[groupIndex];
                return BarTooltipItem(
                  '${DateFormat.E(localeCode).format(day.day)}\n${formatHours(rod.toY, localeCode: localeCode)}',
                  const TextStyle(
                    color: AppColors.frost,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, _) {
                  final i = value.toInt();
                  if (i < 0 || i >= week.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat.E(localeCode).format(week[i].day),
                      style: const TextStyle(color: AppColors.muted, fontSize: 11),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < week.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: week[i].totalHours,
                    width: 14,
                    borderRadius: BorderRadius.circular(8),
                    color: i == week.length - 1
                      ? AppColors.mint
                      : AppColors.sky.withValues(alpha: 0.7),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
