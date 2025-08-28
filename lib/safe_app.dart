import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'src/services/auth_service_safe.dart';
import 'src/services/analytics_service_safe.dart';
import 'src/screens/auth/login_screen_safe.dart';

class SafeApp extends StatelessWidget {
  const SafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthServiceSafe()),
        Provider(create: (_) => AnalyticsServiceSafe()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Shotly',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthServiceSafe>(context);
    
    // Show loading indicator while auth is initializing
    if (!authService.isInitialized) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }
    
    // Show login screen if not logged in
    if (!authService.isLoggedIn) {
      return const LoginScreenSafe();
    }
    
    // Show main app content if logged in
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shotly'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authService.signOut(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 80,
            ),
            const SizedBox(height: 20),
            const Text(
              'Successfully logged in!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              'Welcome, ${authService.currentUser?.email ?? "User"}',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}