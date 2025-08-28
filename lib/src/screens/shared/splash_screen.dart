import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import '../../services/auth_service.dart';
import '../../l10n/app_localizations.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  

  @override
  void initState() {
    debugPrint('initState called');
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthService>(context, listen: false);
      debugPrint('Post-frame callback executed');
      _checkAuthStatus(authService);
    });
  }

  void _checkAuthStatus(AuthService authService) {
    debugPrint('Checking auth status');
    
    if (!mounted) return;
    
    final isLoggedIn = authService.currentUser != null;
    
    if (isLoggedIn) {
      debugPrint('Navigating to /buyer');
      context.go('/buyer');
    } else {
      debugPrint('Navigating to /onboarding');
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo or animation
            Builder(builder: (context) {
              // Try multiple asset paths for web compatibility
              return Lottie.asset(
                'assets/animations/splash_animation.json',
                width: 200,
                height: 200,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  print('Error loading animation: $error');
                  // Fallback if animation file is missing
                  return const Icon(
                    Icons.cloud_download,
                    size: 100,
                    color: Color(0xFF4A6FFF),
                  );
                },
              );
            }),
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
            Text(
              'Welcome to Shotly',
              style: const TextStyle(
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