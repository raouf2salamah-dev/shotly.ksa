import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';

import '../../models/content_model.dart';
import '../../services/auth_service.dart';
import '../../services/content_service.dart';
import '../../providers/recent_views_provider.dart';
import '../../widgets/content_card.dart';

class RecentViewsScreen extends StatefulWidget {
  const RecentViewsScreen({Key? key}) : super(key: key);

  @override
  State<RecentViewsScreen> createState() => _RecentViewsScreenState();
}

class _RecentViewsScreenState extends State<RecentViewsScreen> {
  final List<ContentModel> _recentContent = [];
  bool _isLoading = false;
  ContentType? _selectedContentType;

  @override
  void initState() {
    super.initState();
    _loadRecentViews();
  }

  Future<void> _loadRecentViews() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final recentViewsProvider = Provider.of<RecentViewsProvider>(context, listen: false);
      final contentService = Provider.of<ContentService>(context, listen: false);
      
      // Get the list of recent view IDs
      final recentViewIds = recentViewsProvider.recentViews;
      
      // Clear the current list
      _recentContent.clear();
      
      // Load content details for each ID
      for (final id in recentViewIds) {
        try {
          final content = await contentService.getContentById(id);
          if (content != null) {
            _recentContent.add(content);
          }
        } catch (e) {
          // Skip content that can't be loaded
          debugPrint('Error loading content $id: $e');
        }
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading recent views: ${e.toString()}'))
        );
      }
    }
  }

  void _filterByType(ContentType? type) {
    setState(() {
      _selectedContentType = type;
    });
  }

  List<ContentModel> get _filteredContent {
    if (_selectedContentType == null) {
      return _recentContent;
    }
    return _recentContent.where((content) => content.contentType == _selectedContentType).toList();
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary,
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64.0,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16.0),
          Text(
            'No recently viewed content',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8.0),
          Text(
            'Content you view will appear here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recently Viewed'),
      ),
      body: Column(
        children: [
          // Filter chips
          Padding(
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
                : _recentContent.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadRecentViews,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: MasonryGridView.count(
                            crossAxisCount: 2,
                            mainAxisSpacing: 8.0,
                            crossAxisSpacing: 8.0,
                            itemCount: _filteredContent.length,
                            itemBuilder: (context, index) {
                              final content = _filteredContent[index];
                              return ContentCard(
                                content: content,
                                onTap: () => context.push('/buyer/content/${content.id}'),
                                showFavoriteButton: true,
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
}