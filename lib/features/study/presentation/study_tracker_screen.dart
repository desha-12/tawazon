import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/mint_button.dart';
import '../../../services/locale_controller.dart';
import '../../../services/ambient_audio_service.dart';
import '../../../services/prayer_service.dart';
import '../../focus_garden/domain/plant_phase.dart';
import '../../focus_garden/presentation/focus_controller.dart';
import 'study_mode_controller.dart';

class StudyTrackerScreen extends ConsumerWidget {
  const StudyTrackerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final stats = ref.watch(gardenStatsProvider);
    final prayer = ref.watch(prayerSnapshotProvider);
    final examShield = ref.watch(examShieldProvider);
    final ambientSound = ref.watch(ambientSoundProvider);
    final shouldRest = prayer.shouldTakePrayerBreak;
    final durationMinutes = shouldRest
        ? 10
        : prayer.suggestedFocusMinutes.clamp(10, examShield ? 50 : 25).toInt();

    return Scaffold(
      appBar: AppBar(title: Text(s.studyTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          GlassCard(
            child: SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: examShield,
              onChanged: ref.read(examShieldProvider.notifier).setEnabled,
              secondary:
                  const Icon(Icons.shield_outlined, color: AppColors.amber),
              title: Text(s.examShield,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(s.examShieldBody,
                  style: const TextStyle(color: AppColors.muted)),
            ),
          ),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.prayerSyncedPlan,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  shouldRest
                      ? s.prayerRestSuggestion
                      : s.prayerFocusSuggestion(durationMinutes),
                  style: const TextStyle(color: AppColors.muted, height: 1.45),
                ),
                const SizedBox(height: 16),
                MintButton(
                  label: shouldRest ? s.studyRest : s.studyFocus,
                  icon: shouldRest
                      ? Icons.self_improvement_outlined
                      : Icons.timer_outlined,
                  onPressed: () async {
                    await ref.read(focusControllerProvider.notifier).start(
                          duration: Duration(minutes: durationMinutes),
                          kind:
                              shouldRest ? SessionKind.rest : SessionKind.study,
                        );
                    if (context.mounted) {
                      context.go(AppRoutes.shell);
                      openGardenTab(ref);
                    }
                  },
                ),
                const SizedBox(height: 10),
                Text(
                  examShield ? s.examShieldBody : s.pomodoro,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GlassCard(
            child: Row(
              children: [
                const Icon(Icons.graphic_eq_rounded, color: AppColors.mint),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(s.ambientSound,
                        style: const TextStyle(fontWeight: FontWeight.w600))),
                DropdownButtonHideUnderline(
                  child: DropdownButton<AmbientSound>(
                    value: ambientSound,
                    onChanged: (sound) {
                      if (sound != null) {
                        ref.read(ambientSoundProvider.notifier).select(sound);
                      }
                    },
                    items: [
                      DropdownMenuItem(
                          value: AmbientSound.off, child: Text(s.soundOff)),
                      DropdownMenuItem(
                          value: AmbientSound.brownNoise,
                          child: Text(s.brownNoise)),
                      DropdownMenuItem(
                          value: AmbientSound.pinkNoise,
                          child: Text(s.pinkNoise)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GlassCard(
            child: Row(
              children: [
                const Icon(Icons.eco_outlined, color: AppColors.mint),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${stats.completedMinutes} ${s.minutes}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
