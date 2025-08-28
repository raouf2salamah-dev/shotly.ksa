import 'package:flutter/material.dart';
import '../screens/analytics_page.dart';

class RTLAnalyticsExample extends StatelessWidget {
  const RTLAnalyticsExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Directionality(
      textDirection: TextDirection.rtl,
      child: AnalyticsPage(),
    );
  }
}

// Usage example:
// To use this widget, you can navigate to it or include it in your routes
// For example in your app.dart or main.dart:
//
// routes: {
//   '/rtl-analytics': (context) => const RTLAnalyticsExample(),
// }
//
// Or you can use it directly with Navigator:
// Navigator.push(context, MaterialPageRoute(builder: (context) => const RTLAnalyticsExample()));