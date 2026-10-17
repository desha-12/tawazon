import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/appearance_controller.dart';
import '../../../../services/locale_controller.dart';
import '../../../../services/prayer_service.dart';

class AdaptiveTimeline extends ConsumerWidget {
  const AdaptiveTimeline({super.key, required this.currentAnchorKey});

  final GlobalKey currentAnchorKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final now = ref.watch(currentTimeProvider);
    final phase = ref.watch(dayPeriodProvider);
    final prayer = ref.watch(prayerSnapshotProvider);
    final locale = ref.watch(localeControllerProvider);
    final accent = Theme.of(context).colorScheme.primary;

    final evening = DateTime(now.year, now.month, now.day, 20, 30);
    final eveningEntry = evening.isAfter(now)
        ? evening
        : evening.add(const Duration(days: 1));
    final entries = <_TimelineEntry>[
      _TimelineEntry(
        at: now,
        title: _phaseTitle(strings, phase),
        detail: _phaseDetail(strings, phase),
        icon: _phaseIcon(phase),
        color: accent,
        current: true,
      ),
      _TimelineEntry(
        at: prayer.nextAt,
        title: '${strings.nextPrayer} · ${_prayerName(strings, prayer.next)}',
        detail: prayer.shouldTakePrayerBreak
            ? strings.restWindow
            : strings.focusWindow,
        icon: Icons.mosque_outlined,
        color: AppColors.mintSoft,
      ),
      _TimelineEntry(
        at: eveningEntry,
        title: strings.timelineEvening,
        detail: strings.moodCheck,
        icon: Icons.nightlight_outlined,
        color: AppColors.amber,
      ),
    ]..sort((a, b) => a.at.compareTo(b.at));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                strings.biologicalTimeline,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              DateFormat.jm(locale.languageCode).format(now),
              style: TextStyle(color: accent, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (var index = 0; index < entries.length; index++)
          _TimelineRow(
            key: entries[index].current ? currentAnchorKey : null,
            entry: entries[index],
            isLast: index == entries.length - 1,
            timeLabel:
                DateFormat.jm(locale.languageCode).format(entries[index].at.toLocal()),
            nowLabel: strings.nowLabel,
          ),
      ],
    );
  }

  String _phaseTitle(AppStrings strings, CircadianPhase phase) => switch (phase) {
        CircadianPhase.dawn => strings.phaseDawn,
        CircadianPhase.day => strings.phaseDay,
        CircadianPhase.sunset => strings.phaseSunset,
        CircadianPhase.night => strings.phaseNight,
      };

  String _phaseDetail(AppStrings strings, CircadianPhase phase) => switch (phase) {
        CircadianPhase.dawn => strings.timelineMorning,
        CircadianPhase.day => strings.timelineDay,
        CircadianPhase.sunset || CircadianPhase.night => strings.timelineEvening,
      };

  IconData _phaseIcon(CircadianPhase phase) => switch (phase) {
        CircadianPhase.dawn => Icons.wb_twilight,
        CircadianPhase.day => Icons.wb_sunny_outlined,
        CircadianPhase.sunset => Icons.wb_twilight_outlined,
        CircadianPhase.night => Icons.nightlight_outlined,
      };

  String _prayerName(AppStrings strings, Prayer prayer) => switch (prayer) {
        Prayer.fajr => strings.fajr,
        Prayer.sunrise => strings.sunrise,
        Prayer.dhuhr => strings.dhuhr,
        Prayer.asr => strings.asr,
        Prayer.maghrib => strings.maghrib,
        Prayer.isha => strings.isha,
        Prayer.none => strings.nextPrayer,
      };
}

class _TimelineEntry {
  const _TimelineEntry({
    required this.at,
    required this.title,
    required this.detail,
    required this.icon,
    required this.color,
    this.current = false,
  });

  final DateTime at;
  final String title;
  final String detail;
  final IconData icon;
  final Color color;
  final bool current;
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    super.key,
    required this.entry,
    required this.isLast,
    required this.timeLabel,
    required this.nowLabel,
  });

  final _TimelineEntry entry;
  final bool isLast;
  final String timeLabel;
  final String nowLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: isLast ? 58 : 68,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: entry.current ? 13 : 9,
                  height: entry.current ? 13 : 9,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: entry.current ? entry.color : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(color: entry.color, width: 1.5),
                    boxShadow: entry.current
                        ? [
                            BoxShadow(
                              color: entry.color.withValues(alpha: 0.45),
                              blurRadius: 10,
                            ),
                          ]
                        : null,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: entry.color.withValues(alpha: 0.28),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(entry.icon, size: 18, color: entry.color),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                entry.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: entry.current
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              entry.current
                                  ? '$nowLabel · $timeLabel'
                                  : timeLabel,
                              style: TextStyle(
                                color: entry.color,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          entry.detail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
