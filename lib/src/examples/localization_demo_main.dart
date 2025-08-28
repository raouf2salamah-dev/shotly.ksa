import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// هذا الملف يوضح كيفية إعداد الترجمة بشكل صحيح في تطبيق Flutter
/// يمكن استخدامه كمرجع لإصلاح مشاكل الترجمة
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Localization Demo',
      // إعداد مندوبي الترجمة - هذا هو الجزء المهم لحل مشكلة الترجمة
      localizationsDelegates: [
        // مندوبو الترجمة الأساسية من Flutter
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // اللغات المدعومة في التطبيق
      supportedLocales: const [
        Locale('en'), // الإنجليزية
        Locale('ar'), // العربية
      ],
      // تعيين اللغة الافتراضية للتطبيق
      locale: const Locale('ar'), // تعيين العربية كلغة افتراضية
      // تعيين سمة التطبيق
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Cairo', // خط يدعم العربية
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

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
              'مرحبًا بك في تطبيق Flutter',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // زر لعرض مربع حوار التاريخ - سيظهر بالعربية بسبب إعدادات الترجمة
            ElevatedButton(
              onPressed: () {
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
            // زر لعرض مربع حوار الوقت - سيظهر بالعربية بسبب إعدادات الترجمة
            ElevatedButton(
              onPressed: () {
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