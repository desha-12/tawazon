import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/locale_controller.dart';
import 'widgets/coach_chat_view.dart';

/// Coach tab. The chat surface itself lives in [CoachChatView] so the tab and
/// the floating panel stay in sync through the same Riverpod providers.
class AiCoachScreen extends ConsumerWidget {
  const AiCoachScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              s.coachTitle,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const Expanded(child: CoachChatView()),
      ],
    );
  }
}
