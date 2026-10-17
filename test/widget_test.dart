import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tawazon/app.dart';
import 'package:tawazon/core/constants/credits.dart';
import 'package:tawazon/services/preferences_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('splash shows credits', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const TawazonApp(),
      ),
    );

    expect(find.text(AppCredits.developedBy), findsOneWidget);
    expect(find.text(AppCredits.faculty), findsOneWidget);
    expect(find.byType(AnimatedScale), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2400));
    await tester.pump(const Duration(milliseconds: 400));
  });
}
