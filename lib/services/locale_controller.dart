import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n/app_strings.dart';
import 'preferences_service.dart';

final localeControllerProvider =
    NotifierProvider<LocaleController, Locale>(LocaleController.new);

final stringsProvider = Provider<AppStrings>((ref) {
  final locale = ref.watch(localeControllerProvider);
  return AppStrings(locale.languageCode);
});

class LocaleController extends Notifier<Locale> {
  @override
  Locale build() {
    return ref.read(preferencesServiceProvider).locale();
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    await ref.read(preferencesServiceProvider).setLocale(locale);
  }

  Future<void> toggle() {
    return setLocale(state.languageCode == 'ar' ? const Locale('en') : const Locale('ar'));
  }
}
