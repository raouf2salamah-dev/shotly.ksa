import 'package:flutter/material.dart';
import '../../services/security_service.dart';
import '../../services/sensitive_data_manager.dart';

class SensitiveDataDemo extends StatefulWidget {
  const SensitiveDataDemo({Key? key}) : super(key: key);

  @override
  State<SensitiveDataDemo> createState() => _SensitiveDataDemoState();
}

class _SensitiveDataDemoState extends State<SensitiveDataDemo> {
  final SecurityService _securityService = SecurityService();
  final TextEditingController _sensitiveTextController = TextEditingController();
  final List<String> _sensitiveData = [];
  bool _isProtectionActive = true;
  String _lastAction = '';

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

  @override
  void dispose() {
    _sensitiveTextController.dispose();
    super.dispose();
  }

  Future<void> _initializeSecurityService() async {
    await _securityService.initialize();
    
    // Set up sensitive data protection
    _securityService.setSensitiveDataCallback(() {
      setState(() {
        _lastAction = 'Sensitive data cleared (background)';
      });
      _clearSensitiveData();
    });
  }

  void _clearSensitiveData() {
    // Clear text controller
    _sensitiveTextController.clear();
    
    // Clear in-memory list
    _sensitiveData.clear();
    
    setState(() {});
  }

  void _addSensitiveData() {
    if (_sensitiveTextController.text.isNotEmpty) {
      setState(() {
        _sensitiveData.add(_sensitiveTextController.text);
        _sensitiveTextController.clear();
      });
    }
  }

  void _toggleProtection() {
    setState(() {
      _isProtectionActive = !_isProtectionActive;
      _lastAction = _isProtectionActive 
          ? 'Protection enabled' 
          : 'Protection disabled';
    });
    
    // Manually clear data when protection is enabled
    if (_isProtectionActive) {
      _clearSensitiveData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensitive Data Protection'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Protection Status:'),
                        Text(
                          _isProtectionActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _isProtectionActive ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Last Action:'),
                        Text(_lastAction),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _toggleProtection,
                      child: Text(_isProtectionActive 
                          ? 'Disable Protection' 
                          : 'Enable Protection'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Input section
            const Text(
              'Enter Sensitive Data:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _sensitiveTextController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Type sensitive information here',
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _addSensitiveData,
              child: const Text('Add to Memory'),
            ),
            const SizedBox(height: 16),
            
            // Sensitive data display
            const Text(
              'Sensitive Data in Memory:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: _securityService.applyContentProtection(
                  _sensitiveData.isEmpty
                      ? const Center(child: Text('No sensitive data in memory'))
                      : ListView.builder(
                          itemCount: _sensitiveData.length,
                          itemBuilder: (context, index) {
                            return Card(
                              child: ListTile(
                                title: Text(_sensitiveData[index]),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () {
                                    setState(() {
                                      _sensitiveData.removeAt(index);
                                    });
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                  isProtected: _isProtectionActive,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _clearSensitiveData();
                setState(() {
                  _lastAction = 'Sensitive data cleared (manual)';
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Clear All Sensitive Data'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Note: Put the app in background (home button) to test automatic clearing',
              style: TextStyle(fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}