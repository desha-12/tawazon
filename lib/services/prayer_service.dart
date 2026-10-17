import 'package:adhan/adhan.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'appearance_controller.dart';
import 'location_service.dart';
import 'preferences_service.dart';

final prayerAlertsProvider =
    NotifierProvider<PrayerAlertsController, bool>(PrayerAlertsController.new);

class PrayerAlertsController extends Notifier<bool> {
  @override
  bool build() => ref.read(preferencesServiceProvider).prayerAlertsEnabled();

  Future<void> setEnabled(bool value) async {
    state = value;
    await ref.read(preferencesServiceProvider).setPrayerAlerts(value);
  }
}

/// Damanhour, Egypt — default coordinates for this build.
const _damanhourLatitude = 31.0341;
const _damanhourLongitude = 30.4681;

class PrayerLocation {
  const PrayerLocation({
    required this.latitude,
    required this.longitude,
    required this.fromDevice,
  });

  final double latitude;
  final double longitude;
  final bool fromDevice;
}

final prayerLocationProvider =
    NotifierProvider<PrayerLocationController, PrayerLocation>(
  PrayerLocationController.new,
);

class PrayerLocationController extends Notifier<PrayerLocation> {
  @override
  PrayerLocation build() {
    final preferences = ref.read(preferencesServiceProvider);
    final saved = preferences.prayerCoordinates();
    if (saved == null) {
      return const PrayerLocation(
        latitude: _damanhourLatitude,
        longitude: _damanhourLongitude,
        fromDevice: false,
      );
    }
    return PrayerLocation(
      latitude: saved.latitude,
      longitude: saved.longitude,
      fromDevice: preferences.prayerLocationIsDevice(),
    );
  }

  Future<bool> useDeviceLocation() async {
    final coordinates =
        await ref.read(locationServiceProvider).requestCurrentLocation();
    if (coordinates == null) return false;
    state = PrayerLocation(
      latitude: coordinates.latitude,
      longitude: coordinates.longitude,
      fromDevice: true,
    );
    await ref.read(preferencesServiceProvider).setPrayerCoordinates(
          latitude: coordinates.latitude,
          longitude: coordinates.longitude,
          fromDevice: true,
        );
    return true;
  }
}

class PrayerSnapshot {
  PrayerSnapshot({
    required this.times,
    required this.next,
    required this.nextAt,
    required this.nextIn,
    required this.alertsEnabled,
    required this.usingDeviceLocation,
  });

  final PrayerTimes times;
  final Prayer next;
  final DateTime nextAt;
  final Duration nextIn;
  final bool alertsEnabled;
  final bool usingDeviceLocation;

  bool get inQuietWindow {
    final now = DateTime.now();
    for (final at in [
      times.fajr,
      times.dhuhr,
      times.asr,
      times.maghrib,
      times.isha
    ]) {
      if (now.isAfter(at.subtract(const Duration(minutes: 5))) &&
          now.isBefore(at.add(const Duration(minutes: 12)))) {
        return true;
      }
    }
    return false;
  }

  bool get shouldTakePrayerBreak =>
      inQuietWindow || nextIn <= const Duration(minutes: 15);

  int get suggestedFocusMinutes {
    if (shouldTakePrayerBreak) return 10;
    return (nextIn.inMinutes - 5).clamp(10, 50).toInt();
  }
}

final prayerSnapshotProvider = Provider<PrayerSnapshot>((ref) {
  final now = ref.watch(currentTimeProvider);
  final location = ref.watch(prayerLocationProvider);
  final params = CalculationMethod.egyptian.getParameters()
    ..madhab = Madhab.shafi;
  final times = PrayerTimes(
    Coordinates(location.latitude, location.longitude),
    DateComponents(now.year, now.month, now.day),
    params,
  );
  final nextRaw = times.nextPrayer();
  final Prayer next;
  final DateTime when;
  if (nextRaw == Prayer.none) {
    next = Prayer.fajr;
    when = times.fajr.add(const Duration(days: 1));
  } else {
    next = nextRaw;
    when = times.timeForPrayer(nextRaw)!;
  }
  final alerts = ref.watch(prayerAlertsProvider);
  return PrayerSnapshot(
    times: times,
    next: next,
    nextAt: when,
    nextIn: when.difference(now),
    alertsEnabled: alerts,
    usingDeviceLocation: location.fromDevice,
  );
});

String formatPrayerClock(DateTime time, String localeCode) {
  // toLocal() is a no-op for local values and fixes UTC ones.
  return DateFormat.jm(localeCode).format(time.toLocal());
}
