import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../services/locale_controller.dart';
import '../../../services/location_service.dart';
import '../../../services/prayer_service.dart';

class PrayerTimesScreen extends ConsumerStatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  ConsumerState<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends ConsumerState<PrayerTimesScreen> {
  bool _requestingLocation = false;

  Future<void> _useCurrentLocation() async {
    if (_requestingLocation) return;
    setState(() => _requestingLocation = true);
    final updated = await ref
        .read(prayerLocationProvider.notifier)
        .useDeviceLocation();
    if (!mounted) return;
    setState(() => _requestingLocation = false);
    final strings = ref.read(stringsProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          updated ? strings.prayerLocationUpdated : strings.prayerLocationFailed,
        ),
        action: updated
            ? null
            : SnackBarAction(
                label: strings.openAppSettings,
                onPressed: () {
                  ref.read(locationServiceProvider).openAppSettings();
                },
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final snapshot = ref.watch(prayerSnapshotProvider);
    final locale = ref.watch(localeControllerProvider);
    final times = snapshot.times;

    final rows = <(Prayer, DateTime)>[
      (Prayer.fajr, times.fajr),
      (Prayer.sunrise, times.sunrise),
      (Prayer.dhuhr, times.dhuhr),
      (Prayer.asr, times.asr),
      (Prayer.maghrib, times.maghrib),
      (Prayer.isha, times.isha),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(s.prayerTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, color: AppColors.mint),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        s.prayerLocationTitle,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.usingDeviceLocation
                      ? s.prayerLocationUsingDevice
                      : s.prayerLocationUsingDefault,
                  style: const TextStyle(color: AppColors.muted, height: 1.4),
                ),
                const SizedBox(height: 6),
                Text(
                  s.prayerLocationPrivacy,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton.icon(
                    onPressed:
                        _requestingLocation ? null : _useCurrentLocation,
                    icon: _requestingLocation
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location),
                    label: Text(
                      _requestingLocation
                          ? (s.isArabic ? 'جارٍ تحديد الموقع…' : 'Getting location…')
                          : s.prayerLocationUseDevice,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(s.prayerAlerts),
            value: snapshot.alertsEnabled,
            activeThumbColor: AppColors.mint,
            onChanged: (value) => ref
                .read(prayerAlertsProvider.notifier)
                .setEnabled(value),
          ),
          GlassCard(
            accentBorder: snapshot.inQuietWindow,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.nextPrayer, style: const TextStyle(color: AppColors.muted)),
                const SizedBox(height: 6),
                Text(
                  _name(s, snapshot.next),
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(color: AppColors.mint),
                ),
                const SizedBox(height: 4),
                Text(
                  formatPrayerClock(snapshot.nextAt, locale.languageCode),
                  style: const TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.prayerScheduleTitle,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                ...rows.map((row) {
                  final selected = row.$1 == snapshot.next;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_name(s, row.$1)),
                    trailing: Text(
                      formatPrayerClock(row.$2, locale.languageCode),
                      style: TextStyle(
                        color: selected ? AppColors.mint : AppColors.frost,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _name(AppStrings s, Prayer prayer) {
    return switch (prayer) {
      Prayer.fajr => s.fajr,
      Prayer.sunrise => s.sunrise,
      Prayer.dhuhr => s.dhuhr,
      Prayer.asr => s.asr,
      Prayer.maghrib => s.maghrib,
      Prayer.isha => s.isha,
      _ => s.nextPrayer,
    };
  }
}
