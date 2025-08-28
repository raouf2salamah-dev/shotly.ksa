import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/content_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/content_service.dart';
import '../providers/favorites_provider.dart';

class ContentCard extends StatelessWidget {
  final ContentModel content;
  final VoidCallback onTap;
  final bool showFavoriteButton;

  const ContentCard({
    super.key,
    required this.content,
    required this.onTap,
    this.showFavoriteButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = Provider.of<AuthService>(context);
    final contentService = Provider.of<ContentService>(context);
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    // Check if content is in user's favorites using FavoritesProvider
    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    final isFavorite = favoritesProvider.isFavorite(content.id);
    
    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        elevation: 2.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Content Preview
            Stack(
              children: [
                // Content Thumbnail
                AspectRatio(
                  aspectRatio: content.contentType == ContentType.video ? 16 / 9 : 1,
                  child: _buildContentPreview(),
                ),
                
                // Content Type Badge
                Positioned(
                  top: 8.0,
                  left: 8.0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12.0),
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
                          content.contentType.name.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Favorite Button
                if (showFavoriteButton && authService.isBuyer)
                  Positioned(
                    top: 8.0,
                    right: 8.0,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          try {
                            final favoritesProvider = Provider.of<FavoritesProvider>(context, listen: false);
                            
                            // Toggle in local cache first
                            if (favoritesProvider.isFavorite(content.id)) {
                              await favoritesProvider.removeFavorite(content.id);
                            } else {
                              await favoritesProvider.addFavorite(content.id);
                            }
                            
                            // Also update in Firestore if user is logged in
                            if (authService.currentUser != null) {
                              final userId = authService.currentUser!.uid;
                              await contentService.toggleFavorite(
                                contentId: content.id,
                                userId: userId,
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString())),
                              );
                            }
                          }
                        },
                        borderRadius: BorderRadius.circular(20.0),
                        child: Container(
                          padding: const EdgeInsets.all(6.0),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface.withOpacity(0.8),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            size: 20.0,
                            color: isFavorite ? Colors.red : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            
            // Content Info
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    content.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4.0),
                  
                  // Price
                  Text(
                    currencyFormat.format(content.price),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  
                  // Creator Info
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 12.0,
                        child: Icon(Icons.person, size: 16.0),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: Text(
                          content.sellerName,
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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
    switch (content.contentType) {
      case ContentType.image:
        return CachedNetworkImage(
          imageUrl: content.thumbnailUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
          errorWidget: (context, url, error) => const Center(child: Icon(Icons.error)),
        );
      case ContentType.gif:
        return CachedNetworkImage(
          imageUrl: content.thumbnailUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
          errorWidget: (context, url, error) => const Center(child: Icon(Icons.error)),
        );
      case ContentType.video:
        return Stack(
          alignment: Alignment.center,
          children: [
            CachedNetworkImage(
              imageUrl: content.thumbnailUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) => const Center(child: Icon(Icons.error)),
            ),
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 32.0,
              ),
            ),
          ],
        );
      default:
        return CachedNetworkImage(
          imageUrl: content.thumbnailUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
          errorWidget: (context, url, error) => const Center(child: Icon(Icons.error)),
        );
    }
  }
  
  IconData _getContentTypeIcon() {
    switch (content.contentType) {
      case ContentType.image:
        return Icons.image;
      case ContentType.gif:
        return Icons.gif;
      case ContentType.video:
        return Icons.videocam;
    }
  }
}