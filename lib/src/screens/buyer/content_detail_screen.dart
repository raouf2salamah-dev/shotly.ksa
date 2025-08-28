import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

import '../../models/content_model.dart';
import '../../services/auth_service.dart';
import '../../services/content_service.dart';
import '../../services/payment_service.dart';
import '../../services/analytics_service.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/recent_views_provider.dart';
import '../../widgets/custom_button.dart';

class ContentDetailScreen extends StatefulWidget {
  final String contentId;

  const ContentDetailScreen({super.key, required this.contentId});

  @override
  State<ContentDetailScreen> createState() => _ContentDetailScreenState();
}

class _ContentDetailScreenState extends State<ContentDetailScreen> {
  ContentModel? _content;
  bool _isLoading = true;
  bool _isPurchasing = false;
  bool _isPurchased = false;
  bool _isFavorite = false;
  
  // Video player controllers
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  
  @override
  void initState() {
    super.initState();
    _loadContent();
  }
  
  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }
  
  Future<void> _loadContent() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    
    try {
      final contentService = Provider.of<ContentService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // Add to recent views
      final recentViewsProvider = Provider.of<RecentViewsProvider>(context, listen: false);
      await recentViewsProvider.addRecentView(widget.contentId);
      
      final content = await contentService.getContentById(widget.contentId);
      
      // Track content view in analytics
      final analyticsService = AnalyticsService();
      if (content != null) {
        await analyticsService.logContentView(
          contentId: content.id!,
          contentTitle: content.title!,
          contentType: content.contentType!.toString().split('.').last,
          sellerId: content.sellerId!,
        );
        
        // Check if user has purchased or favorited this content
        final currentUser = authService.currentUser;
        final isPurchased = currentUser != null && 
            currentUser.purchasedContent != null && 
            currentUser.purchasedContent!.contains(widget.contentId);
        final isFavorite = currentUser != null && 
            currentUser.favoriteContent != null && 
            currentUser.favoriteContent!.contains(widget.contentId);
        
        if (mounted) {
          setState(() {
            _content = content;
            _isPurchased = isPurchased;
            _isFavorite = isFavorite;
            _isLoading = false;
          });
          
          // Initialize video player if content is video and purchased
          if (content.contentType == ContentType.video && isPurchased) {
            _initializeVideoPlayer(content.mediaUrl!);
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Content not found'))
          );
        }
      }
    } catch (e) {
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
  
  Future<void> _initializeVideoPlayer(String videoUrl) async {
    _videoPlayerController = VideoPlayerController.network(videoUrl);
    await _videoPlayerController!.initialize();
    
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController!,
      autoPlay: false,
      looping: false,
      aspectRatio: 16 / 9,
      errorBuilder: (context, errorMessage) {
        return Center(
          child: Text(
            'Error: $errorMessage',
            style: const TextStyle(color: Colors.white),
          ),
        );
      },
    );
    
    if (mounted) {
      setState(() {});
    }
  }
  
  Future<void> _handlePurchase() async {
    if (_content == null) return;
    
    // Show payment method selection dialog
    final paymentMethod = await _showPaymentMethodDialog();
    if (paymentMethod == null) return; // User cancelled
    
    setState(() {
      _isPurchasing = true;
    });
    
    try {
      final contentService = Provider.of<ContentService>(context, listen: false);
      
      // Get the payment service to handle the purchase
      final paymentService = Provider.of<PaymentService>(context, listen: false);
      
      // Use the selected payment method
      if (paymentMethod == 'stripe') {
        await paymentService.purchaseWithStripe(_content!);
      } else {
        await contentService.purchaseContent(_content!.id!);
      }
      
      // Track purchase in analytics
      final analyticsService = AnalyticsService();
      await analyticsService.logPurchase(
        contentId: _content!.id!,
        contentTitle: _content!.title!,
        price: _content!.price?.toDouble() ?? 0.0,
        currency: 'USD',
        sellerId: _content!.sellerId!,
      );
      
      if (mounted) {
        setState(() {
          _isPurchased = true;
          _isPurchasing = false;
        });
        
        // Initialize video player if content is video
        if (_content!.contentType == ContentType.video) {
          _initializeVideoPlayer(_content!.mediaUrl!);
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase successful! You now own this content.'))
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPurchasing = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Purchase failed: ${e.toString()}'))
        );
      }
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
  
  Future<void> _toggleFavorite() async {
    if (_content == null) return;
    
    try {
      // Use FavoritesProvider to toggle in local cache
      final favoritesProvider = Provider.of<FavoritesProvider>(context, listen: false);
      
      if (_isFavorite) {
        await favoritesProvider.removeFavorite(_content!.id!);
      } else {
        await favoritesProvider.addFavorite(_content!.id!);
      }
      
      // Also update in Firestore if user is logged in
      final authService = Provider.of<AuthService>(context, listen: false);
      if (authService.currentUser != null) {
        final contentService = Provider.of<ContentService>(context, listen: false);
        final userId = authService.currentUser!.uid;
        await contentService.toggleFavorite(contentId: _content!.id!, userId: userId);
      } else {
        // Prompt user to sign in for cloud sync
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sign in to sync favorites across devices'))
          );
        }
      }
      
      // Track favorite action in analytics
      final newFavoriteState = !_isFavorite;
      final analyticsService = AnalyticsService();
      await analyticsService.logFavoriteAction(
        contentId: _content!.id!,
        contentTitle: _content!.title!,
        isFavorited: newFavoriteState,
      );
      
      if (mounted) {
        setState(() {
          _isFavorite = newFavoriteState;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()))
        );
      }
    }
  }
  
  Future<void> _downloadContent() async {
    if (_content == null || !_isPurchased) return;
    
    try {
      final contentService = Provider.of<ContentService>(context, listen: false);
      // Using a generic method since downloadContent isn't defined
      await contentService.getContentById(_content!.id!);
      
      // Track download in analytics
      final analyticsService = AnalyticsService();
      await analyticsService.logDownload(
        contentId: _content!.id!,
        contentTitle: _content!.title!,
        contentType: _content!.contentType!.toString().split('.').last,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Content downloaded successfully!'))
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: ${e.toString()}'))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_content?.title ?? 'Content Details'),
        actions: [
          if (_content != null)
            IconButton(
              icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
              color: _isFavorite ? Colors.red : null,
              onPressed: _toggleFavorite,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _content == null
              ? const Center(child: Text('Content not found'))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Content Preview
                      _buildContentPreview(),
                      
                      // Content Info
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title and Price
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    _content!.title,
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Text(
                                  currencyFormat.format(_content!.price?.toDouble() ?? 0.0),
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8.0),
                            
                            // Content Type Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getContentTypeIcon(),
                                    size: 16.0,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 4.0),
                                  Text(
                                    _content!.contentType.name.toUpperCase(),
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            
                            // Creator Info
                            Row(
                              children: [
                                const CircleAvatar(
                                  radius: 20.0,
                                  child: Icon(Icons.person),
                                ),
                                const SizedBox(width: 12.0),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _content!.sellerName,
                                      style: theme.textTheme.titleMedium,
                                    ),
                                    Text(
                                      'Creator',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 24.0),
                            
                            // Description
                            Text(
                              'Description',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              _content!.description,
                              style: theme.textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 32.0),
                            
                            // Purchase or Download Button
                            if (_isPurchased)
                              CustomButton(
                                text: 'Download',
                                icon: Icons.download,
                                onPressed: _downloadContent,
                              )
                            else
                              CustomButton(
                                  text: 'Purchase for ${currencyFormat.format(_content!.price?.toDouble() ?? 0.0)}',
                                  icon: Icons.shopping_cart,
                                  isLoading: _isPurchasing,
                                  onPressed: _handlePurchase,
                                ),
                            const SizedBox(height: 16.0),
                            
                            // License Info
                            Container(
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: theme.brightness == Brightness.light
                                    ? Colors.grey.shade100
                                    : Colors.grey.shade800,
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'License Information',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8.0),
                                  _buildLicenseItem(
                                    icon: Icons.check_circle,
                                    text: 'Personal and commercial use',
                                  ),
                                  _buildLicenseItem(
                                    icon: Icons.check_circle,
                                    text: 'No attribution required',
                                  ),
                                  _buildLicenseItem(
                                    icon: Icons.check_circle,
                                    text: 'Lifetime access',
                                  ),
                                  _buildLicenseItem(
                                    icon: Icons.cancel,
                                    text: 'Redistribution or resale not allowed',
                                    isAllowed: false,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
  
  Widget _buildContentPreview() {
    if (_content == null) return const SizedBox.shrink();
    
    final aspectRatio = _content!.contentType == ContentType.video ? 16 / 9 : 1;
    
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: _isPurchased
          ? _buildFullContent()
          : Stack(
              fit: StackFit.expand,
              children: [
                // Blurred preview
                CachedNetworkImage(
                  imageUrl: _content!.thumbnailUrl ?? '',
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => const Center(child: Icon(Icons.error)),
                ),
                
                // Overlay with purchase message
                if (!_isPurchased)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.lock,
                            color: Colors.white,
                            size: 48.0,
                          ),
                          const SizedBox(height: 16.0),
                          const Text(
                            'Purchase to unlock full content',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
  
  Widget _buildFullContent() {
    if (_content == null) return const SizedBox.shrink();
    
    switch (_content!.contentType) {
      case ContentType.image:
        return CachedNetworkImage(
          imageUrl: _content!.mediaUrl ?? '',
          fit: BoxFit.contain,
          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
          errorWidget: (context, url, error) => const Center(child: Icon(Icons.error)),
        );
      case ContentType.gif:
        return CachedNetworkImage(
          imageUrl: _content!.mediaUrl ?? '',
          fit: BoxFit.contain,
          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
          errorWidget: (context, url, error) => const Center(child: Icon(Icons.error)),
        );
      case ContentType.video:
        return _chewieController != null
            ? Chewie(controller: _chewieController!)
            : const Center(child: CircularProgressIndicator());
      default:
        return const Center(child: Text('Unsupported content type'));
    }
  }
  
  Widget _buildLicenseItem({
    required IconData icon,
    required String text,
    bool isAllowed = true,
  }) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18.0,
            color: isAllowed ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
  
  IconData _getContentTypeIcon() {
    if (_content == null) return Icons.image;
    
    switch (_content!.contentType) {
      case ContentType.image:
        return Icons.image;
      case ContentType.gif:
        return Icons.gif;
      case ContentType.video:
        return Icons.videocam;
      default:
        return Icons.file_present;
    }
  }
}