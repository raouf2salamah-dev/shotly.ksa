import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// هذا المثال يوضح كيفية إعداد الترجمة بشكل صحيح في تطبيق Flutter
class LocalizationFixExample extends StatelessWidget {
  const LocalizationFixExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Localization Fix Example',
      // إعداد مندوبي الترجمة (هذه هي النقطة المهمة لحل الخطأ)
      localizationsDelegates: [
        // مندوبو الترجمة الأساسية من Flutter
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // اللغات المدعومة
      supportedLocales: const [
        Locale('en'), // الإنجليزية
        Locale('ar'), // العربية
      ],
      // اللغة الافتراضية
      locale: const Locale('ar'),
      home: const LocalizationDemoHome(),
    );
  }
}

/// شاشة رئيسية بسيطة تعرض عناصر واجهة مستخدم متعددة
/// لاختبار الترجمة التلقائية مثل مربع حوار التاريخ
class LocalizationDemoHome extends StatelessWidget {
  const LocalizationDemoHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مثال الترجمة'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'مرحبًا بك في مثال الترجمة',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // عرض مربع حوار التاريخ لاختبار الترجمة التلقائية
                showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
              },
              child: const Text('اختر تاريخًا'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                // عرض مربع حوار الوقت لاختبار الترجمة التلقائية
                showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
              },
              child: const Text('اختر وقتًا'),
            ),
          ],
        ),
      ),
    );
  }
}

/// مثال على كيفية استخدام المثال أعلاه في main.dart
/// 
/// ```dart
/// import 'package:flutter/material.dart';
/// import 'src/examples/localization_fix_example.dart';
/// 
/// void main() {
///   runApp(const LocalizationFixExample());
/// }
/// ```