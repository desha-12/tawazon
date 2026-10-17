import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/time_format.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../services/locale_controller.dart';
import '../../focus_garden/presentation/focus_controller.dart';
import 'usage_controller.dart';
import 'widgets/adaptive_timeline.dart';
import 'widgets/home_card_carousel.dart';
import 'widgets/home_wide_layout.dart';
import 'widgets/mood_analytics_chart.dart';
import 'widgets/usage_chart.dart';

/// Responsive home screen.
///
/// Below [kDesktopBreakpoint] the content stays in a single scrolling column;
/// at or above it the layout splits into the two-column [HomeWideLayout].
class AdaptiveHomeTimeline extends ConsumerStatefulWidget {
  const AdaptiveHomeTimeline({super.key, required this.isActive});

  final bool isActive;

  @override
  ConsumerState<AdaptiveHomeTimeline> createState() =>
      _AdaptiveHomeTimelineState();
}

class _AdaptiveHomeTimelineState extends ConsumerState<AdaptiveHomeTimeline> {
  final _scrollController = ScrollController();
  final _currentTimeAnchor = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.isActive) _scrollToCurrentTime();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AdaptiveHomeTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) _scrollToCurrentTime();
  }

  void _scrollToCurrentTime() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final anchor = _currentTimeAnchor.currentContext;
      if (!mounted || !widget.isActive || anchor == null) return;
      Scrollable.ensureVisible(
        anchor,
        alignment: 0.22,
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final padding = responsivePadding(width);
    final accent = Theme.of(context).colorScheme.primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 900),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).scaffoldBackgroundColor,
            Theme.of(context).scaffoldBackgroundColor,
            accent.withValues(alpha: 0.035),
          ],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
          child: width >= kDesktopBreakpoint
              ? HomeWideLayout(
                  isActive: widget.isActive,
                  horizontalPadding: padding,
                )
              : _NarrowLayout(
                  isActive: widget.isActive,
                  horizontalPadding: padding,
                  scrollController: _scrollController,
                  currentTimeAnchor: _currentTimeAnchor,
                ),
        ),
      ),
    );
  }
}

class _NarrowLayout extends ConsumerWidget {
  const _NarrowLayout({
    required this.isActive,
    required this.horizontalPadding,
    required this.scrollController,
    required this.currentTimeAnchor,
  });

  final bool isActive;
  final double horizontalPadding;
  final ScrollController scrollController;
  final GlobalKey currentTimeAnchor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final locale = ref.watch(localeControllerProvider);
    final usage = ref.watch(usageControllerProvider);
    final stats = ref.watch(gardenStatsProvider);
    final accent = Theme.of(context).colorScheme.primary;

    return ListView(
      controller: scrollController,
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        8,
        horizontalPadding,
        96,
      ),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.appName,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    strings.tagline,
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            _StreakPill(streak: stats.streak, label: strings.streak),
          ],
        ),
        const SizedBox(height: 18),
        GlassCard(
          frosted: true,
          child: AdaptiveTimeline(currentAnchorKey: currentTimeAnchor),
        ),
        const SizedBox(height: 14),
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
              const SizedBox(height: 8),
              if (usage.hasUsageAccess)
                UsageChart(week: usage.week, localeCode: locale.languageCode)
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
              const SizedBox(height: 8),
              MoodAnalyticsChart(localeCode: locale.languageCode),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          strings.todayUsage,
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
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
              ?.copyWith(color: accent, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _StreakPill extends StatelessWidget {
  const _StreakPill({required this.streak, required this.label});

  final int streak;
  final String label;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: accent.withValues(alpha: 0.34)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department_outlined, color: accent, size: 17),
          const SizedBox(width: 5),
          Text(
            '$streak · $label',
            style: TextStyle(color: accent, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
