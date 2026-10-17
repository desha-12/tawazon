import 'package:flutter_test/flutter_test.dart';
import 'package:tawazon/core/utils/time_format.dart';

void main() {
  group('formatHours', () {
    test('formats English hour and minute labels', () {
      expect(formatHours(1.5), '1h 30m');
      expect(formatHours(0.5), '30m');
    });

    test('uses Arabic hour and minute labels', () {
      final formatted = formatHours(1.5, localeCode: 'ar');

      expect(formatted, contains('س'));
      expect(formatted, contains('د'));
    });

    test('carries rounded minutes into the next hour', () {
      expect(formatHours(1.999), '2h');
    });
  });
}