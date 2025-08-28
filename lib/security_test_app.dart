import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'src/services/encrypted_hive_service.dart';
import 'src/examples/security_test.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Initialize encrypted Hive storage
  await EncryptedHiveService.initEarly();
  
  runApp(const SecurityTestApp());
}

class SecurityTestApp extends StatelessWidget {
  const SecurityTestApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Security Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const SecurityTestScreen(),
    );
  }
}