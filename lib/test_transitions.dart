import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Transitions Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }

  // Router configuration
  late final GoRouter _router;
  
  MyApp({super.key}) {
    _router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: '/page1',
          builder: (context, state) => const DemoPage(color: Colors.red, title: 'Page 1'),
        ),
        GoRoute(
          path: '/page2',
          builder: (context, state) => const DemoPage(color: Colors.green, title: 'Page 2'),
        ),
        GoRoute(
          path: '/page3',
          builder: (context, state) => const DemoPage(color: Colors.blue, title: 'Page 3'),
        ),
      ],
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transitions Demo')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Test different page transitions', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.go('/page1'),
              child: const Text('Fade Transition'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => context.go('/page2'),
              child: const Text('Fade Transition 2'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => context.go('/page3'),
              child: const Text('Slide Transition'),
            ),
          ],
        ),
      ),
    );
  }
}

class DemoPage extends StatelessWidget {
  final Color color;
  final String title;
  
  const DemoPage({super.key, required this.color, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: color,
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 30, color: Colors.white),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}