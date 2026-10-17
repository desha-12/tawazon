import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/time_format.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/mint_button.dart';
import '../../../services/locale_controller.dart';
import '../../dashboard/presentation/widgets/garden_glass_card.dart';
import '../domain/plant_phase.dart';
import 'focus_controller.dart';

class FocusGardenScreen extends ConsumerStatefulWidget {
  const FocusGardenScreen({super.key, required this.isActive});

  final bool isActive;

  @override
  ConsumerState<FocusGardenScreen> createState() => _FocusGardenScreenState();
}

class _FocusGardenScreenState extends ConsumerState<FocusGardenScreen> {
  // The 3D engine is created the first time the tab is shown, not at app
  // start, and then kept alive (paused while hidden).
  late bool _visited = widget.isActive;

  @override
  void didUpdateWidget(covariant FocusGardenScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive) _visited = true;
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final session = ref.watch(focusControllerProvider);
    final stats = ref.watch(gardenStatsProvider);
    final caption = session.isRunning && session.kind == SessionKind.rest
        ? s.gardenResting
        : switch (session.phase) {
            PlantPhase.idle => s.gardenIdle,
            PlantPhase.growing => s.gardenGrowing,
            PlantPhase.bloomed => s.gardenBloom,
            PlantPhase.withered => s.gardenWithered,
          };

    return ListView(
      // Bottom padding keeps the last cards clear of the coach FAB.
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
      children: [
        Text(s.gardenTitle,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(caption,
            style: const TextStyle(color: AppColors.muted, height: 1.4)),
        const SizedBox(height: 8),
        // Interactive 3D garden inside the glass card: centered, capped in
        // width, and sized from the viewport so it never clips or overflows.
        LayoutBuilder(
          builder: (context, constraints) {
            final viewportHeight = MediaQuery.sizeOf(context).height;
            final cardHeight = math
                .min(constraints.maxWidth, viewportHeight * 0.5)
                .clamp(260.0, 520.0)
                .toDouble();
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: _visited
                    ? GardenGlassCard(
                        isActive: widget.isActive,
                        height: cardHeight,
                      )
                    : SizedBox(height: cardHeight),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        GlassCard(
          child: Column(
            children: [
              Text(
                session.isRunning
                    ? clock(session.remaining)
                    : clock(session.target),
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                session.kind == SessionKind.rest
                    ? s.gardenResting
                    : session.kind == SessionKind.study
                        ? s.studyTitle
                        : s.startFocus,
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 16),
              if (!session.isRunning)
                Row(
                  children: [
                    Expanded(
                      child: MintButton(
                        label: '25 ${s.minutes}',
                        onPressed: () =>
                            ref.read(focusControllerProvider.notifier).start(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: MintButton(
                        label: '45 ${s.minutes}',
                        onPressed: () =>
                            ref.read(focusControllerProvider.notifier).start(
                                  duration: const Duration(minutes: 45),
                                ),
                      ),
                    ),
                  ],
                )
              else
                OutlinedButton(
                  onPressed: () =>
                      ref.read(focusControllerProvider.notifier).abort(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text(s.endEarly),
                ),
              if (session.phase == PlantPhase.withered ||
                  session.phase == PlantPhase.bloomed) ...[
                if (session.phase == PlantPhase.bloomed &&
                    session.kind == SessionKind.study) ...[
                  const SizedBox(height: 8),
                  MintButton(
                    label: s.studyBreakTen,
                    icon: Icons.self_improvement_outlined,
                    onPressed: () =>
                        ref.read(focusControllerProvider.notifier).start(
                              duration: const Duration(minutes: 10),
                              kind: SessionKind.rest,
                            ),
                  ),
                ],
                const SizedBox(height: 8),
                GhostButton(
                  label: s.gardenIdle,
                  onPressed: () =>
                      ref.read(focusControllerProvider.notifier).resetSoil(),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _Stat(label: s.streak, value: '${stats.streak}')),
            const SizedBox(width: 10),
            Expanded(child: _Stat(label: s.withers, value: '${stats.withers}')),
          ],
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        children: [
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(color: AppColors.mint)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppColors.muted)),
        ],
      ),
    );
  }
}
