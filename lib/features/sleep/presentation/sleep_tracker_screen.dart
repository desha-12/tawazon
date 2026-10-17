import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/time_format.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/mint_button.dart';
import '../../../services/locale_controller.dart';
import 'sleep_controller.dart';

class SleepTrackerScreen extends ConsumerStatefulWidget {
  const SleepTrackerScreen({super.key});

  @override
  ConsumerState<SleepTrackerScreen> createState() => _SleepTrackerScreenState();
}

class _SleepTrackerScreenState extends ConsumerState<SleepTrackerScreen> {
  double _hours = 7;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final logs = ref.watch(sleepLogsProvider);
    final corr = ref.watch(sleepCorrelationProvider);
    final locale = ref.watch(localeControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(s.sleepTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Text(s.sleepHint, style: const TextStyle(color: AppColors.muted, height: 1.4)),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              children: [
                Text('${_hours.toStringAsFixed(1)} ${s.sleepHours}'),
                Slider(
                  value: _hours,
                  min: 3,
                  max: 11,
                  divisions: 16,
                  activeColor: AppColors.mint,
                  onChanged: (v) => setState(() => _hours = v),
                ),
                MintButton(
                  label: s.logSleep,
                  onPressed: () => ref.read(sleepLogsProvider.notifier).add(_hours),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.correlation, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(corr.message, style: const TextStyle(height: 1.45, color: AppColors.muted)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ...logs.reversed.map(
            (log) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.bedtime_outlined, color: AppColors.sky),
              title: Text(DateFormat.MMMEd(locale.languageCode).format(log.nightOf)),
              trailing: Text(
                formatHours(log.hours, localeCode: locale.languageCode),
                style: const TextStyle(color: AppColors.mint),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
