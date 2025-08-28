import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';

import '../../models/content_model.dart';
import '../../services/auth_service.dart';
import '../../services/content_service.dart';
import '../../providers/favorites_provider.dart';
import '../../widgets/content_card.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  bool _isLoading = false;
  List<ContentModel> _favoriteContent = [];
  ContentType? _selectedContentType;
  
  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }
  
  Future<void> _loadFavorites() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.currentUser == null) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // First get the product IDs from our local cache using FavoritesProvider
      final favoritesProvider = Provider.of<FavoritesProvider>(context, listen: false);
      final favoriteIds = favoritesProvider.favorites;
      
      if (favoriteIds.isEmpty) {
        setState(() {
          _favoriteContent = [];
          _isLoading = false;
        });
        return;
      }
      
      // Then fetch the content details from ContentService
      final contentService = Provider.of<ContentService>(context, listen: false);
      final List<ContentModel> contentList = [];
      
      for (final id in favoriteIds) {
        try {
          final content = await contentService.getContentById(id);
          if (content != null) {
            // Apply content type filter if specified
            if (_selectedContentType == null || content.contentType == _selectedContentType) {
              // Filter to only show images, videos, and GIFs
              if (content.contentType == ContentType.image || 
                  content.contentType == ContentType.video || 
                  content.contentType == ContentType.gif) {
                contentList.add(content);
              }
            }
          }
        } catch (e) {
          // Skip content that can't be loaded
          debugPrint('Error loading content $id: $e');
        }
      }
      
      setState(() {
        _favoriteContent = contentList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading favorites: ${e.toString()}'))
        );
      }
    }
  }
  
  void _filterByType(ContentType? type) {
    setState(() {
      _selectedContentType = type == _selectedContentType ? null : type;
    });
    _loadFavorites();
  }
  
  void _removeFromFavorites(String contentId) async {
    try {
      // Use FavoritesProvider to remove from local cache
      final favoritesProvider = Provider.of<FavoritesProvider>(context, listen: false);
      await favoritesProvider.removeFavorite(contentId);
      
      // Also update Firestore if user is logged in
      final authService = Provider.of<AuthService>(context, listen: false);
      if (authService.currentUser != null) {
        final contentService = Provider.of<ContentService>(context, listen: false);
        await contentService.toggleFavorite(
          contentId: contentId,
          userId: authService.currentUser!.uid,
        );
      }
      
      // Remove from local list
      setState(() {
        _favoriteContent.removeWhere((content) => content.id == contentId);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from favorites'))
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing from favorites: ${e.toString()}'))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = Provider.of<AuthService>(context);
    
    if (authService.currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Media Favorites'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite_border,
                size: 64.0,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              const SizedBox(height: 16.0),
              Text(
                'Sign in to view your favorites',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: () => context.go('/login'),
                child: const Text('Sign In'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Media Favorites'),
      ),
      body: Column(
        children: [
          // Content Type Filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'All',
                  isSelected: _selectedContentType == null,
                  onTap: () => _filterByType(null),
                ),
                const SizedBox(width: 8.0),
                _buildFilterChip(
                  label: 'Images',
                  isSelected: _selectedContentType == ContentType.image,
                  onTap: () => _filterByType(ContentType.image),
                ),
                const SizedBox(width: 8.0),
                _buildFilterChip(
                  label: 'Videos',
                  isSelected: _selectedContentType == ContentType.video,
                  onTap: () => _filterByType(ContentType.video),
                ),
                const SizedBox(width: 8.0),
                _buildFilterChip(
                  label: 'GIF',
                  isSelected: _selectedContentType == ContentType.gif,
                  onTap: () => _filterByType(ContentType.gif),
                ),
              ],
            ),
          ),
          
          // Content Grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _favoriteContent.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadFavorites,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: MasonryGridView.count(
                            crossAxisCount: 2,
                            mainAxisSpacing: 8.0,
                            crossAxisSpacing: 8.0,
                            itemCount: _favoriteContent.length,
                            itemBuilder: (context, index) {
                              final content = _favoriteContent[index];
                              return Dismissible(
                                key: Key(content.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20.0),
                                  color: Colors.red,
                                  child: const Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                  ),
                                ),
                                onDismissed: (direction) {
                                  _removeFromFavorites(content.id);
                                },
                                child: ContentCard(
                                  content: content,
                                  onTap: () => context.push('/buyer/content/${content.id}'),
                                  showFavoriteButton: true,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.brightness == Brightness.light
                  ? Colors.grey.shade200
                  : Colors.grey.shade800,
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
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
            Icons.favorite_border,
            size: 64.0,
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 16.0),
          Text(
            _selectedContentType != null
                ? 'No ${ContentTypeExtension.getDisplayName(_selectedContentType!).toLowerCase()} favorites yet'
                : 'No favorites yet',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8.0),
          Text(
            'Tap the heart icon on images, videos, or GIFs you like to add them to your favorites',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}