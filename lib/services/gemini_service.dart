import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import 'preferences_service.dart';

/// Model backing Tawazon's general-purpose AI assistant.
///
/// Flash keeps latency low for a chat surface. The gemini-1.5 family has been
/// retired by Google, so the default is a current Flash model; override it at
/// build time with `--dart-define=GEMINI_MODEL=...` (check AI Studio for names).
const String kGeminiModel = String.fromEnvironment(
  'GEMINI_MODEL',
  defaultValue: 'gemini-2.5-flash',
);

/// Build-time key: `flutter run --dart-define=GEMINI_API_KEY=xxxx`.
const String _kBuildTimeKey = String.fromEnvironment('GEMINI_API_KEY');

/// Demo fallback so a presentation never needs the settings screen.
/// Paste a restricted, throw-away key here for demos only. Anything compiled
/// into an APK can be extracted, so never ship a real key this way.
const String kDemoGeminiKey = '';

/// General-purpose assistant instruction handed to Gemini.
const String kTawazonSystemInstruction = '''
You are Tawazon AI, a capable, friendly, general-purpose assistant.
Help with any reasonable request, including explanations, writing and editing,
translation, brainstorming, studying, coding, planning, and digital wellbeing.
Do not restrict answers to wellbeing or to features inside the Tawazon app.

Answer the user's actual request first. Match their language and tone, including
Egyptian Arabic when they use it. Be concise by default, but provide detail,
examples, or step-by-step instructions when the user asks or the task needs it.
Ask a focused clarification only when essential information is missing.

Be honest about limits: do not claim to browse the web, see the user's device,
or perform actions outside this app. If current information is needed and no
source is provided, say so instead of inventing facts. Use app wellbeing context
only when it is available and directly relevant to the user's request.
Protect privacy, and do not provide instructions that facilitate harm. For
medical, legal, or financial topics, give general information and make clear
when a qualified professional is needed.
''';

/// Key the user pasted in Settings (empty when none). The service resolves the
/// effective key as: user key, then build-time key, then the demo fallback.
/// With none of them the coach falls back to the offline rule-based advisor.
final geminiApiKeyProvider =
    NotifierProvider<GeminiApiKeyController, String>(GeminiApiKeyController.new);

class GeminiApiKeyController extends Notifier<String> {
  @override
  String build() => ref.read(preferencesServiceProvider).geminiApiKey();

  Future<void> setKey(String value) async {
    final trimmed = value.trim();
    state = trimmed;
    await ref.read(preferencesServiceProvider).setGeminiApiKey(trimmed);
  }
}

final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService(ref.watch(geminiApiKeyProvider));
});

/// Thin wrapper around `google_generative_ai` that keeps one multi-turn
/// [ChatSession] alive so the coach remembers the whole conversation.
class GeminiService {
  GeminiService(String userKey) : apiKey = resolveKey(userKey);

  /// Effective key actually used for requests.
  final String apiKey;

  static String resolveKey(String userKey) {
    final user = userKey.trim();
    if (user.isNotEmpty) return user;
    if (_kBuildTimeKey.isNotEmpty) return _kBuildTimeKey;
    return kDemoGeminiKey;
  }

  GenerativeModel? _model;
  ChatSession? _session;
  List<Content> _seed = const [];

  bool get isConfigured => apiKey.trim().isNotEmpty;

  ChatSession _ensureSession() {
    final existing = _session;
    if (existing != null) return existing;
    final model = _model ??= GenerativeModel(
      model: kGeminiModel,
      apiKey: apiKey,
      systemInstruction: Content.system(kTawazonSystemInstruction),
      generationConfig: GenerationConfig(
        temperature: 0.7,
        // Leave room for detailed answers, code, and multi-step requests.
        maxOutputTokens: 4096,
      ),
    );
    return _session = model.startChat(history: _seed);
  }

  /// Streams the assistant reply chunk by chunk so the UI can render it live.
  Stream<String> streamReply(String prompt) async* {
    final session = _ensureSession();
    await for (final response in session
        .sendMessageStream(Content.text(prompt))
        .timeout(const Duration(seconds: 60))) {
      final chunk = response.text;
      if (chunk != null && chunk.isNotEmpty) yield chunk;
    }
  }

  /// Rebuilds the model context from the visible transcript.
  ///
  /// Gemini requires the history to start with a user turn, alternate roles and
  /// end with a model turn (the next message is the user's), so the transcript
  /// is sanitised: leading assistant turns dropped, same-role turns merged and
  /// an unanswered trailing user turn removed. Only the last 24 turns are kept.
  void restoreHistory(List<({bool fromUser, String text})> turns) {
    final recent = turns.length > 24 ? turns.sublist(turns.length - 24) : turns;
    final contents = <Content>[];
    String? lastRole;
    for (final turn in recent) {
      final text = turn.text.trim();
      if (text.isEmpty) continue;
      final role = turn.fromUser ? 'user' : 'model';
      if (contents.isEmpty && role == 'model') continue;
      if (role == lastRole) {
        final previous = (contents.last.parts.first as TextPart).text;
        contents[contents.length - 1] = Content(role, [TextPart('$previous\n$text')]);
      } else {
        contents.add(Content(role, [TextPart(text)]));
      }
      lastRole = role;
    }
    if (contents.isNotEmpty && contents.last.role == 'user') {
      contents.removeLast();
    }
    _seed = contents;
    _session = null;
  }

  /// Drops the conversation so the next message starts from a clean context.
  void resetConversation() {
    _seed = const [];
    _session = null;
  }
}
