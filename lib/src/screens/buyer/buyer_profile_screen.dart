import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';

import '../../models/content_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/content_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/content_card.dart';

class BuyerProfileScreen extends StatefulWidget {
  const BuyerProfileScreen({super.key});

  @override
  State<BuyerProfileScreen> createState() => _BuyerProfileScreenState();
}

class _BuyerProfileScreenState extends State<BuyerProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<ContentModel> _purchasedContent = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPurchasedContent();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadPurchasedContent() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    
    try {
      final contentService = Provider.of<ContentService>(context, listen: false);
      final contents = await contentService.getPurchasedContent();
      
      if (mounted) {
        setState(() {
          _purchasedContent = contents;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading purchases: ${e.toString()}'))
        );
      }
    }
  }
  
  Future<void> _handleSignOut() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signOut();
      
      if (mounted) {
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: ${e.toString()}'))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('User not logged in')),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.translate('profile')),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/buyer/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          // User Info Card
          _buildUserInfoCard(user, theme),
          
          // Tabs
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: AppLocalizations.of(context)!.translate('purchases')),
              Tab(text: AppLocalizations.of(context)!.translate('favorites')),
            ],
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.7),
            indicatorColor: theme.colorScheme.primary,
          ),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Purchases Tab
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _purchasedContent.isEmpty
                        ? _buildEmptyState(
                            icon: Icons.shopping_bag_outlined,
                            title: AppLocalizations.of(context)!.translate('noPurchasesYet'),
                            description: AppLocalizations.of(context)!.translate('purchasedContentWillAppear'),
                          )
                        : _buildContentGrid(_purchasedContent),
                
                // Favorites Tab
                FutureBuilder<List<ContentModel>>(
                  future: Provider.of<ContentService>(context).getFavoriteContent(
                    userId: user.uid,
                    contentType: null,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return _buildEmptyState(
                        icon: Icons.favorite_border,
                        title: AppLocalizations.of(context)!.translate('noFavoritesYet'),
                        description: AppLocalizations.of(context)!.translate('favoritedContentWillAppear'),
                      );
                    } else {
                      return _buildContentGrid(snapshot.data!);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildUserInfoCard(User user, ThemeData theme) {
    final dateFormat = DateFormat.yMMMd();
    final displayName = user.displayName ?? '';
    final email = user.email ?? '';
    final createdAt = user.metadata.creationTime ?? DateTime.now();
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 10.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar and Name
          Row(
            children: [
              CircleAvatar(
                radius: 32.0,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                child: Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 32.0,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      email,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          
          // User Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.shopping_bag_outlined,
                value: '0', // We don't have purchases count from Firebase User
                label: AppLocalizations.of(context)!.translate('purchases'),
              ),
              _buildStatItem(
                icon: Icons.favorite_border,
                value: '0', // We don't have favorites count from Firebase User
                label: AppLocalizations.of(context)!.translate('favorites'),
              ),
              _buildStatItem(
                icon: Icons.calendar_today,
                value: dateFormat.format(createdAt),
                label: AppLocalizations.of(context)!.translate('joined'),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          
          // Sign Out Button
          CustomButton(
            text: AppLocalizations.of(context)!.translate('signOut'),
            icon: Icons.logout,
            isOutlined: true,
            onPressed: _handleSignOut,
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Icon(
          icon,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 4.0),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
  
  Widget _buildContentGrid(List<ContentModel> contents) {
    return RefreshIndicator(
      onRefresh: _loadPurchasedContent,
      child: GridView.builder(
        padding: const EdgeInsets.all(16.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
        ),
        itemCount: contents.length,
        itemBuilder: (context, index) {
          final content = contents[index];
          return ContentCard(
            content: content,
            onTap: () => context.push('/buyer/content/${content.id}'),
          );
        },
      ),
    );
  }
  
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64.0,
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 16.0),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8.0),
          Text(
            description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24.0),
          CustomButton(
            text: AppLocalizations.of(context)!.translate('exploreContent'),
            icon: Icons.search,
            onPressed: () => context.go('/buyer'),
          ),
        ],
      ),
    );
  }
}