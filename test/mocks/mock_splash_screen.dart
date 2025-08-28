import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shotly/src/services/auth_service.dart';

/// A simplified version of the SplashScreen for testing purposes
/// This removes dependencies on animations, localization, and other complex widgets
class MockSplashScreen extends StatefulWidget {
  final Function(MockSplashScreenState)? onCreated;
  final bool skipInitialAuthCheck;
  
  const MockSplashScreen({
    super.key, 
    this.onCreated,
    this.skipInitialAuthCheck = false,
  });

  @override
  MockSplashScreenState createState() => MockSplashScreenState(skipInitialAuthCheck: skipInitialAuthCheck);
}

class MockSplashScreenState extends State<MockSplashScreen> {
  final bool skipInitialAuthCheck;

  @override
  void initState() {
    super.initState();
    if (widget.onCreated != null) {
      widget.onCreated!(this);
    }
    // Only perform the auth check in initState if not skipped
    if (!skipInitialAuthCheck) {
      _checkAuthStatus();
    }
  }
  
  // Constructor with default value
  MockSplashScreenState({this.skipInitialAuthCheck = false});

  // In tests, we'll manually trigger this method instead of using initState
  void checkAuthStatus() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final isLoggedIn = authService.isLoggedIn;
    
    // Navigation logic is simplified for testing
    if (isLoggedIn) {
      if (authService.isSeller) {
        print('Navigate to seller screen');
      } else if (authService.isAdmin) {
        print('Navigate to admin screen');
      } else if (authService.isSuperAdmin) {
        print('Navigate to super admin screen');
      } else {
        print('Navigate to buyer screen');
      }
    } else {
      print('Navigate to onboarding screen');
    }
  }
  
  Future<void> _checkAuthStatus() async {
    // For testing, we'll avoid using timers
    if (!mounted) return;
    checkAuthStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Simple icon instead of Lottie animation
            const Icon(
              Icons.cloud_download,
              size: 100,
              color: Color(0xFF4A6FFF),
            ),
            const SizedBox(height: 24),
            const Text(
              'Shotly',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A6FFF),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Welcome to Shotly',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4A6FFF),
              ),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}