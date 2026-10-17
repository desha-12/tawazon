import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/preferences_service.dart';
import '../domain/plant_phase.dart';

final focusControllerProvider =
    NotifierProvider<FocusController, FocusSessionState>(FocusController.new);

/// How long the app may stay in the background before the plant withers.
/// A notification, a call or a quick app switch should not end the session.
const Duration _kBackgroundGrace = Duration(seconds: 30);

class FocusController extends Notifier<FocusSessionState>
    with WidgetsBindingObserver {
  Timer? _tick;
  DateTime? _backgroundedAt;

  @override
  FocusSessionState build() {
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() {
      _tick?.cancel();
      WidgetsBinding.instance.removeObserver(this);
    });

    final stored = ref.read(preferencesServiceProvider).lastPlantState();
    if (stored == 'withered') {
      return FocusSessionState.idle()
          .copyWith(phase: PlantPhase.withered, growth: 0.18);
    }
    if (stored == 'bloomed') {
      return FocusSessionState.idle()
          .copyWith(phase: PlantPhase.bloomed, growth: 1);
    }
    return FocusSessionState.idle();
  }

  Future<void> start({
    Duration duration = const Duration(minutes: 25),
    SessionKind kind = SessionKind.focus,
  }) async {
    _tick?.cancel();
    state = FocusSessionState(
      phase: PlantPhase.growing,
      kind: kind,
      target: duration,
      elapsed: Duration.zero,
      growth: kind == SessionKind.rest ? 0 : 0.08,
      startedAt: DateTime.now(),
    );
    if (kind != SessionKind.rest) {
      await ref.read(preferencesServiceProvider).setLastPlantState('growing');
    }
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  void _onTick() {
    if (!state.isRunning || state.startedAt == null) return;
    final elapsed = DateTime.now().difference(state.startedAt!);
    final progress =
        (elapsed.inMilliseconds / state.target.inMilliseconds).clamp(0.0, 1.0);
    if (progress >= 1) {
      unawaited(complete());
      return;
    }
    state = state.copyWith(
      elapsed: elapsed,
      growth: state.kind == SessionKind.rest
          ? state.growth
          : 0.08 + progress * 0.92,
    );
  }

  Future<void> complete() async {
    _tick?.cancel();
    if (state.kind == SessionKind.rest) {
      state = FocusSessionState.idle();
      return;
    }
    final minutes = state.target.inMinutes;
    state = state.copyWith(
      phase: PlantPhase.bloomed,
      elapsed: state.target,
      growth: 1,
    );
    final prefs = ref.read(preferencesServiceProvider);
    await prefs.setLastPlantState('bloomed');
    await prefs.setGardenStreak(prefs.gardenStreak() + 1);
    await prefs.addCompletedFocusMinutes(minutes);
    ref.invalidate(gardenStatsProvider);
  }

  Future<void> abort() async {
    if (!state.isRunning) return;
    _tick?.cancel();
    if (state.kind == SessionKind.rest) {
      state = FocusSessionState.idle();
      return;
    }
    state = state.copyWith(
        phase: PlantPhase.withered,
        growth: (state.growth * 0.4).clamp(0.08, 0.3));
    final prefs = ref.read(preferencesServiceProvider);
    await prefs.setLastPlantState('withered');
    await prefs.setGardenWithers(prefs.gardenWithers() + 1);
    await prefs.setGardenStreak(0);
    ref.invalidate(gardenStatsProvider);
  }

  Future<void> resetSoil() async {
    _tick?.cancel();
    state = FocusSessionState.idle();
    await ref.read(preferencesServiceProvider).setLastPlantState('idle');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!this.state.isRunning) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _backgroundedAt = DateTime.now();
    }
    if (state == AppLifecycleState.resumed && _backgroundedAt != null) {
      final away = DateTime.now().difference(_backgroundedAt!);
      _backgroundedAt = null;
      if (away > _kBackgroundGrace) {
        unawaited(abort());
      }
    }
  }
}

class GardenStats {
  const GardenStats({
    required this.streak,
    required this.withers,
    required this.completedMinutes,
  });

  final int streak;
  final int withers;
  final int completedMinutes;
}

final gardenStatsProvider = Provider<GardenStats>((ref) {
  final prefs = ref.watch(preferencesServiceProvider);
  return GardenStats(
    streak: prefs.gardenStreak(),
    withers: prefs.gardenWithers(),
    completedMinutes: prefs.completedFocusMinutes(),
  );
});
