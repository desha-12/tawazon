import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../services/detox_advisor.dart';
import '../../../services/gemini_service.dart';
import '../../../services/locale_controller.dart';
import '../../../services/preferences_service.dart';
import '../../dashboard/presentation/usage_controller.dart';
import '../../sleep/presentation/sleep_controller.dart';
import '../domain/coach_message.dart';

const _uuid = Uuid();
const _advisor = DetoxAdvisor();

/// True while the coach is waiting on a reply, so the UI can show a typing
/// indicator and disable the send button.
final coachBusyProvider =
    NotifierProvider<CoachBusyController, bool>(CoachBusyController.new);

class CoachBusyController extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

/// True when the last reply came from the offline advisor even though a key is
/// configured (network or API failure), so the UI can say so instead of
/// silently pretending the AI answered.
final coachFallbackProvider =
    NotifierProvider<CoachFallbackFlag, bool>(CoachFallbackFlag.new);

class CoachFallbackFlag extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final coachControllerProvider =
    NotifierProvider<CoachController, List<CoachMessage>>(CoachController.new);

class CoachController extends Notifier<List<CoachMessage>> {
  bool _isResponding = false;

  @override
  List<CoachMessage> build() {
    final stored = ref.read(preferencesServiceProvider).chatHistory();
    if (stored.isEmpty) {
      final arabic = ref.read(localeControllerProvider).languageCode == 'ar';
      return [
        CoachMessage(
          id: _uuid.v4(),
          role: CoachRole.assistant,
          body: arabic
              ? 'أنا مساعد توازن الذكي. اسألني عن أي موضوع، مثل الشرح أو الكتابة أو الترجمة أو التخطيط.'
              : 'I am Tawazon AI. Ask me about anything, including explanations, writing, translation, or planning.',
          at: DateTime.now(),
        ),
      ];
    }
    return stored.map(CoachMessage.fromJson).toList();
  }

  Future<void> send(String raw) async {
    final text = raw.trim();
    if (text.isEmpty || _isResponding) return;
    _isResponding = true;
    ref.read(coachBusyProvider.notifier).set(true);
    final user = CoachMessage(
      id: _uuid.v4(),
      role: CoachRole.user,
      body: text,
      at: DateTime.now(),
    );
    try {
      state = [...state, user];
      await _persist();
      await _answer(text);
    } finally {
      _isResponding = false;
      ref.read(coachBusyProvider.notifier).set(false);
    }
  }

  Future<void> recordMood(Mood mood) async {
    final preferences = ref.read(preferencesServiceProvider);
    final recordedAt = DateTime.now();
    await preferences.setLastMood(mood.name);
    await preferences.addMoodLog(mood.name, recordedAt);
    ref.invalidate(moodLogsProvider);
    final arabic = ref.read(localeControllerProvider).languageCode == 'ar';
    final label = switch (mood) {
      Mood.calm => arabic ? 'هادئ' : 'calm',
      Mood.restless => arabic ? 'قلق' : 'restless',
      Mood.tired => arabic ? 'مرهق' : 'tired',
      Mood.scattered => arabic ? 'مشتت' : 'scattered',
    };
    await send(arabic ? 'مزاجي الآن: $label' : 'Mood right now: $label');
  }

  Future<void> askRoutine() {
    final arabic = ref.read(localeControllerProvider).languageCode == 'ar';
    return send(arabic
        ? 'أعطني روتين إزالة السموم لليوم'
        : 'Give me today\'s detox routine');
  }

  Future<void> askOffline() {
    final arabic = ref.read(localeControllerProvider).languageCode == 'ar';
    return send(
        arabic ? 'اقترح نشاطاً بلا شاشة' : 'Suggest an offline activity');
  }

  /// Clears the transcript and drops the Gemini conversation context.
  Future<void> clear() async {
    ref.read(geminiServiceProvider).resetConversation();
    ref.read(coachFallbackProvider.notifier).set(false);
    state = build();
    await _persist();
  }

  Future<void> _answer(String prompt) async {
    final gemini = ref.read(geminiServiceProvider);
    if (gemini.isConfigured) {
      final streamed = await _streamGemini(gemini, prompt);
      ref.read(coachFallbackProvider.notifier).set(!streamed);
      if (streamed) return;
    }
    await _offlineAnswer(prompt);
  }

  /// Streams the Gemini reply into a placeholder bubble so text appears live.
  /// Returns false when the request failed, letting the caller fall back.
  Future<bool> _streamGemini(GeminiService gemini, String prompt) async {
    final placeholder = CoachMessage(
      id: _uuid.v4(),
      role: CoachRole.assistant,
      body: '',
      at: DateTime.now(),
    );
    state = [...state, placeholder];
    // Rebuild the Gemini context from the visible transcript (everything before
    // the new prompt and the placeholder) so both always agree, including after
    // an app restart or an offline reply.
    final earlier = state.length >= 2
        ? state.sublist(0, state.length - 2)
        : <CoachMessage>[];
    gemini.restoreHistory([
      for (final m in earlier)
        if (m.role != CoachRole.system)
          (fromUser: m.role == CoachRole.user, text: m.body),
    ]);
    final buffer = StringBuffer();
    try {
      await for (final chunk in gemini.streamReply(prompt)) {
        buffer.write(chunk);
        state = [
          for (final message in state)
            message.id == placeholder.id
                ? message.copyWith(body: buffer.toString())
                : message,
        ];
      }
    } catch (error) {
      debugPrint('Gemini request failed: $error');
      // Drop the empty placeholder so the fallback reply is not duplicated.
      state = state.where((message) => message.id != placeholder.id).toList();
      return false;
    }
    if (buffer.isEmpty) {
      state = state.where((message) => message.id != placeholder.id).toList();
      return false;
    }
    await _persist();
    return true;
  }

  Future<void> _offlineAnswer(String prompt) async {
    final arabic = ref.read(localeControllerProvider).languageCode == 'ar';
    final usage = ref.read(usageControllerProvider);
    final today = usage.today;
    final sleep = ref.read(sleepLogsProvider.notifier).latestHours;
    final prayer = ref.read(preferencesServiceProvider).prayerAlertsEnabled();
    final moodName = ref.read(preferencesServiceProvider).lastMood();
    final mood = Mood.values.where((m) => m.name == moodName).firstOrNull;
    final body = _advisor.reply(
      prompt: prompt,
      arabic: arabic,
      today: today,
      hasUsageData: usage.hasUsageAccess,
      lastSleepHours: sleep,
      prayerAlerts: prayer,
      mood: mood,
    );
    state = [
      ...state,
      CoachMessage(
        id: _uuid.v4(),
        role: CoachRole.assistant,
        body: body,
        at: DateTime.now(),
      ),
    ];
    await _persist();
  }

  Future<void> _persist() {
    final clipped =
        state.length > 80 ? state.sublist(state.length - 80) : state;
    return ref
        .read(preferencesServiceProvider)
        .writeChatHistory(clipped.map((e) => e.toJson()).toList());
  }
}
