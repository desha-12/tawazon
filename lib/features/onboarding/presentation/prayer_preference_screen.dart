import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/mint_button.dart';
import '../../../services/locale_controller.dart';
import '../../../services/preferences_service.dart';

class PrayerPreferenceScreen extends ConsumerWidget {
  const PrayerPreferenceScreen({super.key});

  Future<void> _finish(WidgetRef ref, BuildContext context, {required bool enable}) async {
    final prefs = ref.read(preferencesServiceProvider);
    await prefs.setPrayerAlerts(enable);
    await prefs.setOnboardingDone(true);
    if (context.mounted) context.go(AppRoutes.shell);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.mosque_outlined, size: 56, color: AppColors.mint),
              const SizedBox(height: 22),
              Text(
                s.prayerPrefTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              GlassCard(
                child: Text(
                  s.prayerPrefBody,
                  style: const TextStyle(color: AppColors.muted, height: 1.45, fontSize: 15),
                ),
              ),
              const Spacer(),
              MintButton(
                label: s.enable,
                icon: Icons.notifications_active_outlined,
                onPressed: () => _finish(ref, context, enable: true),
              ),
              const SizedBox(height: 8),
              GhostButton(
                label: s.skip,
                onPressed: () => _finish(ref, context, enable: false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
