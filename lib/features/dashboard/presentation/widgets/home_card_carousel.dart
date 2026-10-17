import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/time_format.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/mint_button.dart';
import '../../../../services/locale_controller.dart';
import '../../../../services/prayer_service.dart';
import '../../../../services/preferences_service.dart';
import '../../../ai_coach/domain/coach_message.dart';
import '../../../focus_garden/domain/plant_phase.dart';
import '../../../focus_garden/presentation/focus_controller.dart';
import '../usage_controller.dart';

class HomeCardCarousel extends ConsumerStatefulWidget {
  const HomeCardCarousel({super.key});

  @override
  ConsumerState<HomeCardCarousel> createState() => _HomeCardCarouselState();
}

class _HomeCardCarouselState extends ConsumerState<HomeCardCarousel> {
  late final PageController _pageController;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final locale = ref.watch(localeControllerProvider);
    // Keep the prayer card below the focus and mood cards instead of letting
    // it become the first card on the home screen near prayer time.
    const cards = [
      _HomeCardKind.focus,
      _HomeCardKind.mood,
      _HomeCardKind.prayer,
    ];

    return Column(
      children: [
        SizedBox(
          // Grows with the user's text scale so large fonts do not overflow.
          height:
              224 * MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.6).toDouble(),
          child: PageView.builder(
            controller: _pageController,
            itemCount: cards.length,
            onPageChanged: (index) => setState(() => _page = index),
            itemBuilder: (context, index) {
              final kind = cards[index];
              return Padding(
                padding: const EdgeInsetsDirectional.only(end: 10),
                child: switch (kind) {
                  _HomeCardKind.focus => _FocusCard(strings: strings),
                  _HomeCardKind.prayer => _PrayerCard(
                      strings: strings,
                      localeCode: locale.languageCode,
                    ),
                  _HomeCardKind.mood => _MoodCard(strings: strings),
                },
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var index = 0; index < cards.length; index++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: _page == index ? 18 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: _page == index
                      ? Theme.of(context).colorScheme.primary
                      : AppColors.muted.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

enum _HomeCardKind { focus, prayer, mood }

class _FocusCard extends ConsumerWidget {
  const _FocusCard({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(focusControllerProvider);
    final usageSnapshot = ref.watch(usageControllerProvider);
    final usage = usageSnapshot.today;
    final stats = ref.watch(gardenStatsProvider);
    final accent = Theme.of(context).colorScheme.primary;

    return GlassCard(
      frosted: true,
      accentBorder: true,
      accentColor: accent,
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeading(
            icon: Icons.center_focus_strong_outlined,
            color: accent,
            title: strings.focusCardTitle,
          ),
          const SizedBox(height: 12),
          Text(
            session.isRunning
                ? clock(session.remaining)
                : usageSnapshot.hasUsageAccess
                    ? formatHours(
                        usage.totalHours,
                        localeCode: locale.languageCode,
                      )
                    : strings.usageDataUnavailable,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                ),
          ),
          Text(
            session.isRunning
                ? strings.focusInProgress
                : '${strings.todayUsage} · ${stats.completedMinutes} ${strings.minutes}',
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: MintButton(
              label: session.isRunning ? strings.focusInProgress : strings.startFocus,
              icon: session.isRunning ? Icons.spa_outlined : Icons.play_arrow_rounded,
              onPressed: session.isRunning
                  ? () => openGardenTab(ref)
                  : () => ref.read(focusControllerProvider.notifier).start(
                        duration: const Duration(minutes: 25),
                        kind: SessionKind.focus,
                      ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrayerCard extends ConsumerWidget {
  const _PrayerCard({required this.strings, required this.localeCode});

  final AppStrings strings;
  final String localeCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prayer = ref.watch(prayerSnapshotProvider);
    final accent = AppColors.mintSoft;
    return GlassCard(
      frosted: true,
      accentBorder: true,
      accentColor: accent,
      padding: const EdgeInsets.all(17),
      onTap: () => context.push(AppRoutes.prayer),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeading(
            icon: Icons.mosque_outlined,
            color: accent,
            title: strings.prayerCardTitle,
          ),
          const SizedBox(height: 12),
          Text(
            _prayerName(strings, prayer.next),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 3),
          Text(
            formatPrayerClock(prayer.nextAt, localeCode),
            style: const TextStyle(color: AppColors.muted),
          ),
          const Spacer(),
          Text(
            prayer.shouldTakePrayerBreak
                ? strings.prayerRestSuggestion
                : strings.prayerFocusSuggestion(prayer.suggestedFocusMinutes),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

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

class _MoodCard extends ConsumerWidget {
  const _MoodCard({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(moodLogsProvider);
    final accent = AppColors.sky;
    Mood? mood;
    if (logs.isNotEmpty) {
      final name = logs.last['mood'] as String?;
      mood = Mood.values.where((value) => value.name == name).firstOrNull;
    }

    return GlassCard(
      frosted: true,
      accentBorder: true,
      accentColor: accent,
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeading(
            icon: Icons.favorite_outline,
            color: accent,
            title: strings.moodCardTitle,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 420),
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                ),
                child: _MoodAvatar(key: ValueKey(mood), mood: mood, color: accent),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  mood == null ? strings.moodAnalyticsEmpty : _moodName(strings, mood),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => openCoachTab(ref),
              icon: const Icon(Icons.mood_outlined),
              label: Text(strings.moodCheck),
              style: OutlinedButton.styleFrom(
                foregroundColor: accent,
                side: BorderSide(color: accent.withValues(alpha: 0.55)),
                minimumSize: const Size.fromHeight(46),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _moodName(AppStrings strings, Mood mood) => switch (mood) {
        Mood.calm => strings.moodCalm,
        Mood.restless => strings.moodRestless,
        Mood.tired => strings.moodTired,
        Mood.scattered => strings.moodScattered,
      };
}

class _MoodAvatar extends StatelessWidget {
  const _MoodAvatar({super.key, required this.mood, required this.color});

  final Mood? mood;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final icon = switch (mood) {
      Mood.calm => Icons.sentiment_satisfied_alt_rounded,
      Mood.restless => Icons.sentiment_dissatisfied_rounded,
      Mood.tired => Icons.bedtime_outlined,
      Mood.scattered => Icons.blur_on_rounded,
      null => Icons.spa_outlined,
    };
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.48)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.22), blurRadius: 18),
        ],
      ),
      child: Icon(icon, color: color, size: 29),
    );
  }
}

class _CardHeading extends StatelessWidget {
  const _CardHeading({required this.icon, required this.color, required this.title});

  final IconData icon;
  final Color color;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 19, color: color),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
