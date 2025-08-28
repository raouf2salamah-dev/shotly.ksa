import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'src/services/auth_service.dart';
import 'src/services/analytics_service.dart';
import 'src/screens/auth/login_screen.dart';

class SimpleApp extends StatefulWidget {
  const SimpleApp({super.key});

  @override
  State<SimpleApp> createState() => _SimpleAppState();
}

class _SimpleAppState extends State<SimpleApp> {
  late final AuthService _authService;
  late final AnalyticsService _analyticsService;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    _analyticsService = AnalyticsService();
    
    // Initialize services
    _initializeServices();
  }
  
  Future<void> _initializeServices() async {
    try {
      await _authService.init();
      await _analyticsService.init();
    } catch (e) {
      print('Error initializing services: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: _authService),
        Provider<AnalyticsService>.value(value: _analyticsService),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Shotly',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const LoginScreen(),
      ),
    );
  }
}