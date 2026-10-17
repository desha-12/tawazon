import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/time_format.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../services/locale_controller.dart';
import '../../../focus_garden/presentation/focus_controller.dart';
import 'home_card_carousel.dart';
import 'mood_analytics_chart.dart';
import 'next_prayer_card.dart';
import 'usage_chart.dart';
import '../usage_controller.dart';

/// Home screen for wide viewports.
///
/// Left column carries the day rhythm and the weekly analytics; the right
/// column holds the next-prayer card (the 3D garden lives in the Garden tab). Both
/// columns scroll together inside one [SingleChildScrollView] so the page
/// never clips at the edges.
class HomeWideLayout extends ConsumerWidget {
  const HomeWideLayout({
    super.key,
    required this.isActive,
    required this.horizontalPadding,
  });

  final bool isActive;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final locale = ref.watch(localeControllerProvider);
    final usage = ref.watch(usageControllerProvider);
    final stats = ref.watch(gardenStatsProvider);
    final accent = Theme.of(context).colorScheme.primary;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        12,
        horizontalPadding,
        96,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(
            title: strings.appName,
            subtitle: strings.tagline,
            accent: accent,
            streak: stats.streak,
            streakLabel: strings.streak,
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const HomeCardCarousel(),
                    const SizedBox(height: 18),
                    GlassCard(
                      frosted: true,
                      accentBorder: true,
                      accentColor: accent,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.weeklyTrend,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 10),
                          if (usage.hasUsageAccess)
                            UsageChart(
                              week: usage.week,
                              localeCode: locale.languageCode,
                            )
                          else
                            Text(
                              strings.usageAccessRequiredForAnalytics,
                              style: const TextStyle(color: AppColors.muted),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    GlassCard(
                      frosted: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.moodAnalyticsTitle,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 10),
                          MoodAnalyticsChart(localeCode: locale.languageCode),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    GlassCard(
                      frosted: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.todayUsage,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            usage.hasUsageAccess
                                ? formatHours(
                                    usage.today.totalHours,
                                    localeCode: locale.languageCode,
                                  )
                                : strings.usageDataUnavailable,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: accent,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: const [
                    NextPrayerCard(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.streak,
    required this.streakLabel,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final int streak;
  final String streakLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: accent.withValues(alpha: 0.34)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.local_fire_department_outlined,
                color: accent,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                '$streak · $streakLabel',
                style: TextStyle(color: accent, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
