import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'preferences_service.dart';

enum DarkAppearance { soft, trueBlack }

enum CircadianPhase { dawn, day, sunset, night }

class AppearanceState {
  const AppearanceState({required this.now, required this.mode});

  final DateTime now;
  final DarkAppearance mode;

  CircadianPhase get period {
    final hour = now.hour;
    if (hour >= 5 && hour < 10) return CircadianPhase.dawn;
    if (hour >= 10 && hour < 17) return CircadianPhase.day;
    if (hour >= 17 && hour < 20) return CircadianPhase.sunset;
    return CircadianPhase.night;
  }

  AppearanceState copyWith({DateTime? now, DarkAppearance? mode}) =>
      AppearanceState(now: now ?? this.now, mode: mode ?? this.mode);
}

final appearanceControllerProvider =
    NotifierProvider<AppearanceController, AppearanceState>(
  AppearanceController.new,
);

final currentTimeProvider = Provider<DateTime>((ref) {
  return ref.watch(appearanceControllerProvider.select((state) => state.now));
});

final dayPeriodProvider = Provider<CircadianPhase>((ref) {
  return ref.watch(appearanceControllerProvider.select((state) => state.period));
});

class AppearanceController extends Notifier<AppearanceState> {
  Timer? _minuteTimer;

  @override
  AppearanceState build() {
    ref.onDispose(() => _minuteTimer?.cancel());
    final savedMode = ref.read(preferencesServiceProvider).darkAppearance();
    final mode = DarkAppearance.values.firstWhere(
      (value) => value.name == savedMode,
      orElse: () => DarkAppearance.soft,
    );
    _minuteTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      state = state.copyWith(now: DateTime.now());
    });
    return AppearanceState(now: DateTime.now(), mode: mode);
  }

  Future<void> setMode(DarkAppearance mode) async {
    if (state.mode == mode) return;
    state = state.copyWith(mode: mode);
    await ref.read(preferencesServiceProvider).setDarkAppearance(mode.name);
  }
}