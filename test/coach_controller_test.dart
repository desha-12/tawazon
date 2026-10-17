import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tawazon/features/ai_coach/domain/coach_message.dart';
import 'package:tawazon/features/ai_coach/presentation/coach_controller.dart';
import 'package:tawazon/services/gemini_service.dart';
import 'package:tawazon/services/preferences_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('overlapping coach sends append only one exchange', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        // Never hit the network from tests, whatever keys the build defines.
        geminiServiceProvider.overrideWithValue(_OfflineGemini()),
      ],
    );
    addTearDown(container.dispose);

    final coach = container.read(coachControllerProvider.notifier);
    await Future.wait(
        [coach.send('Help me focus'), coach.send('Help me focus')]);

    final messages = container.read(coachControllerProvider);
    expect(messages.where((message) => message.role == CoachRole.user),
        hasLength(1));
    expect(messages.where((message) => message.role == CoachRole.assistant),
        hasLength(2));
  });
}

class _OfflineGemini extends GeminiService {
  _OfflineGemini() : super('');

  @override
  bool get isConfigured => false;
}
