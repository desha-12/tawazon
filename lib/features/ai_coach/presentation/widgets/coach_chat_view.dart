import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../services/gemini_service.dart';
import '../../../../services/locale_controller.dart';
import '../../domain/coach_message.dart';
import '../coach_controller.dart';

/// Shared chat surface used by both the Coach tab and the floating panel.
///
/// Renders dynamic user/assistant bubbles, a live typing indicator while a
/// reply streams in, and the composer row.
class CoachChatView extends ConsumerStatefulWidget {
  const CoachChatView({super.key, this.showQuickActions = true});

  final bool showQuickActions;

  @override
  ConsumerState<CoachChatView> createState() => _CoachChatViewState();
}

class _CoachChatViewState extends ConsumerState<CoachChatView> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _input.text;
    if (text.trim().isEmpty) return;
    // Keep the typed text while a reply is still streaming; sending would be
    // ignored by the controller and the message would silently vanish.
    if (ref.read(coachBusyProvider)) return;
    _input.clear();
    await ref.read(coachControllerProvider.notifier).send(text);
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final end = _scroll.position.maxScrollExtent;
      if (ref.read(coachBusyProvider)) {
        // Jump while streaming so chunked updates do not stack animations.
        _scroll.jumpTo(end);
      } else {
        _scroll.animateTo(
          end,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final messages = ref.watch(coachControllerProvider);
    final busy = ref.watch(coachBusyProvider);
    final configured = ref.watch(geminiServiceProvider).isConfigured;
    final fallback = ref.watch(coachFallbackProvider);

    ref.listen<List<CoachMessage>>(coachControllerProvider, (_, __) {
      _scrollToEnd();
    });

    return Column(
      children: [
        if (widget.showQuickActions)
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _Quick(label: s.moodCheck, onTap: _moodSheet),
                _Quick(
                  label: s.dailyRoutine,
                  onTap: () =>
                      ref.read(coachControllerProvider.notifier).askRoutine(),
                ),
                _Quick(
                  label: s.offlineIdeas,
                  onTap: () =>
                      ref.read(coachControllerProvider.notifier).askOffline(),
                ),
                _Quick(label: s.coachClear, onTap: _confirmClear),
              ],
            ),
          ),
        if (!configured || fallback)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 15, color: AppColors.amber),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    configured
                        ? (s.isArabic
                            ? 'تعذّر الاتصال بـ Gemini، هذا رد أوفلاين.'
                            : 'Could not reach Gemini; this is an offline reply.')
                        : s.coachOfflineNotice,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11.5,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            itemCount: messages.length + (busy ? 1 : 0),
            itemBuilder: (context, i) {
              if (i >= messages.length) return const _TypingBubble();
              final m = messages[i];
              final mine = m.role == CoachRole.user;
              // The streaming placeholder stays hidden until it has content.
              if (!mine && m.body.isEmpty) return const _TypingBubble();
              return _Bubble(message: m, mine: mine);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  decoration: InputDecoration(
                    hintText: s.coachHint,
                    filled: true,
                    fillColor: AppColors.navyCard,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: busy ? null : _submit,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.mint,
                  foregroundColor: AppColors.navy,
                  disabledBackgroundColor:
                      AppColors.mint.withValues(alpha: 0.3),
                ),
                icon: const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmClear() async {
    final arabic = ref.read(stringsProvider).isArabic;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(arabic ? 'مسح المحادثة؟' : 'Clear conversation?'),
        content: Text(
          arabic ? 'سيتم حذف كل الرسائل.' : 'All messages will be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(arabic ? 'إلغاء' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(arabic ? 'مسح' : 'Clear'),
          ),
        ],
      ),
    );
    if (ok == true) await ref.read(coachControllerProvider.notifier).clear();
  }

  Future<void> _moodSheet() async {
    final s = ref.read(stringsProvider);
    final mood = await showModalBottomSheet<Mood>(
      context: context,
      backgroundColor: AppColors.navyElevated,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(s.moodCheck, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              for (final entry in {
                Mood.calm: s.moodCalm,
                Mood.restless: s.moodRestless,
                Mood.tired: s.moodTired,
                Mood.scattered: s.moodScattered,
              }.entries)
                ListTile(
                  title: Text(entry.value),
                  onTap: () => Navigator.pop(context, entry.key),
                ),
            ],
          ),
        );
      },
    );
    if (mood != null) {
      await ref.read(coachControllerProvider.notifier).recordMood(mood);
    }
  }
}

final _arabicChars = RegExp(r'[\u0600-\u06FF]');

/// Picks the paragraph direction from the content so Arabic replies read
/// right-to-left even when the app language is English (and vice versa).
TextDirection _direction(String text) =>
    _arabicChars.hasMatch(text) ? TextDirection.rtl : TextDirection.ltr;

/// Gemini answers in Markdown; strip the markers so bubbles read cleanly.
String _plain(String text) {
  return text
      .replaceAll(RegExp(r'\*\*|__|`'), '')
      .replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), '')
      .replaceAll(RegExp(r'^\s*[*-]\s+', multiLine: true), '• ')
      .trim();
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.mine});

  final CoachMessage message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: mine
                ? AppColors.mint.withValues(alpha: 0.18)
                : AppColors.navyCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: mine
                  ? AppColors.mint.withValues(alpha: 0.4)
                  : const Color(0x22FFFFFF),
            ),
          ),
          child: Text(
            mine ? message.body : _plain(message.body),
            textDirection: _direction(message.body),
            style: const TextStyle(height: 1.45),
          ),
        ),
      ),
    );
  }
}

/// Three-dot pulse shown while the assistant is composing a reply.
class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.navyCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x22FFFFFF)),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 3; i++)
                  Padding(
                    padding: EdgeInsetsDirectional.only(end: i == 2 ? 0 : 5),
                    child: Opacity(
                      opacity: 0.35 +
                          0.65 *
                              (0.5 +
                                  0.5 *
                                      math.sin(
                                        _controller.value * 2 * math.pi - i * 0.7,
                                      )),
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.mint,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Quick extends StatelessWidget {
  const _Quick({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: ActionChip(
        label: Text(label),
        onPressed: onTap,
        backgroundColor: AppColors.navyCard,
        side: const BorderSide(color: AppColors.mint),
      ),
    );
  }
}
