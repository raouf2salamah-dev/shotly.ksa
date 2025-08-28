import 'package:flutter/material.dart'; 
import 'device_integrity_service.dart'; 
 
class SecurityWarningDialog extends StatelessWidget { 
  final DeviceIntegrityResult result;
 
  const SecurityWarningDialog({
    super.key, 
    required this.result,
  }); 
 
  @override 
  Widget build(BuildContext context) { 
    final issues = <String>[]; 
    if (result.isJailbrokenOrRooted) issues.add('Jailbreak/Root detected'); 
    if (!result.isRealDevice) issues.add('Running on emulator'); 
    if (result.developerMode) issues.add('Developer Mode enabled'); 
    if (result.canMockLocation) issues.add('Mock location allowed'); 
 
    return AlertDialog( 
      title: const Text('Security Warning'), 
      content: Column( 
        mainAxisSize: MainAxisSize.min, 
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [ 
          const Text( 
              'Your device environment appears insecure. This may affect account protection and purchases.'), 
          const SizedBox(height: 12), 
          if (issues.isNotEmpty) 
            ...issues.map((e) => Row( 
                  children: [ 
                    const Icon(Icons.warning_amber_rounded, size: 18), 
                    const SizedBox(width: 8), 
                    Expanded(child: Text(e)), 
                  ], 
                )), 
          const SizedBox(height: 12), 
          const Text( 
            'You can proceed at your own risk. Some features may be restricted.', 
            style: TextStyle(fontStyle: FontStyle.italic), 
          ), 
        ], 
      ), 
      actions: [ 
        TextButton( 
          onPressed: () => Navigator.of(context).pop(false), 
          child: const Text('Exit App'), 
        ), 
        ElevatedButton( 
          onPressed: () => Navigator.of(context).pop(true), 
          child: const Text('Proceed'), 
        ), 
      ], 
    ); 
  } 
}