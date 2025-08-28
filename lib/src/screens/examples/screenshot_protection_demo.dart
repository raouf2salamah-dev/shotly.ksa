import 'package:flutter/material.dart';
import '../../services/security_service.dart';
import 'package:visibility_detector/visibility_detector.dart';

class ScreenshotProtectionDemo extends StatefulWidget {
  const ScreenshotProtectionDemo({Key? key}) : super(key: key);

  @override
  State<ScreenshotProtectionDemo> createState() => _ScreenshotProtectionDemoState();
}

class _ScreenshotProtectionDemoState extends State<ScreenshotProtectionDemo> {
  final SecurityService _securityService = SecurityService();
  bool _isProtectionActive = true;
  bool _isAppSwitcherProtectionActive = true;
  bool _screenshotDetected = false;
  int _screenshotCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeSecurityService();
    
    // Show security intro dialog after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _securityService.showSecurityIntro(context);
      }
    });
  }

  Future<void> _initializeSecurityService() async {
    await _securityService.initialize();
    _securityService.setScreenshotCallback(_onScreenshotDetected);
    
    // Setup iOS app switcher protection if available and enabled
    if (_securityService.supportsAppSwitcherHiding && _isAppSwitcherProtectionActive) {
      await _setupIOSAppSwitcherProtection();
    }
  }
  
  /// Setup iOS app switcher protection with error handling
  Future<void> _setupIOSAppSwitcherProtection() async {
    if (!_securityService.supportsAppSwitcherHiding) return;
    
    try { 
      await _securityService.setupIOSAppSwitcherProtectionWithErrorHandling(); 
    } catch (error) { 
      if (error.toString().contains('OverlayError.alreadyAdded')) { 
        print("Overlay already exists. No action needed."); 
      } else if (error.toString().contains('OverlayError.failedToAdd')) { 
        print("Failed to add overlay. Check memory and view hierarchy."); 
      } else { 
        print("Unexpected error: ${error.toString()}"); 
      } 
    } 
  }

  void _onScreenshotDetected() {
    if (mounted) {
      setState(() {
        _screenshotDetected = true;
        _screenshotCount++;
      });

      // Show a snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Screenshot detected! Count: $_screenshotCount'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );

      // Reset the detection flag after a delay
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _screenshotDetected = false;
          });
        }
      });
    }
  }

  // Build the sensitive content widget
  Widget _buildSensitiveContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          const Text(
            'Sensitive Information',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Credit Card: **** **** **** 1234\nExpiry: 12/25\nCVV: ***',
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_securityService.supportsScreenshotPrevention)
                Text(
                  _isProtectionActive
                      ? 'Screenshot protected on Android'
                      : 'NOT protected from screenshots',
                  style: TextStyle(
                    color: _isProtectionActive ? Colors.green : Colors.red,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              if (_securityService.supportsScreenshotPrevention && 
                  _securityService.supportsAppSwitcherHiding)
                const Text(' • '),
              if (_securityService.supportsAppSwitcherHiding)
                Text(
                  _isAppSwitcherProtectionActive
                      ? 'Hidden in app switcher on iOS'
                      : 'Visible in app switcher',
                  style: TextStyle(
                    color: _isAppSwitcherProtectionActive ? Colors.green : Colors.red,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Screenshot Protection Demo'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Platform support information
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Platform Support',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    _buildSupportRow(
                      'Screenshot Detection',
                      _securityService.supportsScreenshotDetection,
                    ),
                    const SizedBox(height: 4),
                    _buildSupportRow(
                      'Screenshot Prevention',
                      _securityService.supportsScreenshotPrevention,
                    ),
                    const SizedBox(height: 4),
                    _buildSupportRow(
                      'App Switcher Content Hiding',
                      _securityService.supportsAppSwitcherHiding,
                    ),
                  ],
                ),
              ),
            ),

            // Screenshot detection status
            Card(
              margin: const EdgeInsets.all(16),
              color: _screenshotDetected ? Colors.red.shade50 : null,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Screenshot Detection',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Icon(
                      _screenshotDetected
                          ? Icons.camera_alt
                          : Icons.camera_alt_outlined,
                      size: 48,
                      color: _screenshotDetected ? Colors.red : Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _screenshotDetected
                          ? 'Screenshot Detected!'
                          : 'No Screenshots Detected',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _screenshotDetected ? Colors.red : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Total Screenshots: $_screenshotCount'),
                  ],
                ),
              ),
            ),

            // Sensitive content example
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Protected Content Example',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _securityService.applyContentProtection(
                      _buildSensitiveContent(),
                      isProtected: _isProtectionActive && _isAppSwitcherProtectionActive,
                    ),
                    const SizedBox(height: 8),
                    if (_securityService.supportsAppSwitcherHiding)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('App Switcher Protection:'),
                          Switch(
                            value: _isAppSwitcherProtectionActive,
                            onChanged: (value) async {
                              setState(() {
                                _isAppSwitcherProtectionActive = value;
                              });
                              
                              // Setup or disable iOS app switcher protection
                              if (_securityService.supportsAppSwitcherHiding) {
                                if (value) {
                                  await _setupIOSAppSwitcherProtection();
                                } else {
                                  await _securityService.disableIOSAppSwitcherProtection();
                                }
                              }
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    value
                                        ? 'App switcher protection enabled'
                                        : 'App switcher protection disabled',
                                  ),
                                  backgroundColor:
                                      value ? Colors.green : Colors.orange,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          setState(() {
            _isProtectionActive = !_isProtectionActive;
          });
          
          // Enable or disable secure screen on Android
          if (_securityService.supportsScreenshotPrevention) {
            if (_isProtectionActive) {
              await _securityService.enableSecureScreen();
            } else {
              await _securityService.disableSecureScreen();
            }
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isProtectionActive
                    ? 'Screenshot protection enabled'
                    : 'Screenshot protection disabled',
              ),
              backgroundColor:
                  _isProtectionActive ? Colors.green : Colors.orange,
            ),
          );
        },
        icon: Icon(_isProtectionActive ? Icons.lock : Icons.lock_open),
        label: Text(_isProtectionActive ? 'Disable Protection' : 'Enable Protection'),
      ),
    );
  }

  Widget _buildSupportRow(String feature, bool isSupported) {
    return Row(
      children: [
        Icon(
          isSupported ? Icons.check_circle : Icons.cancel,
          color: isSupported ? Colors.green : Colors.red,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(feature),
        const Spacer(),
        Text(
          isSupported ? 'Supported' : 'Not Supported',
          style: TextStyle(
            color: isSupported ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}