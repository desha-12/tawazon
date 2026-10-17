import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/storage_keys.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw StateError('SharedPreferences must be overridden in main()');
});

final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  return PreferencesService(ref.watch(sharedPreferencesProvider));
});

final moodLogsProvider = Provider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(preferencesServiceProvider).moodLogs();
});

class PreferencesService {
  PreferencesService(this._prefs);

  final SharedPreferences _prefs;

  Locale locale() {
    final code = _prefs.getString(StorageKeys.locale) ?? 'en';
    return Locale(code);
  }

  Future<void> setLocale(Locale locale) {
    return _prefs.setString(StorageKeys.locale, locale.languageCode);
  }

  bool onboardingDone() => _prefs.getBool(StorageKeys.onboardingDone) ?? false;

  Future<void> setOnboardingDone(bool value) {
    return _prefs.setBool(StorageKeys.onboardingDone, value);
  }

  bool prayerAlertsEnabled() =>
      _prefs.getBool(StorageKeys.prayerAlerts) ?? false;

  Future<void> setPrayerAlerts(bool value) {
    return _prefs.setBool(StorageKeys.prayerAlerts, value);
  }

  ({double latitude, double longitude})? prayerCoordinates() {
    final latitude = _prefs.getDouble(StorageKeys.prayerLatitude);
    final longitude = _prefs.getDouble(StorageKeys.prayerLongitude);
    if (latitude == null || longitude == null) return null;
    return (latitude: latitude, longitude: longitude);
  }

  bool prayerLocationIsDevice() =>
      _prefs.getBool(StorageKeys.prayerLocationIsDevice) ?? false;

  Future<void> setPrayerCoordinates({
    required double latitude,
    required double longitude,
    required bool fromDevice,
  }) async {
    await _prefs.setDouble(StorageKeys.prayerLatitude, latitude);
    await _prefs.setDouble(StorageKeys.prayerLongitude, longitude);
    await _prefs.setBool(StorageKeys.prayerLocationIsDevice, fromDevice);
  }

  int gardenStreak() => _prefs.getInt(StorageKeys.gardenStreak) ?? 0;

  Future<void> setGardenStreak(int value) {
    return _prefs.setInt(StorageKeys.gardenStreak, value);
  }

  int gardenWithers() => _prefs.getInt(StorageKeys.gardenWithers) ?? 0;

  Future<void> setGardenWithers(int value) {
    return _prefs.setInt(StorageKeys.gardenWithers, value);
  }

  String? lastPlantState() => _prefs.getString(StorageKeys.lastPlantState);

  Future<void> setLastPlantState(String value) {
    return _prefs.setString(StorageKeys.lastPlantState, value);
  }

  int completedFocusMinutes() =>
      _prefs.getInt(StorageKeys.completedFocusMinutes) ?? 0;

  Future<void> addCompletedFocusMinutes(int minutes) {
    return _prefs.setInt(
      StorageKeys.completedFocusMinutes,
      completedFocusMinutes() + minutes,
    );
  }

  String? lastMood() => _prefs.getString(StorageKeys.lastMood);

  Future<void> setLastMood(String mood) {
    return _prefs.setString(StorageKeys.lastMood, mood);
  }

  List<Map<String, dynamic>> moodLogs() {
    final raw = _prefs.getString(StorageKeys.moodLogs);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList();
  }

  Future<void> addMoodLog(String mood, DateTime at) async {
    final logs = moodLogs()..add({'mood': mood, 'at': at.toIso8601String()});
    final clipped = logs.length > 365 ? logs.sublist(logs.length - 365) : logs;
    await _prefs.setString(StorageKeys.moodLogs, jsonEncode(clipped));
  }

  bool examShieldEnabled() => _prefs.getBool(StorageKeys.examShield) ?? false;

  Future<void> setExamShieldEnabled(bool enabled) {
    return _prefs.setBool(StorageKeys.examShield, enabled);
  }

  String darkAppearance() =>
      _prefs.getString(StorageKeys.darkAppearance) ?? 'soft';

  Future<void> setDarkAppearance(String appearance) {
    return _prefs.setString(StorageKeys.darkAppearance, appearance);
  }

  String geminiApiKey() => _prefs.getString(StorageKeys.geminiApiKey) ?? '';

  Future<void> setGeminiApiKey(String value) {
    return _prefs.setString(StorageKeys.geminiApiKey, value);
  }

  List<Map<String, dynamic>> sleepLogs() {
    final raw = _prefs.getString(StorageKeys.sleepLogs);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> writeSleepLogs(List<Map<String, dynamic>> logs) {
    return _prefs.setString(StorageKeys.sleepLogs, jsonEncode(logs));
  }

  List<Map<String, dynamic>> chatHistory() {
    final raw = _prefs.getString(StorageKeys.chatHistory);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> writeChatHistory(List<Map<String, dynamic>> messages) {
    return _prefs.setString(StorageKeys.chatHistory, jsonEncode(messages));
  }
}
