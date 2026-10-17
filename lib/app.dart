import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'services/appearance_controller.dart';
import 'services/locale_controller.dart';

class TawazonApp extends ConsumerWidget {
  const TawazonApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeControllerProvider);
    final router = ref.watch(appRouterProvider);
    final period = ref.watch(dayPeriodProvider);
    final mode = ref.watch(
      appearanceControllerProvider.select((state) => state.mode),
    );

    return MaterialApp.router(
      title: 'Tawazon',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(period: period, mode: mode),
      themeAnimationDuration: const Duration(milliseconds: 900),
      themeAnimationCurve: Curves.easeInOutCubic,
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
