import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import '../../models/content_model.dart';
import '../../services/content_service.dart';
import '../../services/auth_service.dart';
import '../../services/payment_service.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/recent_views_provider.dart';
import '../../widgets/content_preview_widget.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_message.dart';

class ContentDetailsScreen extends StatefulWidget {
  final String contentId;

  const ContentDetailsScreen({super.key, required this.contentId});

  @override
  State<ContentDetailsScreen> createState() => _ContentDetailsScreenState();
}

class _ContentDetailsScreenState extends State<ContentDetailsScreen> {
  late Future<ContentModel?> _contentFuture;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  void _loadContent() {
    final contentService = ContentService();
    _contentFuture = contentService.getContentById(widget.contentId);
    
    // Add to recent views
    final recentViewsProvider = Provider.of<RecentViewsProvider>(context, listen: false);
    recentViewsProvider.addRecentView(widget.contentId);
    
    // Check if content is in favorites using FavoritesProvider
    final favoritesProvider = Provider.of<FavoritesProvider>(context, listen: false);
    setState(() {
      _isFavorite = favoritesProvider.isFavorite(widget.contentId);
    });
    
    // Also check Firestore if user is logged in
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.currentUser != null) {
      contentService.isContentFavorited(
        authService.currentUser!.uid, 
        widget.contentId
      ).then((value) {
        if (mounted && value != _isFavorite) {
          // If there's a discrepancy between local and cloud, update local
          if (value) {
            favoritesProvider.addFavorite(widget.contentId);
          } else {
            favoritesProvider.removeFavorite(widget.contentId);
          }
          setState(() {
            _isFavorite = value;
          });
        }
      });
    }
  }

  void _toggleFavorite(String contentId) async {
    // Update local state immediately for responsive UI
    setState(() {
      _isFavorite = !_isFavorite;
    });
    
    try {
      // Use FavoritesProvider to update local cache
      final favoritesProvider = Provider.of<FavoritesProvider>(context, listen: false);
      
      if (_isFavorite) {
        await favoritesProvider.addFavorite(contentId);
      } else {
        await favoritesProvider.removeFavorite(contentId);
      }
      
      // Also update in Firestore if user is logged in
      final authService = Provider.of<AuthService>(context, listen: false);
      if (authService.currentUser != null) {
        final contentService = ContentService();
        final userId = authService.currentUser!.uid;
        
        if (_isFavorite) {
          await contentService.addToFavorites(userId, contentId);
        } else {
          await contentService.removeFromFavorites(userId, contentId);
        }
      }
    } catch (e) {
      // Revert state if operation fails
      if (mounted) {
        setState(() {
          _isFavorite = !_isFavorite;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  void _shareContent(ContentModel content) {
    final String shareText = 
        "Check out '${content.title}' on Digital Content Marketplace!";
    Share.share(shareText);
  }

  void _purchaseContent(ContentModel content) async {
    // Show payment method selection dialog
    final paymentMethod = await _showPaymentMethodDialog();
    if (paymentMethod == null) return; // User cancelled
    
    try {
      // Get the payment service to handle the purchase
      final paymentService = Provider.of<PaymentService>(context, listen: false);
      
      // Use the selected payment method
      if (paymentMethod == 'stripe') {
        await paymentService.purchaseWithStripe(content);
      } else {
        final contentService = Provider.of<ContentService>(context, listen: false);
        await contentService.purchaseContent(content.id);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Purchase successful! You now own this content.')),
      );
      
      // Refresh the screen to show updated purchase status
      setState(() {
        _contentFuture = Provider.of<ContentService>(context, listen: false)
            .getContentById(widget.contentId);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Purchase failed: ${e.toString()}')),
      );
    }
  }
  
  Future<String?> _showPaymentMethodDialog() async {
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Payment Method'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.shopping_bag),
                title: const Text('In-App Purchase'),
                onTap: () => Navigator.of(context).pop('inapp'),
              ),
              ListTile(
                leading: const Icon(Icons.credit_card),
                title: const Text('Credit Card (Stripe)'),
                onTap: () => Navigator.of(context).pop('stripe'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Content Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => FutureBuilder<ContentModel?>(
              future: _contentFuture,
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  _shareContent(snapshot.data!);
                }
                return Container();
              },
            ),
          ),
        ],
      ),
      body: FutureBuilder<ContentModel?>(
        future: _contentFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator();
          }
          
          if (snapshot.hasError) {
            return ErrorMessage(
              message: 'Error loading content: ${snapshot.error}',
              onRetry: _loadContent,
            );
          }
          
          if (!snapshot.hasData) {
            return const ErrorMessage(
              message: 'Content not found',
            );
          }
          
          final content = snapshot.data!;
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Content Preview
                ContentPreviewWidget(content: content),
                
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and Favorite Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              content.title,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              _isFavorite 
                                  ? Icons.favorite 
                                  : Icons.favorite_border,
                              color: _isFavorite ? Colors.red : null,
                            ),
                            onPressed: () => _toggleFavorite(content.id),
                          ),
                        ],
                      ),
                      
                      // Creator and Date
                      Row(
                        children: [
                          const Icon(Icons.person, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            content.sellerName.isNotEmpty 
                                ? content.sellerName 
                                : 'Unknown Creator',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(width: 16),
                          const Icon(Icons.calendar_today, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat.yMMMd().format(content.createdAt),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Price and Purchase Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            content.price > 0 
                                ? '\$${content.price.toStringAsFixed(2)}' 
                                : 'Free',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.shopping_cart),
                            label: const Text('Purchase'),
                            onPressed: () => _purchaseContent(content),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Description
                      Text(
                        'Description',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(content.description),
                      
                      const SizedBox(height: 24),
                      
                      // Stats
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(Icons.remove_red_eye, '${content.views}', 'Views'),
                          _buildStatItem(Icons.download, '${content.downloads}', 'Downloads'),
                          _buildStatItem(Icons.favorite, '${content.favorites}', 'Favorites'),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Tags
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: content.tags.map((tag) => Chip(
                          label: Text(tag),
                          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                        )).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}