import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/mint_button.dart';
import '../../../../services/locale_controller.dart';
import '../../../../services/prayer_service.dart';
import '../../../focus_garden/presentation/focus_controller.dart';

/// Glassmorphic "next prayer" panel used by the wide home layout.
class NextPrayerCard extends ConsumerWidget {
  const NextPrayerCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final locale = ref.watch(localeControllerProvider);
    final prayer = ref.watch(prayerSnapshotProvider);
    final running =
        ref.watch(focusControllerProvider.select((s) => s.isRunning));
    final accent = AppColors.mintSoft;

    return GlassCard(
      frosted: true,
      accentBorder: true,
      accentColor: accent,
      onTap: () => context.push(AppRoutes.prayer),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.mosque_outlined, size: 19, color: accent),
              const SizedBox(width: 8),
              Text(
                strings.prayerCardTitle,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
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
            formatPrayerClock(prayer.nextAt, locale.languageCode),
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          Text(
            prayer.shouldTakePrayerBreak
                ? strings.prayerRestSuggestion
                : strings.prayerFocusSuggestion(prayer.suggestedFocusMinutes),
            style: const TextStyle(fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 14),
          MintButton(
            label: running ? strings.focusInProgress : strings.startFocus,
            icon: running
                ? Icons.spa_outlined
                : Icons.play_arrow_rounded,
            onPressed: running
                ? null
                : () => ref.read(focusControllerProvider.notifier).start(
                      duration: Duration(
                        minutes: prayer.suggestedFocusMinutes,
                      ),
                    ),
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
