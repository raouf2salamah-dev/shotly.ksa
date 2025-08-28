import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shotly/src/services/locale_service.dart';

void main() {
  group('LocaleService Tests', () {
    late LocaleService localeService;

    setUp(() {
      localeService = LocaleService();
    });

    test('Default locale should be English', () {
      expect(localeService.locale, equals(const Locale('en')));
    });

    test('Setting locale to Arabic updates locale value', () {
      localeService.setLocale(const Locale('ar'));
      expect(localeService.locale, equals(const Locale('ar')));
    });

    test('Setting locale to English updates locale value', () {
      // First set to Arabic to test changing back to English
      localeService.setLocale(const Locale('ar'));
      expect(localeService.locale, equals(const Locale('ar')));
      
      // Now change to English
      localeService.setLocale(const Locale('en'));
      expect(localeService.locale, equals(const Locale('en')));
    });

    test('Toggle locale switches between English and Arabic', () {
      // Start with English
      localeService.setLocale(const Locale('en'));
      expect(localeService.locale, equals(const Locale('en')));

      // Toggle to Arabic
      localeService.toggleLocale();
      expect(localeService.locale, equals(const Locale('ar')));

      // Toggle back to English
      localeService.toggleLocale();
      expect(localeService.locale, equals(const Locale('en')));
    });

    test('isEnglish returns correct value', () {
      localeService.setLocale(const Locale('en'));
      expect(localeService.isEnglish, isTrue);

      localeService.setLocale(const Locale('ar'));
      expect(localeService.isEnglish, isFalse);
    });

    test('isArabic returns correct value', () {
      localeService.setLocale(const Locale('en'));
      expect(localeService.isArabic, isFalse);

      localeService.setLocale(const Locale('ar'));
      expect(localeService.isArabic, isTrue);
    });

    test('Notifies listeners when locale changes', () {
      int notificationCount = 0;
      
      // Add listener to count notifications
      localeService.addListener(() {
        notificationCount++;
      });

      // Change locale and verify notification
      localeService.setLocale(const Locale('ar'));
      expect(notificationCount, equals(1));

      // Change locale again and verify another notification
      localeService.setLocale(const Locale('en'));
      expect(notificationCount, equals(2));
    });
  });
}