import 'package:flutter/material.dart';
import '../security/security_dialog_manager.dart';
import '../security/security_intro_dialog.dart';

/// Example showing how to integrate SecurityDialogManager into app initialization
class AppInitializationExample extends StatefulWidget {
  const AppInitializationExample({Key? key}) : super(key: key);

  @override
  State<AppInitializationExample> createState() => _AppInitializationExampleState();
}

class _AppInitializationExampleState extends State<AppInitializationExample> {
  @override
  void initState() {
    super.initState();
    // Schedule the security dialog check for after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showSecurityDialogIfNeeded();
    });
  }

  Future<void> _showSecurityDialogIfNeeded() async {
    // Use the SecurityDialogManager to show the dialog if it hasn't been shown before
    await SecurityDialogManager.showSecurityIntroDialogIfNeeded(
      context: context,
      dialogBuilder: () => const SecurityIntroDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Initialization Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.green,
              size: 64,
            ),
            const SizedBox(height: 24),
            const Text(
              'App Initialized Successfully',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Security dialog will only show on first launch',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () async {
                // Reset the dialog status for testing
                await SecurityDialogManager.resetSecurityDialogShownStatus();
                
                // Show the dialog again
                if (mounted) {
                  await SecurityDialogManager.showSecurityIntroDialogIfNeeded(
                    context: context,
                    dialogBuilder: () => const SecurityIntroDialog(),
                  );
                }
              },
              child: const Text('Reset & Show Dialog Again'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Example of how to use the SecurityDialogManager in your main.dart file
/// 
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   
///   // Initialize other services...
///   
///   runApp(const MyApp());
/// }
/// 
/// class MyApp extends StatelessWidget {
///   const MyApp({Key? key}) : super(key: key);
///   
///   @override
///   Widget build(BuildContext context) {
///     return MaterialApp(
///       home: const MyHomePage(),
///       // ...
///     );
///   }
/// }
/// 
/// class MyHomePage extends StatefulWidget {
///   const MyHomePage({Key? key}) : super(key: key);
///   
///   @override
///   State<MyHomePage> createState() => _MyHomePageState();
/// }
/// 
/// class _MyHomePageState extends State<MyHomePage> {
///   @override
///   void initState() {
///     super.initState();
///     // Show security dialog after the first frame is rendered
///     WidgetsBinding.instance.addPostFrameCallback((_) {
///       SecurityDialogManager.showSecurityIntroDialogIfNeeded(
///         context: context,
///         dialogBuilder: () => const SecurityIntroDialog(),
///       );
///     });
///   }
///   
///   // Rest of your widget implementation...
/// }
/// ```