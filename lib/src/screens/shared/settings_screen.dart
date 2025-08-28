import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

import '../../services/secure_storage_service.dart';

import '../../utils/firebase_test.dart';

import '../../services/auth_service.dart';
import '../../services/theme_service.dart';
import '../../services/locale_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  
  // Profile settings
  final _nameController = TextEditingController();
  File? _profileImage;
  String? _currentPhotoUrl;
  
  // Password settings
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  // Notification settings
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _salesNotifications = true;
  bool _contentUpdates = true;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadUserData();
    _loadNotificationSettings();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;
      
      if (user != null) {
        // Get user document from Firestore to get additional data
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        
        setState(() {
          _nameController.text = user.displayName ?? '';
          _currentPhotoUrl = user.photoURL;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load user data: ${e.toString()}'))
        );
      }
    }
  }
  
  Future<void> _loadNotificationSettings() async {
    try {
      // Use SecureStorageService instead of SharedPreferences
      final emailNotif = await SecureStorageService.read('emailNotifications');
      final pushNotif = await SecureStorageService.read('pushNotifications');
      final salesNotif = await SecureStorageService.read('salesNotifications');
      final contentUpd = await SecureStorageService.read('contentUpdates');
      
      setState(() {
        _emailNotifications = emailNotif == 'true';
        _pushNotifications = pushNotif == 'true';
        _salesNotifications = salesNotif == 'true';
        _contentUpdates = contentUpd == 'true';
      });
    } catch (e) {
      // Use defaults if preferences can't be loaded
    }
  }
  
  Future<void> _saveNotificationSettings() async {
    try {
      // Use SecureStorageService instead of SharedPreferences
      await SecureStorageService.write('emailNotifications', _emailNotifications.toString());
      await SecureStorageService.write('pushNotifications', _pushNotifications.toString());
      await SecureStorageService.write('salesNotifications', _salesNotifications.toString());
      await SecureStorageService.write('contentUpdates', _contentUpdates.toString());
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification settings saved securely'))
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save notification settings: ${e.toString()}'))
        );
      }
    }
  }
  
  Future<void> _pickProfileImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      
      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: ${e.toString()}'))
      );
    }
  }
  
  Future<void> _updateProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name'))
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      await authService.updateUserProfile(
        name: _nameController.text.trim(),
        profileImage: _profileImage,
      );
      
      setState(() {
        _isLoading = false;
        _profileImage = null; // Reset after successful update
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully'))
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: ${e.toString()}'))
        );
      }
    }
  }
  
  Future<void> _updatePassword() async {
    // Validate password fields
    if (_currentPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your current password'))
      );
      return;
    }
    
    if (_newPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a new password'))
      );
      return;
    }
    
    if (_newPasswordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters'))
      );
      return;
    }
    
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match'))
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      await authService.updatePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );
      
      setState(() {
        _isLoading = false;
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully'))
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update password: ${e.toString()}'))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeService = Provider.of<ThemeService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.translate('settings')),
        actions: [
          IconButton(
            icon: const Icon(Icons.storage),
            tooltip: 'Firestore Cache Demo',
            onPressed: () => context.push('/firestore-cache-demo'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: AppLocalizations.of(context)!.translate('profile')),
            Tab(text: AppLocalizations.of(context)!.translate('account')),
            Tab(text: AppLocalizations.of(context)!.translate('preferences')),
            Tab(text: AppLocalizations.of(context)!.translate('legal')),
            Tab(text: AppLocalizations.of(context)!.translate('developer')),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildProfileTab(),
                _buildAccountTab(),
                _buildPreferencesTab(themeService),
                _buildLegalTab(),
                _buildDeveloperTab(),
              ],
            ),
    );
  }
  
  Widget _buildProfileTab() {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile image
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 60.0,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  backgroundImage: _profileImage != null
                      ? FileImage(_profileImage!) as ImageProvider
                      : _currentPhotoUrl != null
                          ? NetworkImage(_currentPhotoUrl!) as ImageProvider
                          : null,
                  child: (_profileImage == null && _currentPhotoUrl == null)
                      ? Icon(
                          Icons.person,
                          size: 60.0,
                          color: theme.colorScheme.primary,
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, color: Colors.white),
                      onPressed: _pickProfileImage,
                      constraints: const BoxConstraints.tightFor(
                        width: 40.0,
                        height: 40.0,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32.0),
          
          // Name field
          Text(
            AppLocalizations.of(context)!.translate('name'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8.0),
          CustomTextField(
            controller: _nameController,
            hintText: AppLocalizations.of(context)!.translate('yourName'),
            prefixIcon: Icons.person,
          ),
          const SizedBox(height: 32.0),
          
          // Update button
          CustomButton(
            text: AppLocalizations.of(context)!.translate('updateProfile'),
            icon: Icons.save,
            isLoading: _isLoading,
            onPressed: _updateProfile,
          ),
        ],
      ),
    );
  }
  
  Widget _buildAccountTab() {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Password section
          Text(
            AppLocalizations.of(context)!.translate('changePassword'),
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 16.0),
          
          // Current password
          CustomTextField(
            controller: _currentPasswordController,
            hintText: AppLocalizations.of(context)!.translate('currentPassword'),
            prefixIcon: Icons.lock,
            isPassword: true,
          ),
          const SizedBox(height: 16.0),
          
          // New password
          CustomTextField(
            controller: _newPasswordController,
            hintText: AppLocalizations.of(context)!.translate('newPassword'),
            prefixIcon: Icons.lock_outline,
            isPassword: true,
          ),
          const SizedBox(height: 16.0),
          
          // Confirm password
          CustomTextField(
            controller: _confirmPasswordController,
            hintText: AppLocalizations.of(context)!.translate('confirmNewPassword'),
            prefixIcon: Icons.lock_outline,
            isPassword: true,
          ),
          const SizedBox(height: 32.0),
          
          // Update password button
          CustomButton(
            text: AppLocalizations.of(context)!.translate('updatePassword'),
            icon: Icons.save,
            isLoading: _isLoading,
            onPressed: _updatePassword,
          ),
          
          const SizedBox(height: 48.0),
          const Divider(),
          const SizedBox(height: 24.0),
          
          // Danger zone
          Text(
            AppLocalizations.of(context)!.translate('dangerZone'),
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 16.0),
          CustomButton(
            text: AppLocalizations.of(context)!.translate('deleteAccount'),
            icon: Icons.delete_forever,
            backgroundColor: Colors.red,
            onPressed: () {
              _showDeleteAccountDialog();
            },
          ),
        ],
      ),
    );
  }
  
  void _changeLanguage(Locale locale) { 
    setState(() { 
      final localeService = Provider.of<LocaleService>(context, listen: false);
      localeService.setLocale(locale); 
    }); 
  }

  Widget _buildPreferencesTab(ThemeService themeService) {
    final theme = Theme.of(context);
    final localeService = Provider.of<LocaleService>(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Theme settings
          Text(
            AppLocalizations.of(context)!.translate('preferences'),
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 16.0),
          _buildSettingsCard(
            icon: Icons.brightness_6,
            title: AppLocalizations.of(context)!.translate('darkMode'),
            trailing: Switch(
              value: themeService.isDarkMode(context),
              onChanged: (value) {
                themeService.toggleTheme();
              },
            ),
          ),
          
          // Language settings
          const SizedBox(height: 16.0),
          _buildSettingsCard(
            icon: Icons.language,
            title: AppLocalizations.of(context)!.translate('language'),
            subtitle: localeService.locale.languageCode == 'en' ? 'English' : 'العربية',
            trailing: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: theme.colorScheme.surfaceVariant,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () => _changeLanguage(const Locale('en')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: localeService.locale.languageCode == 'en' 
                          ? theme.colorScheme.primary 
                          : theme.colorScheme.surfaceVariant,
                      foregroundColor: localeService.locale.languageCode == 'en' 
                          ? theme.colorScheme.onPrimary 
                          : theme.colorScheme.onSurfaceVariant,
                      elevation: localeService.locale.languageCode == 'en' ? 2 : 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text('English'),
                  ),
                  ElevatedButton(
                    onPressed: () => _changeLanguage(const Locale('ar')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: localeService.locale.languageCode == 'ar' 
                          ? theme.colorScheme.primary 
                          : theme.colorScheme.surfaceVariant,
                      foregroundColor: localeService.locale.languageCode == 'ar' 
                          ? theme.colorScheme.onPrimary 
                          : theme.colorScheme.onSurfaceVariant,
                      elevation: localeService.locale.languageCode == 'ar' ? 2 : 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text('العربية'),
                  ),
                ],
              ),
            ),
          ),
          
          // Notification settings
          const SizedBox(height: 32.0),
          Text(
            AppLocalizations.of(context)!.translate('notifications'),
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 16.0),
          _buildSettingsCard(
            icon: Icons.email,
            title: AppLocalizations.of(context)!.translate('emailNotifications'),
            subtitle: AppLocalizations.of(context)!.translate('emailNotificationsDescription'),
            trailing: Switch(
              value: _emailNotifications,
              onChanged: (value) {
                setState(() {
                  _emailNotifications = value;
                });
              },
            ),
          ),
          const SizedBox(height: 8.0),
          _buildSettingsCard(
            icon: Icons.notifications,
            title: AppLocalizations.of(context)!.translate('pushNotifications'),
            subtitle: AppLocalizations.of(context)!.translate('pushNotificationsDescription'),
            trailing: Switch(
              value: _pushNotifications,
              onChanged: (value) {
                setState(() {
                  _pushNotifications = value;
                });
              },
            ),
          ),
          const SizedBox(height: 8.0),
          _buildSettingsCard(
            icon: Icons.shopping_cart,
            title: AppLocalizations.of(context)!.translate('salesNotifications'),
            subtitle: AppLocalizations.of(context)!.translate('salesNotificationsDescription'),
            trailing: Switch(
              value: _salesNotifications,
              onChanged: (value) {
                setState(() {
                  _salesNotifications = value;
                });
              },
            ),
          ),
          const SizedBox(height: 8.0),
          _buildSettingsCard(
            icon: Icons.update,
            title: AppLocalizations.of(context)!.translate('contentUpdates'),
            subtitle: AppLocalizations.of(context)!.translate('contentUpdatesDescription'),
            trailing: Switch(
              value: _contentUpdates,
              onChanged: (value) {
                setState(() {
                  _contentUpdates = value;
                });
              },
            ),
          ),
          const SizedBox(height: 32.0),
          
          // Save button
          CustomButton(
            text: AppLocalizations.of(context)!.translate('saveNotificationSettings'),
            icon: Icons.save,
            onPressed: _saveNotificationSettings,
          ),
        ],
      ),
    );
  }
  
  Widget _buildSettingsCard({
    required IconData icon,
    required String title,
    String? subtitle,
    required Widget trailing,
  }) {
    final theme = Theme.of(context);
    
    return Card(
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: trailing,
      ),
    );
  }
  
  Future<void> _showDeleteAccountDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.translate('deleteAccount')),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(AppLocalizations.of(context)!.translate('deleteAccountConfirmation')),
                const SizedBox(height: 8.0),
                Text(AppLocalizations.of(context)!.translate('deleteAccountWarning')),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(AppLocalizations.of(context)!.translate('cancel')),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                AppLocalizations.of(context)!.translate('delete'),
                style: const TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteAccount();
              },
            ),
          ],
        );
      },
    );
  }
  
  Future<void> _deleteAccount() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.deleteAccount();
      
      if (mounted) {
        context.go('/login');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.translate('deleteAccountFailed')}: ${e.toString()}'))
        );
      }
    }
  }
  
  Widget _buildLegalTab() {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.translate('legal'),
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 16.0),
          
          // Privacy Policy
          _buildSettingsCard(
            icon: Icons.privacy_tip,
            title: AppLocalizations.of(context)!.translate('privacyPolicy'),
            subtitle: AppLocalizations.of(context)!.translate('readPrivacyPolicy'),
            trailing: IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: () => context.push('/privacy'),
            ),
          ),
          const SizedBox(height: 8.0),
          
          // Terms of Service
          _buildSettingsCard(
            icon: Icons.policy,
            title: AppLocalizations.of(context)!.translate('termsOfService'),
            subtitle: AppLocalizations.of(context)!.translate('readTermsOfService'),
            trailing: IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: () => context.push('/terms'),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDeveloperTab() {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Performance Optimization Examples
          Text(
            'Performance Optimization',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 16.0),
          
          // Optimization Examples
          _buildSettingsCard(
            icon: Icons.speed,
            title: 'Performance Optimization Examples',
            subtitle: 'View examples of query optimization and asset compression',
            trailing: IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: () => context.push('/optimization-examples'),
            ),
          ),
          const SizedBox(height: 16.0),
          
          // Sync Service Demo
          _buildSettingsCard(
            icon: Icons.sync,
            title: 'Sync Service Demo',
            subtitle: 'Demonstrate online/offline data synchronization',
            trailing: IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: () => context.push('/sync-demo'),
            ),
          ),
          const SizedBox(height: 16.0),
          
          // Security Examples
          _buildSettingsCard(
            icon: Icons.security,
            title: 'Security Examples',
            subtitle: 'View examples of screenshot protection and other security features',
            trailing: IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: () => context.push('/security-examples'),
            ),
          ),
          const SizedBox(height: 24.0),
          
          // Firebase Testing Section
          Text(
            AppLocalizations.of(context)!.translate('firebaseTesting'),
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 16.0),
          
          // Crashlytics Testing
          _buildSettingsCard(
            icon: Icons.bug_report,
            title: AppLocalizations.of(context)!.translate('testCrashlytics'),
            subtitle: AppLocalizations.of(context)!.translate('testCrashlyticsDescription'),
            trailing: IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: () => FirebaseTest.testCrashlytics(context),
            ),
          ),
          const SizedBox(height: 8.0),
          
          // Force Crash Button (with warning)
          Card(
            color: theme.colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 8.0),
                      Text(
                        AppLocalizations.of(context)!.translate('dangerForceCrash'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    AppLocalizations.of(context)!.translate('forceCrashDescription'),
                  ),
                  const SizedBox(height: 16.0),
                  CustomButton(
                    text: AppLocalizations.of(context)!.translate('forceCrash'),
                    icon: Icons.dangerous,
                    backgroundColor: theme.colorScheme.error,
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(AppLocalizations.of(context)!.translate('forceCrashConfirmTitle')),
                          content: Text(
                            AppLocalizations.of(context)!.translate('forceCrashConfirmMessage')
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(AppLocalizations.of(context)!.translate('cancel')),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                FirebaseTest.forceCrash();
                              },
                              child: Text(
                                AppLocalizations.of(context)!.translate('crashApp'),
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}