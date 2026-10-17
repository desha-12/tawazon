import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/credit_footer.dart';
import '../../../services/locale_controller.dart';
import '../../../services/preferences_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _brandVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _go());
  }

  Future<void> _go() async {
    if (mounted) setState(() => _brandVisible = true);
    await Future<void>.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;
    final done = ref.read(preferencesServiceProvider).onboardingDone();
    context.go(done ? AppRoutes.shell : AppRoutes.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.navy, Color(0xFF080C11)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),
              AnimatedOpacity(
                opacity: _brandVisible ? 1 : 0,
                duration: reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 1050),
                curve: Curves.easeOutCubic,
                child: AnimatedScale(
                  scale: _brandVisible ? 1 : 0.94,
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 1250),
                  curve: Curves.easeOutCubic,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(AppAssets.logo,
                          height: 168, filterQuality: FilterQuality.high),
                      const SizedBox(height: 22),
                      Text(
                        s.appName,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        s.tagline,
                        style: const TextStyle(
                            color: AppColors.mint, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              const CreditFooter(),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}
