import 'package:flutter/material.dart';
import 'security_dashboard.dart';
import 'webhook_service.dart';
import '../bootstrap/security_bootstrap.dart';

/// DashboardHome serves as the main entry point for the security dashboard web application.
/// It provides navigation between different dashboard sections and handles the overall layout.
class DashboardHome extends StatefulWidget {
  const DashboardHome({Key? key}) : super(key: key);

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  int _selectedIndex = 0;
  final WebhookService _webhookService = WebhookService();
  bool _isWebhookActive = false;
  String _lastUpdateTime = 'Never';

  @override
  void initState() {
    super.initState();
    _initWebhookService();
    
    // Initialize certificate alert configuration and check for expiring certificates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SecurityBootstrap.checkCertificateExpiration(context);
    });
  }

  Future<void> _initWebhookService() async {
    // Initialize the webhook service
    await _webhookService.initialize();
    
    // Set up a listener for webhook events
    _webhookService.addListener(() {
      if (mounted) {
        setState(() {
          _lastUpdateTime = DateTime.now().toString();
        });
      }
    });

    if (mounted) {
      setState(() {
        _isWebhookActive = _webhookService.isActive;
      });
    }
  }

  @override
  void dispose() {
    _webhookService.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Dashboard'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Text(
                'Last update: $_lastUpdateTime',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
          Switch(
            value: _isWebhookActive,
            onChanged: (value) async {
              if (value) {
                await _webhookService.startListening();
              } else {
                await _webhookService.stopListening();
              }
              setState(() {
                _isWebhookActive = _webhookService.isActive;
              });
            },
            activeColor: Colors.green,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          SecurityDashboard(),
          Center(child: Text('Build History - Coming Soon')),
          Center(child: Text('Settings - Coming Soon')),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.security),
            label: 'Security',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Build History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        onTap: _onItemTapped,
      ),
    );
  }
}