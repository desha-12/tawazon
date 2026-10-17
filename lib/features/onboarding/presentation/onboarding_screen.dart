import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/mint_button.dart';
import '../../../services/locale_controller.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _page = PageController();
  int _index = 0;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final locale = ref.watch(localeControllerProvider);
    final pages = [
      _Slide(
        icon: Icons.nightlight_round,
        title: s.onboardingDetoxTitle,
        body: s.onboardingDetoxBody,
      ),
      _Slide(
        icon: Icons.local_florist_outlined,
        title: s.onboardingGardenTitle,
        body: s.onboardingGardenBody,
      ),
      _Slide(
        icon: Icons.psychology_alt_outlined,
        title: s.onboardingCoachTitle,
        body: s.onboardingCoachBody,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 18),
          child: Column(
            children: [
              Row(
                children: [
                  _LangChip(
                    selected: locale.languageCode == 'en',
                    label: s.english,
                    onTap: () => ref.read(localeControllerProvider.notifier).setLocale(const Locale('en')),
                  ),
                  const SizedBox(width: 8),
                  _LangChip(
                    selected: locale.languageCode == 'ar',
                    label: s.arabic,
                    onTap: () => ref.read(localeControllerProvider.notifier).setLocale(const Locale('ar')),
                  ),
                  const Spacer(),
                  GhostButton(
                    label: s.skip,
                    onPressed: () => context.go(AppRoutes.prayerPref),
                  ),
                ],
              ),
              Expanded(
                child: PageView(
                  controller: _page,
                  onPageChanged: (i) => setState(() => _index = i),
                  children: pages,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  pages.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: _index == i ? 22 : 8,
                    decoration: BoxDecoration(
                      color: _index == i ? AppColors.mint : AppColors.muted.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              MintButton(
                label: _index == pages.length - 1 ? s.start : s.next,
                onPressed: () {
                  if (_index == pages.length - 1) {
                    context.go(AppRoutes.prayerPref);
                    return;
                  }
                  _page.nextPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 330;
        final veryCompact = constraints.maxHeight < 230;
        final iconSize = veryCompact ? 32.0 : compact ? 44.0 : 64.0;
        final iconPadding = veryCompact ? 10.0 : compact ? 16.0 : 28.0;
        return Column(
          mainAxisAlignment:
              compact ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            if (!compact) const Spacer(),
            Container(
              padding: EdgeInsets.all(iconPadding),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.mintDim,
                border: Border.all(color: AppColors.mint.withValues(alpha: 0.4)),
              ),
              child: Icon(icon, size: iconSize, color: AppColors.mint),
            ),
            SizedBox(height: compact ? 10 : 28),
            Text(
              title,
              textAlign: TextAlign.center,
              style: (compact
                      ? Theme.of(context).textTheme.titleLarge
                      : Theme.of(context).textTheme.headlineSmall)
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: compact ? 6 : 12),
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.muted,
                height: compact ? 1.3 : 1.5,
                fontSize: veryCompact ? 12 : compact ? 14 : 16,
              ),
            ),
            if (!compact) const Spacer(flex: 2),
          ],
        );
      },
    );
  }
}

class _LangChip extends StatelessWidget {
  const _LangChip({required this.selected, required this.label, required this.onTap});

  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.mint,
      labelStyle: TextStyle(
        color: selected ? AppColors.navy : AppColors.frost,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: AppColors.navyCard,
    );
  }
}
