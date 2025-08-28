import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../l10n/app_localizations.dart';

import '../../models/user_model.dart';

import '../../services/auth_service.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/settings_tile.dart';

class BuyerProfileScreen extends StatelessWidget {
  const BuyerProfileScreen({super.key});
  
  // Helper method to show profile image in full screen
  void _showProfileImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.zero,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.contain,
              placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
            // Close button
            Positioned(
              top: 16,
              right: 16,
              child: CircleAvatar(
                backgroundColor: Colors.black.withOpacity(0.5),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Helper method to build stat item
  Widget _buildStatItem(BuildContext context, String value, String label) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.translate('profile')),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to settings
              context.push('/settings');
            },
          ),
        ],
      ),
      body: user == null
          ? _buildNotLoggedIn(context)
          : _buildProfile(context, authService),
    );
  }

  Widget _buildNotLoggedIn(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.account_circle,
            size: 100,
            color: Colors.grey,
          ),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context)!.translate('notLoggedIn'),
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.go('/login');
            },
            child: Text(AppLocalizations.of(context)!.translate('signIn')),
          ),
        ],
      ),
    );
  }

  Widget _buildProfile(BuildContext context, AuthService authService) {
    final firebaseUser = authService.currentUser!;
    final theme = Theme.of(context);
    
    // We'll use the Firebase User for basic info
    // In a real app, you would fetch the UserModel from Firestore
    
    return SingleChildScrollView(
      child: Column(
        children: [
          // Profile header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary.withOpacity(0.2),
                  theme.colorScheme.primary.withOpacity(0.05),
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                ProfileAvatar(
                  radius: 50,
                  photoUrl: firebaseUser.photoURL,
                  name: firebaseUser.displayName ?? 'User',
                  onTap: () {
                    // Show profile image in full screen
                    if (firebaseUser.photoURL != null && firebaseUser.photoURL!.isNotEmpty) {
                      _showProfileImage(context, firebaseUser.photoURL!);
                    }
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  firebaseUser.displayName ?? 'User',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  firebaseUser.email ?? '',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.edit),
                      label: Text(AppLocalizations.of(context)!.translate('editProfile')),
                      onPressed: () {
                        // Navigate to edit profile
                        context.push('/buyer/edit-profile');
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // User Stats
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.translate('activity'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(context, '12', AppLocalizations.of(context)!.translate('purchases')),
                        _buildStatItem(context, '24', AppLocalizations.of(context)!.translate('favorites')),
                        _buildStatItem(context, '5', AppLocalizations.of(context)!.translate('reviews')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Account settings
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.account_circle, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.translate('account'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SettingsTile(
                      icon: Icons.shopping_bag,
                      title: AppLocalizations.of(context)!.translate('myPurchases'),
                      subtitle: AppLocalizations.of(context)!.translate('viewPurchasedContent'),
                      onTap: () {
                        // Navigate to purchases
                        context.push('/buyer/purchases');
                      },
                    ),
                    SettingsTile(
                      icon: Icons.favorite,
                      title: AppLocalizations.of(context)!.translate('myFavorites'),
                      subtitle: AppLocalizations.of(context)!.translate('contentYouSaved'),
                      onTap: () {
                        // Navigate to favorites
                        context.push('/buyer/favorites');
                      },
                    ),
                    SettingsTile(
                      icon: Icons.history,
                      title: AppLocalizations.of(context)!.translate('purchaseHistory'),
                      subtitle: AppLocalizations.of(context)!.translate('viewTransactionHistory'),
                      onTap: () {
                        // Navigate to purchase history
                        context.push('/buyer/purchase-history');
                      },
                    ),
                    SettingsTile(
                      icon: Icons.payment,
                      title: AppLocalizations.of(context)!.translate('paymentMethods'),
                      subtitle: AppLocalizations.of(context)!.translate('managePaymentOptions'),
                      onTap: () {
                        // Navigate to payment methods
                        context.push('/buyer/payment-methods');
                      },
                    ),
                
                  ],
                ),
              ),
            ),
          ),
          
          // Seller Tools
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.business_center, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.translate('sellerTools'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SettingsTile(
                      icon: Icons.storefront,
                      title: AppLocalizations.of(context)!.translate('switchToSellerMode'),
                      subtitle: AppLocalizations.of(context)!.translate('sellDigitalContent'),
                      iconColor: Colors.green,
                      onTap: () {
                        // Navigate to seller home
                        context.go('/seller');
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Support
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.support_agent, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.translate('support'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SettingsTile(
                      icon: Icons.help,
                      title: AppLocalizations.of(context)!.translate('helpCenter'),
                      subtitle: AppLocalizations.of(context)!.translate('faqsAndGuides'),
                      onTap: () {
                        // Navigate to help center
                        context.push('/help');
                      },
                    ),
                    SettingsTile(
                      icon: Icons.contact_support,
                      title: AppLocalizations.of(context)!.translate('contactSupport'),
                      subtitle: AppLocalizations.of(context)!.translate('getAssistanceWithIssues'),
                      onTap: () {
                        // Navigate to contact support
                        context.push('/contact');
                      },
                    ),
                    SettingsTile(
                      icon: Icons.policy,
                      title: AppLocalizations.of(context)!.translate('termsOfService'),
                      subtitle: AppLocalizations.of(context)!.translate('readTermsOfService'),
                      onTap: () {
                        // Navigate to terms of service
                        context.push('/terms');
                      },
                    ),
                    SettingsTile(
                      icon: Icons.privacy_tip,
                      title: AppLocalizations.of(context)!.translate('privacyPolicy'),
                      subtitle: AppLocalizations.of(context)!.translate('readPrivacyPolicy'),
                      onTap: () {
                        // Navigate to privacy policy
                        context.push('/privacy');
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
                
          // Logout
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: Text(AppLocalizations.of(context)!.translate('logOut')),
                onPressed: () {
                  // Show confirmation dialog
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(AppLocalizations.of(context)!.translate('logOut')),
                      content: Text(AppLocalizations.of(context)!.translate('logOutConfirmation')),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(AppLocalizations.of(context)!.translate('cancel')),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            await authService.signOut();
                            if (context.mounted) {
                              context.go('/login');
                            }
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: Text(AppLocalizations.of(context)!.translate('logOut')),
                        ),
                      ],
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(200, 50),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}