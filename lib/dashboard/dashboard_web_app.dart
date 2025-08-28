import 'package:flutter/material.dart';
import 'dashboard_home.dart';

/// Entry point for the security dashboard web application.
/// This allows the dashboard to be run as a standalone web app.
class DashboardWebApp extends StatelessWidget {
  const DashboardWebApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Security Dashboard',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: const DashboardHome(),
    );
  }
}

/// Main entry point for the dashboard web application
void main() {
  runApp(const DashboardWebApp());
}