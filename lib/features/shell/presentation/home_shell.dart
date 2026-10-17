import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../services/locale_controller.dart';
import '../../../services/prayer_service.dart';
import '../../ai_coach/presentation/ai_coach_screen.dart';
import '../../ai_coach/presentation/widgets/coach_panel.dart';
import '../../dashboard/presentation/adaptive_home_timeline.dart';
import '../../focus_garden/domain/plant_phase.dart';
import '../../focus_garden/presentation/focus_controller.dart';
import '../../focus_garden/presentation/focus_garden_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../study/presentation/study_mode_controller.dart';

final shellTabProvider =
    NotifierProvider<ShellTabController, int>(ShellTabController.new);

class ShellTabController extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) => state = index;
}

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  bool _quietShown = false;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final tab = ref.watch(shellTabProvider);
    final prayer = ref.watch(prayerSnapshotProvider);
    // Select only what the shell needs so the per-second timer tick does not
    // rebuild every tab.
    final studyRunning = ref.watch(focusControllerProvider
        .select((f) => f.isRunning && f.kind == SessionKind.study));
    final shieldActive = ref.watch(examShieldProvider) && studyRunning;
    final wide = MediaQuery.sizeOf(context).width >= kDesktopBreakpoint;

    // Re-arm the prayer snackbar once the quiet window has passed.
    if (!(prayer.alertsEnabled && prayer.inQuietWindow)) _quietShown = false;
    if (prayer.alertsEnabled && prayer.inQuietWindow && !_quietShown) {
      _quietShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              s.isArabic
                  ? 'دخل وقت الصلاة. أبقِ الجلسة أو أغلق الشاشة لدقيقة.'
                  : 'Prayer window. Hold the sitting, or fold the screen for a minute.',
            ),
          ),
        );
      });
    }

    final pages = [
      AdaptiveHomeTimeline(isActive: tab == 0),
      FocusGardenScreen(isActive: tab == 1),
      const AiCoachScreen(),
      const SettingsScreen(),
    ];

    final destinations = [
      NavigationDestination(
        icon: const Icon(Icons.home_outlined),
        selectedIcon: const Icon(Icons.home, color: AppColors.mint),
        label: s.navHome,
      ),
      NavigationDestination(
        icon: const Icon(Icons.local_florist_outlined),
        selectedIcon: const Icon(Icons.local_florist, color: AppColors.mint),
        label: s.navGarden,
      ),
      NavigationDestination(
        icon: const Icon(Icons.chat_bubble_outline),
        selectedIcon: const Icon(Icons.chat_bubble, color: AppColors.mint),
        label: s.navCoach,
      ),
      NavigationDestination(
        icon: const Icon(Icons.settings_outlined),
        selectedIcon: const Icon(Icons.settings, color: AppColors.mint),
        label: s.navSettings,
      ),
    ];

    // On wide screens the rail replaces the bottom bar so the content keeps
    // its full height; the coach FAB stays available in both layouts.
    final body = wide
        ? Row(
            children: [
              NavigationRail(
                selectedIndex: tab,
                onDestinationSelected: (i) =>
                    ref.read(shellTabProvider.notifier).select(i),
                labelType: NavigationRailLabelType.all,
                backgroundColor: Theme.of(context).colorScheme.surface,
                indicatorColor: AppColors.mintDim,
                destinations: [
                  for (final d in destinations)
                    NavigationRailDestination(
                      icon: d.icon,
                      selectedIcon: d.selectedIcon,
                      label: Text(d.label),
                    ),
                ],
              ),
              const VerticalDivider(width: 1, color: Color(0x22FFFFFF)),
              Expanded(child: IndexedStack(index: tab, children: pages)),
            ],
          )
        : IndexedStack(index: tab, children: pages);

    return PopScope(
      // Back from any other tab returns to Home instead of closing the app.
      canPop: tab == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) ref.read(shellTabProvider.notifier).select(0);
      },
      child: Scaffold(
      body: SafeArea(child: body),
      floatingActionButton: tab == 2
          ? null
          : CoachFab(onPressed: () => showCoachPanel(context)),
      bottomNavigationBar: wide || shieldActive
          ? null
          : NavigationBar(
              selectedIndex: tab,
              onDestinationSelected: (i) =>
                  ref.read(shellTabProvider.notifier).select(i),
              destinations: destinations,
            ),
      ),
    );
  }
}
