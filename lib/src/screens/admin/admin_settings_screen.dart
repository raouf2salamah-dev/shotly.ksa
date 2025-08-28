import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool _isLoading = false;
  
  // Mock settings
  bool _enableUserRegistration = true;
  bool _enableContentUploads = true;
  bool _enablePurchases = true;
  bool _enableNotifications = true;
  bool _enableAnalytics = true;
  bool _enableDarkMode = false;
  bool _enableMaintenanceMode = false;
  String _selectedLanguage = 'English';
  String _selectedCurrency = 'USD';
  double _commissionRate = 15.0; // 15%
  int _maxUploadSize = 50; // 50 MB
  
  final List<String> _languages = ['English', 'Arabic', 'French', 'Spanish', 'German'];
  final List<String> _currencies = ['USD', 'EUR', 'GBP', 'JPY', 'AUD', 'CAD', 'SAR'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = Provider.of<AuthService>(context);
    
    // Check if user is admin
    if (!authService.isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('System Settings'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('You need admin privileges to access this page'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/login'),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Refresh settings (would fetch from backend in real app)
              setState(() {});
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('System Status'),
                  _buildSystemStatusCard(),
                  const SizedBox(height: 24.0),
                  
                  _buildSectionHeader('General Settings'),
                  _buildSettingsCard(
                    children: [
                      _buildSwitchSetting(
                        title: 'Enable User Registration',
                        subtitle: 'Allow new users to register',
                        value: _enableUserRegistration,
                        onChanged: (value) {
                          setState(() {
                            _enableUserRegistration = value;
                          });
                        },
                      ),
                      const Divider(),
                      _buildSwitchSetting(
                        title: 'Enable Content Uploads',
                        subtitle: 'Allow sellers to upload new content',
                        value: _enableContentUploads,
                        onChanged: (value) {
                          setState(() {
                            _enableContentUploads = value;
                          });
                        },
                      ),
                      const Divider(),
                      _buildSwitchSetting(
                        title: 'Enable Purchases',
                        subtitle: 'Allow buyers to purchase content',
                        value: _enablePurchases,
                        onChanged: (value) {
                          setState(() {
                            _enablePurchases = value;
                          });
                        },
                      ),
                      const Divider(),
                      _buildSwitchSetting(
                        title: 'Enable Notifications',
                        subtitle: 'Send push notifications to users',
                        value: _enableNotifications,
                        onChanged: (value) {
                          setState(() {
                            _enableNotifications = value;
                          });
                        },
                      ),
                      const Divider(),
                      _buildSwitchSetting(
                        title: 'Enable Analytics',
                        subtitle: 'Collect usage data for analytics',
                        value: _enableAnalytics,
                        onChanged: (value) {
                          setState(() {
                            _enableAnalytics = value;
                          });
                        },
                      ),
                      const Divider(),
                      _buildSwitchSetting(
                        title: 'Dark Mode',
                        subtitle: 'Enable dark theme for the app',
                        value: _enableDarkMode,
                        onChanged: (value) {
                          setState(() {
                            _enableDarkMode = value;
                          });
                        },
                      ),
                      const Divider(),
                      _buildSwitchSetting(
                        title: 'Maintenance Mode',
                        subtitle: 'Put the app in maintenance mode (only admins can access)',
                        value: _enableMaintenanceMode,
                        onChanged: (value) {
                          _showMaintenanceModeConfirmation(value);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24.0),
                  
                  _buildSectionHeader('Localization'),
                  _buildSettingsCard(
                    children: [
                      _buildDropdownSetting(
                        title: 'Default Language',
                        value: _selectedLanguage,
                        items: _languages.map((lang) => DropdownMenuItem(
                          value: lang,
                          child: Text(lang),
                        )).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedLanguage = value.toString();
                          });
                        },
                      ),
                      const Divider(),
                      _buildDropdownSetting(
                        title: 'Default Currency',
                        value: _selectedCurrency,
                        items: _currencies.map((currency) => DropdownMenuItem(
                          value: currency,
                          child: Text(currency),
                        )).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCurrency = value.toString();
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24.0),
                  
                  _buildSectionHeader('Business Settings'),
                  _buildSettingsCard(
                    children: [
                      _buildSliderSetting(
                        title: 'Commission Rate',
                        subtitle: 'Percentage taken from each sale',
                        value: _commissionRate,
                        min: 0.0,
                        max: 30.0,
                        divisions: 30,
                        labelFormat: '%.1f%%',
                        onChanged: (value) {
                          setState(() {
                            _commissionRate = value;
                          });
                        },
                      ),
                      const Divider(),
                      _buildSliderSetting(
                        title: 'Maximum Upload Size',
                        subtitle: 'Maximum file size for uploads (MB)',
                        value: _maxUploadSize.toDouble(),
                        min: 10.0,
                        max: 500.0,
                        divisions: 49,
                        labelFormat: '%.0f MB',
                        onChanged: (value) {
                          setState(() {
                            _maxUploadSize = value.toInt();
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24.0),
                  
                  _buildSectionHeader('Developer Options'),
                  _buildSettingsCard(
                    children: [
                      // Firebase Testing Section
                      ListTile(
                        leading: const Icon(Icons.bug_report),
                        title: const Text('Test Crashlytics'),
                        subtitle: const Text('Send a test event to Firebase Crashlytics'),
                        trailing: IconButton(
                          icon: const Icon(Icons.play_arrow),
                          onPressed: () {}, // Temporarily disabled
                        ),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.dangerous, color: Colors.red),
                        title: const Text('Force Crash'),
                        subtitle: const Text('Deliberately crash the app to test crash reporting'),
                        trailing: IconButton(
                          icon: const Icon(Icons.play_arrow, color: Colors.red),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Force Crash Confirmation'),
                                content: const Text(
                                  'Are you sure you want to force crash the app? This will help test the crash reporting system.'
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      // This would actually force a crash in a real app
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Crash simulation triggered')),
                                      );
                                    },
                                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                                    child: const Text('Force Crash'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.smart_toy, color: Colors.blue),
                        title: const Text('AI Model Settings'),
                        subtitle: const Text('Configure AI model parameters and features'),
                        trailing: IconButton(
                          icon: const Icon(Icons.settings),
                          onPressed: () => context.go('/admin/ai-settings'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24.0),
                  
                  _buildSectionHeader('System Actions'),
                  _buildSettingsCard(
                    children: [
                      _buildActionButton(
                        title: 'Clear Cache',
                        subtitle: 'Clear all cached data',
                        icon: Icons.cleaning_services,
                        onPressed: () {
                          _showActionConfirmation(
                            'Clear Cache',
                            'Are you sure you want to clear all cached data?',
                            () => _performSystemAction('Cache cleared successfully'),
                          );
                        },
                      ),
                      const Divider(),
                      _buildActionButton(
                        title: 'Reset Analytics',
                        subtitle: 'Reset all analytics data',
                        icon: Icons.analytics,
                        onPressed: () {
                          _showActionConfirmation(
                            'Reset Analytics',
                            'Are you sure you want to reset all analytics data? This action cannot be undone.',
                            () => _performSystemAction('Analytics data reset successfully'),
                          );
                        },
                      ),
                      const Divider(),
                      _buildActionButton(
                        title: 'Reset Settings',
                        subtitle: 'Reset all settings to default values',
                        icon: Icons.restore,
                        onPressed: () {
                          _showActionConfirmation(
                            'Reset Settings',
                            'Are you sure you want to reset all settings to their default values?',
                            _resetSettings,
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 32.0),
                  
                  Center(
                    child: CustomButton(
                      text: 'Save Settings',
                      icon: Icons.save,
                      onPressed: _saveSettings,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                ],
              ),
            ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }
  
  Widget _buildSettingsCard({required List<Widget> children}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
  
  Widget _buildSystemStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current Status',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    // Refresh status (would fetch from backend in real app)
                    setState(() {});
                  },
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Row(
              children: [
                Expanded(
                  child: _buildStatusItem(
                    title: 'Server',
                    status: 'Online',
                    icon: Icons.cloud_done,
                    color: Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatusItem(
                    title: 'Database',
                    status: 'Operational',
                    icon: Icons.storage,
                    color: Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatusItem(
                    title: 'Storage',
                    status: '68% Used',
                    icon: Icons.sd_storage,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Row(
              children: [
                Expanded(
                  child: _buildStatusItem(
                    title: 'API',
                    status: 'Operational',
                    icon: Icons.api,
                    color: Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatusItem(
                    title: 'Payment Gateway',
                    status: 'Active',
                    icon: Icons.payment,
                    color: Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatusItem(
                    title: 'Cache',
                    status: 'Optimized',
                    icon: Icons.memory,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem({
    required String title,
    required String status,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24.0),
        const SizedBox(height: 4.0),
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        Text(
          status,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSwitchSetting({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildDropdownSetting<T>({
    required String title,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required Function(T?) onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildSliderSetting({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String labelFormat,
    required Function(double) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8.0),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: value,
                min: min,
                max: max,
                divisions: divisions,
                label: labelFormat.replaceAll('%.1f', value.toStringAsFixed(1))
                    .replaceAll('%.0f', value.toStringAsFixed(0)),
                onChanged: onChanged,
              ),
            ),
            SizedBox(
              width: 60,
              child: Text(
                labelFormat.replaceAll('%.1f', value.toStringAsFixed(1))
                    .replaceAll('%.0f', value.toStringAsFixed(0)),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Row(
      children: [
        Icon(icon),
        const SizedBox(width: 16.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        ElevatedButton(
          onPressed: onPressed,
          child: const Text('Execute'),
        ),
      ],
    );
  }

  void _showMaintenanceModeConfirmation(bool value) {
    if (value) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Enable Maintenance Mode'),
          content: const Text(
            'Are you sure you want to enable maintenance mode? This will prevent all non-admin users from accessing the app.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _enableMaintenanceMode = true;
                });
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Enable'),
            ),
          ],
        ),
      );
    } else {
      setState(() {
        _enableMaintenanceMode = false;
      });
    }
  }

  void _showActionConfirmation(
    String title,
    String message,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _performSystemAction(String successMessage) {
    // In a real app, this would perform the actual action
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(successMessage)),
    );
  }

  void _resetSettings() {
    setState(() {
      _enableUserRegistration = true;
      _enableContentUploads = true;
      _enablePurchases = true;
      _enableNotifications = true;
      _enableAnalytics = true;
      _enableDarkMode = false;
      _enableMaintenanceMode = false;
      _selectedLanguage = 'English';
      _selectedCurrency = 'USD';
      _commissionRate = 15.0;
      _maxUploadSize = 50;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All settings have been reset to default values')),
    );
  }

  void _saveSettings() {
    setState(() {
      _isLoading = true;
    });
    
    // Simulate API call
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully')),
      );
    });
  }
}