import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/user_model.dart';
import '../../models/content_model.dart';
import '../../services/auth_service.dart';
import '../../services/content_service.dart';
import '../../widgets/custom_button.dart';
import '../../l10n/app_localizations.dart';

class SellerProfileScreen extends StatefulWidget {
  const SellerProfileScreen({super.key});

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  UserModel? _user;
  List<ContentModel> _uploadedContent = [];
  double _totalEarnings = 0;
  int _totalSales = 0;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final contentService = Provider.of<ContentService>(context, listen: false);
      final firestore = FirebaseFirestore.instance;
      
      final firebaseUser = authService.currentUser;
      if (firebaseUser == null) {
        throw Exception('User not authenticated');
      }
      
      // Get user data from Firestore
      final userDoc = await firestore.collection('users').doc(firebaseUser.uid).get();
      final userModel = UserModel.fromMap(userDoc.data() ?? {}, firebaseUser.uid);
      
      final uploadedContent = await contentService.getMyContent();
      final analytics = await contentService.getSellerAnalytics(period: 'all');
      
      setState(() {
        _user = userModel;
        _uploadedContent = uploadedContent;
        _totalEarnings = analytics['totalEarnings'] ?? 0;
        _totalSales = analytics['totalSales'] ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile data: ${e.toString()}'))
        );
      }
    }
  }
  
  Future<void> _signOut() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signOut();
      
      if (mounted) {
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to sign out: ${e.toString()}'))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.translate('sellerProfile')),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              context.push('/settings');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Profile header
                _buildProfileHeader(),
                
                // Tabs
                TabBar(
                  controller: _tabController,
                  tabs: [
                    Tab(text: AppLocalizations.of(context)!.translate('uploadedContent')),
                    Tab(text: AppLocalizations.of(context)!.translate('account')),
                  ],
                ),
                
                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildUploadedContentTab(),
                      _buildAccountTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
  
  Widget _buildProfileHeader() {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Profile image
          CircleAvatar(
            radius: 50.0,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            child: _user?.profileImageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(50.0),
                    child: CachedNetworkImage(
                      imageUrl: _user!.profileImageUrl!,
                      width: 100.0,
                      height: 100.0,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const CircularProgressIndicator(),
                      errorWidget: (context, url, error) => Icon(
                        Icons.person,
                        size: 50.0,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  )
                : Icon(
                    Icons.person,
                    size: 50.0,
                    color: theme.colorScheme.primary,
                  ),
          ),
          const SizedBox(height: 16.0),
          
          // User name
          Text(
            _user?.name ?? 'Seller',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4.0),
          
          // User email
          Text(
            _user?.email ?? '',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16.0),
          
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatColumn(AppLocalizations.of(context)!.translate('content'), _uploadedContent.length.toString()),
              _buildStatColumn(AppLocalizations.of(context)!.translate('sales'), _totalSales.toString()),
              _buildStatColumn(AppLocalizations.of(context)!.translate('earnings'), '\$${_totalEarnings.toStringAsFixed(2)}'),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatColumn(String label, String value) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
  
  Widget _buildUploadedContentTab() {
    final theme = Theme.of(context);
    
    if (_uploadedContent.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_upload,
              size: 64.0,
              color: theme.colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16.0),
            Text(
              'No content uploaded yet',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 24.0),
            CustomButton(
              text: 'Upload Content',
              icon: Icons.add,
              onPressed: () {
                context.push('/seller/upload');
              },
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _uploadedContent.length,
      itemBuilder: (context, index) {
        final content = _uploadedContent[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16.0),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: CachedNetworkImage(
                imageUrl: content.thumbnailUrl ?? '',
                width: 50.0,
                height: 50.0,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 50.0,
                  height: 50.0,
                  color: Colors.grey.shade300,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 50.0,
                  height: 50.0,
                  color: Colors.grey.shade300,
                  child: Icon(
                    _getContentTypeIcon(content.contentType),
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ),
            title: Text(content.title),
            subtitle: Text(
              '\$${content.price.toStringAsFixed(2)} · ${content.contentType.name}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    context.push('/seller/edit/${content.id}');
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    _showDeleteConfirmationDialog(content);
                  },
                ),
              ],
            ),
            onTap: () {
              context.push('/seller/content/${content.id}');
            },
          ),
        );
      },
    );
  }
  
  Widget _buildAccountTab() {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Account settings
          Text(
            'Account Settings',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 16.0),
          _buildSettingsCard(
            icon: Icons.person,
            title: 'Edit Profile',
            subtitle: 'Update your name, profile picture',
            onTap: () {
              context.push('/settings/profile');
            },
          ),
          const SizedBox(height: 12.0),
          _buildSettingsCard(
            icon: Icons.lock,
            title: 'Change Password',
            subtitle: 'Update your password',
            onTap: () {
              context.push('/settings/password');
            },
          ),
          const SizedBox(height: 12.0),
          _buildSettingsCard(
            icon: Icons.payment,
            title: 'Payment Settings',
            subtitle: 'Manage payment methods and payout options',
            onTap: () {
              context.push('/settings/payment');
            },
          ),
          const SizedBox(height: 12.0),
          _buildSettingsCard(
            icon: Icons.notifications,
            title: 'Notification Settings',
            subtitle: 'Manage your notification preferences',
            onTap: () {
              context.push('/settings/notifications');
            },
          ),
          
          // Support
          const SizedBox(height: 32.0),
          Text(
            'Support',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 16.0),
          _buildSettingsCard(
            icon: Icons.help,
            title: 'Help Center',
            subtitle: 'Get help with your account',
            onTap: () {
              context.push('/help');
            },
          ),
          const SizedBox(height: 12.0),
          Column(
            children: [
              _buildSettingsCard(
                icon: Icons.policy,
                title: 'Terms of Service',
                subtitle: 'Read our terms of service',
                onTap: () {
                  context.push('/terms');
                },
              ),
              const SizedBox(height: 12.0),
              _buildSettingsCard(
                icon: Icons.privacy_tip,
                title: 'Privacy Policy',
                subtitle: 'Read our privacy policy',
                onTap: () {
                  context.push('/privacy');
                },
              ),
            ],
          ),
          
          // Sign out
          const SizedBox(height: 32.0),
          CustomButton(
            text: 'Sign Out',
            icon: Icons.logout,
            isOutlined: true,
            onPressed: _signOut,
          ),
        ],
      ),
    );
  }
  
  Widget _buildSettingsCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return Card(
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
  
  Future<void> _showDeleteConfirmationDialog(ContentModel content) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Content'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to delete "${content.title}"?'),
                const SizedBox(height: 8.0),
                const Text('This action cannot be undone.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteContent(content);
              },
            ),
          ],
        );
      },
    );
  }
  
  Future<void> _deleteContent(ContentModel content) async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final contentService = Provider.of<ContentService>(context, listen: false);
      await contentService.deleteContent(content.id);
      
      setState(() {
        _uploadedContent.removeWhere((item) => item.id == content.id);
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Content deleted successfully'))
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete content: ${e.toString()}'))
        );
      }
    }
  }
  
  IconData _getContentTypeIcon(ContentType type) {
    switch (type) {
      case ContentType.image:
        return Icons.image;
      case ContentType.video:
        return Icons.videocam;
      case ContentType.gif:
        return Icons.gif;
    }
  }
}