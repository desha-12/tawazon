import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/credit_footer.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../services/locale_controller.dart';
import '../../../services/appearance_controller.dart';
import '../../../services/prayer_service.dart';
import '../../../services/preferences_service.dart';
import 'widgets/gemini_key_card.dart';
import 'widgets/usage_alert_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final locale = ref.watch(localeControllerProvider);
    final prefs = ref.watch(preferencesServiceProvider);
    final prayerOn = ref.watch(prayerAlertsProvider);
    final darkAppearance = ref.watch(
      appearanceControllerProvider.select((state) => state.mode),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
      children: [
        Text(s.settingsTitle, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.language, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(value: 'en', label: Text(s.english)),
                  ButtonSegment(value: 'ar', label: Text(s.arabic)),
                ],
                selected: {locale.languageCode},
                onSelectionChanged: (v) {
                  ref.read(localeControllerProvider.notifier).setLocale(Locale(v.first));
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.appearanceMode,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              SegmentedButton<DarkAppearance>(
                segments: [
                  ButtonSegment(
                    value: DarkAppearance.soft,
                    label: Text(s.softDark),
                    icon: const Icon(Icons.nightlight_outlined),
                  ),
                  ButtonSegment(
                    value: DarkAppearance.trueBlack,
                    label: Text(s.trueBlack),
                    icon: const Icon(Icons.brightness_2_outlined),
                  ),
                ],
                selected: {darkAppearance},
                onSelectionChanged: (selection) => ref
                    .read(appearanceControllerProvider.notifier)
                    .setMode(selection.first),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const GeminiKeyCard(),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(s.prayerAlerts),
          value: prayerOn,
          activeThumbColor: AppColors.mint,
          onChanged: (v) async {
            await ref.read(prayerAlertsProvider.notifier).setEnabled(v);
          },
        ),
        const UsageAlertCard(),
        const SizedBox(height: 12),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.bedtime_outlined, color: AppColors.sky),
          title: Text(s.sleepTitle),
          onTap: () => context.push(AppRoutes.sleep),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.menu_book_outlined, color: AppColors.amber),
          title: Text(s.studyTitle),
          onTap: () => context.push(AppRoutes.study),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.mosque_outlined, color: AppColors.mint),
          title: Text(s.prayerTitle),
          onTap: () => context.push(AppRoutes.prayer),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.info_outline, color: AppColors.mint),
          title: Text(s.about),
          onTap: () => context.push(AppRoutes.about),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.replay, color: AppColors.muted),
          title: Text(s.resetOnboarding),
          onTap: () async {
            await prefs.setOnboardingDone(false);
            if (context.mounted) context.go(AppRoutes.onboarding);
          },
        ),
        const SizedBox(height: 28),
        const CreditFooter(compact: true),
      ],
    );
  }
}
