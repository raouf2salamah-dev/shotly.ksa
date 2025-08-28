import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../models/content_model.dart';
import '../../services/auth_service.dart';
import '../../services/content_service.dart';
import '../../widgets/content_card.dart';
import '../../widgets/custom_button.dart';
import '../../l10n/app_localizations.dart';

class SellerHomeScreen extends StatefulWidget {
  const SellerHomeScreen({super.key});

  @override
  State<SellerHomeScreen> createState() => _SellerHomeScreenState();
}

class _SellerHomeScreenState extends State<SellerHomeScreen> {
  bool _isLoading = false;
  List<ContentModel> _myContent = [];
  
  @override
  void initState() {
    super.initState();
    _loadMyContent();
  }
  
  Future<void> _loadMyContent() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    
    try {
      // Use Provider.of with a null check to avoid null value errors
      final contentService = context.read<ContentService>();
      if (contentService != null) {
        final contents = await contentService.getMyContent();
        
        if (mounted) {
          setState(() {
            _myContent = contents;
            _isLoading = false;
          });
        }
      } else {
        // Handle null contentService
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        debugPrint('ContentService is null');
      }
    } catch (e) {
      debugPrint('Error loading content: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading content: ${e.toString()}'))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('User not logged in')),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.translate('SellerHomeScreen')),
        actions: [
          IconButton(
            icon: const Icon(Icons.smart_toy_outlined),
            tooltip: 'AI Assistant',
            onPressed: () => context.push('/seller/ai-assistant'),
          ),
          IconButton(
            icon: const Icon(Icons.cached_outlined),
            tooltip: 'Prompt Cache Demo',
            onPressed: () => context.push('/seller/prompt-cache-demo'),
          ),
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () => context.push('/seller/analytics'),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/seller/profile'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadMyContent,
        child: CustomScrollView(
          slivers: [
            // Earnings Summary
            SliverToBoxAdapter(
              child: _buildEarningsSummary(0.0, theme), // Placeholder until UserModel is properly implemented
            ),
            
            // My Content Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.translate('myContent'),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_myContent.length} ${AppLocalizations.of(context)!.translate('items')}',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Content Grid
            _isLoading
                ? const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _myContent.isEmpty
                    ? SliverFillRemaining(
                        child: _buildEmptyState(),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.all(16.0),
                        sliver: SliverMasonryGrid.count(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16.0,
                          crossAxisSpacing: 16.0,
                          childCount: _myContent.length,
                          itemBuilder: (context, index) {
                            final content = _myContent[index];
                            return ContentCard(
                              content: content,
                              onTap: () => context.push('/seller/content/${content.id}'),
                              showFavoriteButton: false,
                            );
                          },
                        ),
                      ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/seller/upload'),
        icon: const Icon(Icons.add),
        label: Text(AppLocalizations.of(context)!.translate('uploadContent')),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
    );
  }
  
  Widget _buildEarningsSummary(double earnings, ThemeData theme) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 10.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.translate('totalProfit'),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimary.withOpacity(0.9),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onPrimary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.trending_up,
                      size: 16.0,
                      color: theme.colorScheme.onPrimary,
                    ),
                    const SizedBox(width: 4.0),
                    Text(
                      AppLocalizations.of(context)!.translate('seller') ?? 'Seller',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          Text(
            currencyFormat.format(earnings),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onPrimary,
            ),
          ),
          const SizedBox(height: 16.0),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: AppLocalizations.of(context)!.translate('viewAnalytics'),
                  icon: Icons.analytics_outlined,
                  backgroundColor: theme.colorScheme.onPrimary.withOpacity(0.2),
                  textColor: theme.colorScheme.onPrimary,
                  onPressed: () => context.push('/seller/analytics'),
                ),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: CustomButton(
                  text: AppLocalizations.of(context)!.translate('withdraw'),
                  icon: Icons.account_balance_wallet_outlined,
                  backgroundColor: theme.colorScheme.onPrimary,
                  textColor: theme.colorScheme.primary,
                  onPressed: () => context.push('/seller/withdraw'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: AppLocalizations.of(context)!.translate('newAnalytics') ?? 'New Analytics',
                  icon: Icons.bar_chart,
                  backgroundColor: theme.colorScheme.secondary.withOpacity(0.8),
                  textColor: theme.colorScheme.onSecondary,
                  onPressed: () => context.push('/seller/analytics-page'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: 64.0,
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 16.0),
          Text(
            AppLocalizations.of(context)!.translate('noContentUploaded'),
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8.0),
          Text(
            AppLocalizations.of(context)!.translate('startUploadingContent'),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24.0),
          CustomButton(
            text: AppLocalizations.of(context)!.translate('uploadContent'),
            icon: Icons.add,
            onPressed: () => context.push('/seller/upload'),
          ),
        ],
      ),
    );
  }
}