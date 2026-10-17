import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../services/gemini_service.dart';
import '../../../../services/locale_controller.dart';

/// Lets the user paste a Gemini API key so the coach switches from the offline
/// rule-based advisor to live multi-turn chat.
class GeminiKeyCard extends ConsumerStatefulWidget {
  const GeminiKeyCard({super.key});

  @override
  ConsumerState<GeminiKeyCard> createState() => _GeminiKeyCardState();
}

class _GeminiKeyCardState extends ConsumerState<GeminiKeyCard> {
  late final TextEditingController _controller;
  bool _obscured = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(geminiApiKeyProvider));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await ref.read(geminiApiKeyProvider.notifier).setKey(_controller.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ref.read(stringsProvider).geminiApiKeySaved)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final configured = ref.watch(geminiServiceProvider).isConfigured;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                configured ? Icons.check_circle_outline : Icons.key_outlined,
                size: 19,
                color: configured ? AppColors.mint : AppColors.amber,
              ),
              const SizedBox(width: 8),
              Text(
                s.geminiApiKey,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            s.geminiApiKeyBody,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 11.5,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            obscureText: _obscured,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              hintText: s.geminiApiKeyHint,
              filled: true,
              fillColor: AppColors.navyCard,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscured = !_obscured),
                icon: Icon(
                  _obscured
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.muted,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: FilledButton.icon(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.mint,
                foregroundColor: AppColors.navy,
              ),
              icon: const Icon(Icons.save_outlined, size: 18),
              label: Text(s.save),
            ),
          ),
        ],
      ),
    );
  }
}
