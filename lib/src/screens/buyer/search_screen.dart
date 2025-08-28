import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';

import '../../models/content_model.dart';
import '../../services/search_service.dart';
import '../../services/analytics_service.dart';
import '../../utils/loading_state.dart';
import '../../utils/network_utils.dart';
import '../../widgets/content_card.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_message.dart';
import '../../widgets/search_bar_widget.dart';
import '../../widgets/search_filter_widget.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  bool _isLoading = false;
  String _currentQuery = '';
  
  @override
  void initState() {
    super.initState();
    _initializeSearchService();
  }
  
  void _initializeSearchService() {
    // Initialize the search service with default values
    final searchService = Provider.of<SearchService>(context, listen: false);
    searchService.clearFilters();
  }
  
  void _handleSearch(String query) {
    setState(() {
      _currentQuery = query;
    });
    
    NetworkUtils.executeWithErrorHandling<void>(
      context,
      operation: () async {
        final searchService = Provider.of<SearchService>(context, listen: false);
        await searchService.searchContent(query);
        
        // Track search in analytics
        final analyticsService = AnalyticsService();
        final contentType = searchService.selectedContentType;
        final category = searchService.selectedCategory;
        await analyticsService.logSearch(
          searchTerm: query,
          contentType: contentType != null ? ContentTypeExtension.getDisplayName(contentType) : null,
          category: category,
        );
      },
      setLoading: (isLoading) {
        setState(() {
          _isLoading = isLoading;
        });
      },
      onSuccess: (_) {},
      errorMessage: 'Error searching content',
      showRetry: true,
      retryOperation: () => _handleSearch(query),
    );
  }
  
  void _applyFilters() {
    final searchService = Provider.of<SearchService>(context, listen: false);
    
    NetworkUtils.executeWithErrorHandling<void>(
      context,
      operation: () {
        if (_currentQuery.isNotEmpty) {
          return searchService.searchContent(_currentQuery);
        } else {
          return searchService.getRecentContent();
        }
      },
      setLoading: (isLoading) {
        setState(() {
          _isLoading = isLoading;
        });
      },
      onSuccess: (_) {},
      errorMessage: 'Error applying filters',
      showRetry: true,
      retryOperation: _applyFilters,
    );
  }
  
  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: SearchFilterWidget(
            onApplyFilters: _applyFilters,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchService = Provider.of<SearchService>(context);
    final theme = Theme.of(context);
    
    // Check if any filters are applied
    final hasFilters = searchService.selectedContentType != null ||
        searchService.selectedCategory != null ||
        searchService.priceRange != PriceRange.all ||
        searchService.sortOption != SortOption.newest;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Content'),
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: hasFilters ? theme.colorScheme.primary : null,
            ),
            onPressed: _showFilterBottomSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          SearchBarWidget(
            onSearch: _handleSearch,
            onFilterApplied: _applyFilters,
          ),
          
          // Applied Filters
          if (hasFilters)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Text(
                    'Applied Filters:',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  if (searchService.selectedContentType != null)
                    _buildFilterTag(
                      label: ContentTypeExtension.getDisplayName(searchService.selectedContentType!),
                    ),
                  if (searchService.selectedCategory != null)
                    _buildFilterTag(
                      label: searchService.selectedCategory!,
                    ),
                  if (searchService.priceRange != PriceRange.all)
                    _buildFilterTag(
                      label: _getPriceRangeLabel(searchService.priceRange),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      searchService.clearFilters();
                      _applyFilters();
                    },
                    child: const Text('Clear All'),
                  ),
                ],
              ),
            ),
          
          // Content Results
          Expanded(
            child: _isLoading
                ? const LoadingIndicator(message: 'Searching...')
                : searchService.searchResults.isEmpty
                    ? _buildEmptyState(searchService.isSearching)
                    : RefreshIndicator(
                        onRefresh: () async {
                          _applyFilters();
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: MasonryGridView.count(
                            crossAxisCount: 2,
                            mainAxisSpacing: 8.0,
                            crossAxisSpacing: 8.0,
                            itemCount: searchService.searchResults.length,
                            itemBuilder: (context, index) {
                              final content = searchService.searchResults[index];
                              return ContentCard(
                                content: content,
                                onTap: () => context.push('/buyer/content/${content.id}'),
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
  
  Widget _buildFilterTag({required String label}) {
    return Container(
      margin: const EdgeInsets.only(right: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 12.0,
        ),
      ),
    );
  }
  
  String _getPriceRangeLabel(PriceRange range) {
    switch (range) {
      case PriceRange.free:
        return 'Free';
      case PriceRange.under5:
        return 'Under \$5';
      case PriceRange.under10:
        return 'Under \$10';
      case PriceRange.under20:
        return 'Under \$20';
      case PriceRange.over20:
        return 'Over \$20';
      default:
        return 'All Prices';
    }
  }
  
  Widget _buildEmptyState(bool isSearching) {
    final hasSearchQuery = _currentQuery.isNotEmpty && isSearching;
    
    return ErrorMessage(
      icon: hasSearchQuery ? Icons.search_off : Icons.search,
      iconColor: Theme.of(context).colorScheme.primary.withOpacity(0.5),
      message: hasSearchQuery
          ? 'No results found for "$_currentQuery"\n\nTry different keywords or filters'
          : 'Search for content\n\nEnter keywords above to find content',
      onRetry: hasSearchQuery ? () => _handleSearch('') : null,
    );
  }
}