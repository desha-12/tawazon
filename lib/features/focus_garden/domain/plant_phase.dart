enum PlantPhase { idle, growing, bloomed, withered }

enum SessionKind { focus, study, rest }

class FocusSessionState {
  const FocusSessionState({
    required this.phase,
    required this.kind,
    required this.target,
    required this.elapsed,
    required this.growth,
    this.startedAt,
  });

  final PlantPhase phase;
  final SessionKind kind;
  final Duration target;
  final Duration elapsed;
  final double growth;
  final DateTime? startedAt;

  bool get isRunning => phase == PlantPhase.growing;

  Duration get remaining {
    final left = target - elapsed;
    return left.isNegative ? Duration.zero : left;
  }

  FocusSessionState copyWith({
    PlantPhase? phase,
    SessionKind? kind,
    Duration? target,
    Duration? elapsed,
    double? growth,
    DateTime? startedAt,
    bool clearStart = false,
  }) {
    return FocusSessionState(
      phase: phase ?? this.phase,
      kind: kind ?? this.kind,
      target: target ?? this.target,
      elapsed: elapsed ?? this.elapsed,
      growth: growth ?? this.growth,
      startedAt: clearStart ? null : (startedAt ?? this.startedAt),
    );
  }

  static FocusSessionState idle() => const FocusSessionState(
        phase: PlantPhase.idle,
        kind: SessionKind.focus,
        target: Duration(minutes: 25),
        elapsed: Duration.zero,
        growth: 0,
      );
}
