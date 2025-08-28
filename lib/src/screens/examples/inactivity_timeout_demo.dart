import 'package:flutter/material.dart';
import '../../services/security_service.dart';

/// A demo screen that demonstrates the inactivity timeout feature
class InactivityTimeoutDemo extends StatefulWidget {
  const InactivityTimeoutDemo({Key? key}) : super(key: key);

  @override
  State<InactivityTimeoutDemo> createState() => _InactivityTimeoutDemoState();
}

class _InactivityTimeoutDemoState extends State<InactivityTimeoutDemo> {
  final SecurityService _securityService = SecurityService();
  bool _isLockScreenEnabled = true;
  bool _isLocked = false;
  String _sensitiveData = '';
  final TextEditingController _dataController = TextEditingController();
  
  // Security settings
  int _timeoutMinutes = 5;
  bool _requireBiometrics = true;

  @override
  void initState() {
    super.initState();
    
    // Apply initial security settings
    _securityService.updateSecuritySettings(
      SecuritySettings(
        timeoutMinutes: _timeoutMinutes,
        requireBiometrics: _requireBiometrics
      )
    );
    
    _setupSecurityService();
    
    // Show security intro dialog after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _securityService.showSecurityIntro(context);
      }
    });
  }

  @override
  void dispose() {
    _dataController.dispose();
    super.dispose();
  }

  void _setupSecurityService() {
    // Set callback for clearing sensitive data
    _securityService.setSensitiveDataCallback(() {
      if (_isLockScreenEnabled) {
        setState(() {
          // Clear sensitive data from UI
          _sensitiveData = '';
          _dataController.clear();
        });
      }
    });

    // Set callback for showing lock screen
    _securityService.setLockScreenCallback(() {
      if (_isLockScreenEnabled) {
        setState(() {
          _isLocked = true;
        });
      }
    });
  }

  void _unlockScreen() {
    setState(() {
      _isLocked = false;
    });
  }

  void _saveSensitiveData() {
    setState(() {
      _sensitiveData = _dataController.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inactivity Timeout Demo'),
      ),
      body: _isLocked ? _buildLockScreen() : _buildMainScreen(),
    );
  }

  Widget _buildLockScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.lock,
            size: 80,
            color: Colors.red,
          ),
          const SizedBox(height: 20),
          const Text(
            'App Locked',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Your app was locked due to inactivity',
            style: TextStyle(fontSize: 16),
          ),
          if (_requireBiometrics)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: const Text(
                'Biometric authentication required',
                style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
              ),
            ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            icon: Icon(_requireBiometrics ? Icons.fingerprint : Icons.lock_open),
            onPressed: _unlockScreen,
            label: Text(_requireBiometrics ? 'Authenticate' : 'Unlock App'),
          ),
        ],
      ),
    );
  }

  Widget _buildMainScreen() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(),
          const SizedBox(height: 20),
          _buildControls(),
          const SizedBox(height: 20),
          _buildSensitiveDataSection(),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Inactivity Timeout Protection',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'This demo shows how the app can automatically lock after being in the background for a period of time (currently set to $_timeoutMinutes ${_timeoutMinutes == 1 ? "minute" : "minutes"}).',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            const Text(
              'To test this feature:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildBulletPoint('Enter some sensitive data below'),
            _buildBulletPoint('Put the app in the background (press home button)'),
            _buildBulletPoint('Wait for $_timeoutMinutes ${_timeoutMinutes == 1 ? "minute" : "minutes"}'),
            _buildBulletPoint('Return to the app - it should be locked${_requireBiometrics ? " and require biometric authentication" : ""}'),
            const SizedBox(height: 12),
            const Text(
              'Note: For demo purposes, you can manually trigger the lock screen using the button below.',
              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 14)),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Controls',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Enable Lock Screen:'),
                Switch(
                  value: _isLockScreenEnabled,
                  onChanged: (value) {
                    setState(() {
                      _isLockScreenEnabled = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Timeout (minutes):'),
                DropdownButton<int>(
                  value: _timeoutMinutes,
                  items: [1, 2, 3, 5, 10, 15].map((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text(value.toString()),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null) {
                      setState(() {
                        _timeoutMinutes = newValue;
                        _securityService.updateSecuritySettings(
                          SecuritySettings(
                            timeoutMinutes: _timeoutMinutes,
                            requireBiometrics: _requireBiometrics
                          )
                        );
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Require Biometrics:'),
                Switch(
                  value: _requireBiometrics,
                  onChanged: (value) {
                    setState(() {
                      _requireBiometrics = value;
                      _securityService.updateSecuritySettings(
                        SecuritySettings(
                          timeoutMinutes: _timeoutMinutes,
                          requireBiometrics: _requireBiometrics
                        )
                      );
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (_isLockScreenEnabled) {
                  setState(() {
                    _isLocked = true;
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lock screen is disabled. Enable it first.'),
                    ),
                  );
                }
              },
              child: const Text('Manually Lock Screen'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensitiveDataSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sensitive Data',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _dataController,
              decoration: const InputDecoration(
                labelText: 'Enter sensitive data',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _saveSensitiveData,
                  child: const Text('Save Data'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _sensitiveData = '';
                      _dataController.clear();
                    });
                  },
                  child: const Text('Clear Data'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Stored Sensitive Data:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: _securityService.applyContentProtection(
                Text(
                  _sensitiveData.isEmpty ? 'No data stored' : _sensitiveData,
                  style: TextStyle(
                    color: _sensitiveData.isEmpty ? Colors.grey : Colors.black,
                  ),
                ),
                isProtected: _isLockScreenEnabled && _sensitiveData.isNotEmpty,
              ),
            ),
          ],
        ),
      ),
    );
  }
}