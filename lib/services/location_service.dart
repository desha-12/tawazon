import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _locationChannel = MethodChannel('com.example.tawazon/usage_alerts');

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

class DeviceCoordinates {
  const DeviceCoordinates({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

/// Requests a foreground location only after an explicit user action.
class LocationService {
  Future<DeviceCoordinates?> requestCurrentLocation() async {
    try {
      final values = await _locationChannel.invokeMapMethod<String, dynamic>(
        'getCurrentLocation',
      );
      final latitude = values?['latitude'];
      final longitude = values?['longitude'];
      if (latitude is! num || longitude is! num) return null;
      return DeviceCoordinates(
        latitude: latitude.toDouble(),
        longitude: longitude.toDouble(),
      );
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  Future<void> openAppSettings() async {
    try {
      await _locationChannel.invokeMethod<bool>('openLocationAppSettings');
    } on MissingPluginException {
      // This settings shortcut is Android-only.
    } on PlatformException {
      // The user can still open app permissions from Android Settings.
    }
  }
}
