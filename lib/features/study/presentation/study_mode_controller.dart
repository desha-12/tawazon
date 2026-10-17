import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/preferences_service.dart';

final examShieldProvider =
    NotifierProvider<ExamShieldController, bool>(ExamShieldController.new);

class ExamShieldController extends Notifier<bool> {
  @override
  bool build() => ref.read(preferencesServiceProvider).examShieldEnabled();

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    await ref.read(preferencesServiceProvider).setExamShieldEnabled(enabled);
  }
}
