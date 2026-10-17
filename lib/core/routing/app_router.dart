import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/onboarding/presentation/prayer_preference_screen.dart';
import '../../features/prayer/presentation/prayer_times_screen.dart';
import '../../features/settings/presentation/about_screen.dart';
import '../../features/shell/presentation/home_shell.dart';
import '../../features/sleep/presentation/sleep_tracker_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/study/presentation/study_tracker_screen.dart';
import 'app_routes.dart';

CustomTransitionPage<void> _fadeGlidePage(
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curve,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.018),
            end: Offset.zero,
          ).animate(curve),
          child: child,
        ),
      );
    },
  );
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (context, state) =>
            _fadeGlidePage(state, const SplashScreen()),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        pageBuilder: (context, state) =>
            _fadeGlidePage(state, const OnboardingScreen()),
      ),
      GoRoute(
        path: AppRoutes.prayerPref,
        pageBuilder: (context, state) =>
            _fadeGlidePage(state, const PrayerPreferenceScreen()),
      ),
      GoRoute(
        path: AppRoutes.shell,
        pageBuilder: (context, state) => _fadeGlidePage(state, const HomeShell()),
        routes: [
          GoRoute(
            path: 'sleep',
            pageBuilder: (context, state) =>
                _fadeGlidePage(state, const SleepTrackerScreen()),
          ),
          GoRoute(
            path: 'study',
            pageBuilder: (context, state) =>
                _fadeGlidePage(state, const StudyTrackerScreen()),
          ),
          GoRoute(
            path: 'prayer',
            pageBuilder: (context, state) =>
                _fadeGlidePage(state, const PrayerTimesScreen()),
          ),
          GoRoute(
            path: 'about',
            pageBuilder: (context, state) =>
                _fadeGlidePage(state, const AboutScreen()),
          ),
        ],
      ),
    ],
  );
});

void openGardenTab(WidgetRef ref) {
  ref.read(shellTabProvider.notifier).select(1);
}

void openCoachTab(WidgetRef ref) {
  ref.read(shellTabProvider.notifier).select(2);
}
