import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../services/locale_controller.dart';
import 'coach_chat_view.dart';

/// Floating action button that opens the coach panel.
///
/// A slow, subtle glow pulse draws the eye without being distracting.
class CoachFab extends ConsumerStatefulWidget {
  const CoachFab({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  ConsumerState<CoachFab> createState() => _CoachFabState();
}

class _CoachFabState extends ConsumerState<CoachFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tooltip = ref.watch(stringsProvider).openCoach;
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_pulse.value);
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.mint.withValues(alpha: 0.22 + t * 0.30),
                blurRadius: 16 + t * 16,
                spreadRadius: 1 + t * 3,
              ),
            ],
          ),
          child: child,
        );
      },
      child: FloatingActionButton(
        onPressed: widget.onPressed,
        backgroundColor: AppColors.mint,
        foregroundColor: AppColors.navy,
        tooltip: tooltip,
        child: const Icon(Icons.auto_awesome),
      ),
    );
  }
}

/// Opens the coach as a right-hand glass panel on wide screens and as a
/// draggable bottom sheet on narrow ones.
Future<void> showCoachPanel(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width >= kDesktopBreakpoint) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'coach',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, _, __) => const _CoachSidePanel(),
      transitionBuilder: (context, animation, _, child) {
        final curved =
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.06, 0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _CoachBottomSheet(),
  );
}

class _CoachSidePanel extends StatelessWidget {
  const _CoachSidePanel();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final panelWidth = (width * 0.34).clamp(360.0, 460.0).toDouble();
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: panelWidth,
          child: const _GlassPanel(
            child: Column(
              children: [
                _PanelHeader(),
                Divider(height: 1, color: Color(0x22FFFFFF)),
                Expanded(child: CoachChatView()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CoachBottomSheet extends StatelessWidget {
  const _CoachBottomSheet();

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(
        // Give the chat nearly the full display height instead of the previous
        // 88%, while keeping a small glimpse of the screen behind it.
        top: height * 0.04,
        bottom: keyboardInset,
      ),
      child: SafeArea(
        top: false,
        child: _GlassPanel(
          radius: const BorderRadius.vertical(top: Radius.circular(26)),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: const BoxDecoration(
                  color: Color(0x8094A3B8),
                  borderRadius: BorderRadius.all(Radius.circular(99)),
                ),
              ),
              const _PanelHeader(),
              const Divider(height: 1, color: Color(0x22FFFFFF)),
              const Expanded(child: CoachChatView()),
            ],
          ),
        ),
      ),
    );
  }
}

class _PanelHeader extends ConsumerWidget {
  const _PanelHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 10, 12),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: AppColors.mint, size: 20),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              s.coachPanelTitle,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.close, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

/// Frosted container shared by the side panel and the bottom sheet.
class _GlassPanel extends StatelessWidget {
  const _GlassPanel({
    required this.child,
    this.radius = const BorderRadius.all(Radius.circular(24)),
  });

  final Widget child;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.navyElevated.withValues(alpha: 0.92),
                AppColors.navy.withValues(alpha: 0.88),
              ],
            ),
            border: Border.all(
              color: AppColors.mint.withValues(alpha: 0.28),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}