import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../services/locale_controller.dart';
import '../../../focus_garden/domain/plant_phase.dart';
import '../../../focus_garden/presentation/focus_controller.dart';
import '../../../focus_garden/presentation/widgets/garden_3d_widget.dart';

/// Glassmorphic shell around the interactive 3D garden.
///
/// The card owns the blur, the rounded highlight border and the semi
/// transparent fill, while [Garden3DWidget] renders a transparent canvas on
/// top so the model appears to float inside the glass.
class GardenGlassCard extends ConsumerStatefulWidget {
  const GardenGlassCard({
    super.key,
    required this.isActive,
    this.height = 320,
  });

  final bool isActive;
  final double height;

  @override
  ConsumerState<GardenGlassCard> createState() => _GardenGlassCardState();
}

class _GardenGlassCardState extends ConsumerState<GardenGlassCard> {
  Timer? _celebrationTimer;
  bool _celebrating = false;

  @override
  void dispose() {
    _celebrationTimer?.cancel();
    super.dispose();
  }

  void _celebrate() {
    _celebrationTimer?.cancel();
    setState(() => _celebrating = true);
    _celebrationTimer = Timer(const Duration(milliseconds: 1700), () {
      if (mounted) setState(() => _celebrating = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    // Select only what the card renders so the per-second timer tick does not
    // rebuild the blur layer (growth is bucketed to 2% steps).
    final view = ref.watch(focusControllerProvider.select(
      (s) => (s.kind, s.phase, (s.growth * 50).round()),
    ));
    final kind = view.$1;
    final phase = view.$2;
    final stats = ref.watch(gardenStatsProvider);
    final accent = Theme.of(context).colorScheme.primary;
    final radius = BorderRadius.circular(24);

    ref.listen<FocusSessionState>(focusControllerProvider, (previous, next) {
      if (previous?.isRunning == true &&
          next.phase == PlantPhase.bloomed &&
          next.kind != SessionKind.rest) {
        _celebrate();
      }
    });

    final growth = kind == SessionKind.rest ? 0.0 : view.$3 / 50.0;

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.10),
                accent.withValues(alpha: 0.05),
                Colors.white.withValues(alpha: 0.03),
              ],
            ),
            border: Border.all(
              color: accent.withValues(alpha: 0.34),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.05 + growth * 0.12),
                blurRadius: 26 + growth * 16,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Garden3DWidget(
                    growth: growth,
                    phase: phase,
                    streak: stats.streak,
                    isActive: widget.isActive,
                    celebrate: _celebrating,
                    semanticLabel: strings.gardenSceneDescription,
                  ),
                ),
              ),
              PositionedDirectional(
                top: 12,
                start: 14,
                child: _GlassChip(
                  icon: Icons.local_fire_department_outlined,
                  label: '${stats.streak} · ${strings.streak}',
                  color: accent,
                ),
              ),
              PositionedDirectional(
                top: 12,
                end: 14,
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: _celebrating ? 1 : 0,
                    duration: const Duration(milliseconds: 260),
                    child: AnimatedScale(
                      scale: _celebrating ? 1 : 0.82,
                      duration: const Duration(milliseconds: 340),
                      curve: Curves.easeOutBack,
                      child: _GlassChip(
                        icon: Icons.auto_awesome,
                        label: strings.focusCompleted,
                        color: accent,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassChip extends StatelessWidget {
  const _GlassChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.navy.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.42)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
