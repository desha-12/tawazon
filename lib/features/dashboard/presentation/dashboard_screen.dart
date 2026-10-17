import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/time_format.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/mint_button.dart';
import '../../../services/locale_controller.dart';
import '../../../services/prayer_service.dart';
import '../../ai_coach/domain/coach_message.dart';
import '../../ai_coach/presentation/coach_controller.dart';
import '../../focus_garden/presentation/focus_controller.dart';
import 'usage_controller.dart';
import 'widgets/mood_analytics_chart.dart';
import 'widgets/usage_chart.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final usage = ref.watch(usageControllerProvider);
    final locale = ref.watch(localeControllerProvider);
    final prayer = ref.watch(prayerSnapshotProvider);
    final session = ref.watch(focusControllerProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Text(s.appName,
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        Text(s.tagline,
            style: const TextStyle(
                color: AppColors.mint, fontWeight: FontWeight.w600)),
        const SizedBox(height: 18),
        GlassCard(
          accentBorder: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.todayUsage,
                  style: const TextStyle(color: AppColors.muted)),
              const SizedBox(height: 6),
              Text(
                usage.hasUsageAccess
                    ? formatHours(
                        usage.today.totalHours,
                        localeCode: locale.languageCode,
                      )
                    : s.usageDataUnavailable,
                style: Theme.of(context)
                    .textTheme
                    .displaySmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              MintButton(
                label: s.startFocus,
                icon: Icons.eco_outlined,
                onPressed: session.isRunning
                    ? () => openGardenTab(ref)
                    : () async {
                        await ref
                            .read(focusControllerProvider.notifier)
                            .start();
                        if (context.mounted) openGardenTab(ref);
                      },
              ),
            ],
          ),
        ),
        if (usage.highUsage) ...[
          const SizedBox(height: 14),
          GlassCard(
            accentBorder: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.highUsageBanner,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MoodChip(label: s.moodCalm, mood: Mood.calm),
                    _MoodChip(label: s.moodRestless, mood: Mood.restless),
                    _MoodChip(label: s.moodTired, mood: Mood.tired),
                    _MoodChip(label: s.moodScattered, mood: Mood.scattered),
                  ],
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 14),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.weeklyTrend,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              if (usage.hasUsageAccess)
                UsageChart(week: usage.week, localeCode: locale.languageCode)
              else
                Text(
                  s.usageAccessRequiredForAnalytics,
                  style: const TextStyle(color: AppColors.muted),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.moodAnalyticsTitle,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              MoodAnalyticsChart(localeCode: locale.languageCode),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.byCategory,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Text(
                usage.hasUsageAccess
                    ? s.usageCategoryBreakdownUnavailable
                    : s.usageAccessRequiredForAnalytics,
                style: const TextStyle(color: AppColors.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: GlassCard(
                onTap: () => context.push(AppRoutes.sleep),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.bedtime_outlined, color: AppColors.sky),
                    const SizedBox(height: 10),
                    Text(s.sleepCard,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GlassCard(
                onTap: () => context.push(AppRoutes.study),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.menu_book_outlined,
                        color: AppColors.amber),
                    const SizedBox(height: 10),
                    Text(s.studyCard,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (prayer.alertsEnabled) ...[
          const SizedBox(height: 12),
          GlassCard(
            onTap: () => context.push(AppRoutes.prayer),
            child: Row(
              children: [
                const Icon(Icons.mosque_outlined, color: AppColors.mint),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    prayer.inQuietWindow
                        ? (locale.languageCode == 'ar'
                            ? 'نافذة هدوء حول الصلاة — أبقِ الشاشة مطوية'
                            : 'Quiet window around prayer — keep the screen folded')
                        : s.prayerTitle,
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.muted),
              ],
            ),
          ),
        ],
      ],
    );
  }

}

class _MoodChip extends ConsumerWidget {
  const _MoodChip({required this.label, required this.mood});

  final String label;
  final Mood mood;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ActionChip(
      label: Text(label),
      onPressed: () async {
        await ref.read(coachControllerProvider.notifier).recordMood(mood);
        if (context.mounted) openCoachTab(ref);
      },
      backgroundColor: AppColors.navyElevated,
      side: const BorderSide(color: AppColors.mint),
    );
  }
}
