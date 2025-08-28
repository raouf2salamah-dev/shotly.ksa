import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';

import '../../models/content_model.dart';
import '../../services/auth_service.dart';
import '../../services/content_service.dart';
import '../../services/search_service.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/loading_state.dart';
import '../../widgets/content_card.dart';
import '../../widgets/search_bar_widget.dart';
import '../../widgets/language_switcher.dart';

class BuyerHomeScreen extends StatefulWidget {
  const BuyerHomeScreen({super.key});

  @override
  State<BuyerHomeScreen> createState() => _BuyerHomeScreenState();
}

class _BuyerHomeScreenState extends State<BuyerHomeScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  bool _isTrendingLoading = false;
  List<ContentModel> _trendingContent = [];
  List<ContentModel> _recommendedContent = [];
  TabController? _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeSearchService();
    _loadContent();
    _loadTrendingContent();
    _loadRecommendedContent();
  }
  
  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }
  
  void _initializeSearchService() {
    // Initialize the search service with default values
    final searchService = Provider.of<SearchService>(context, listen: false);
    searchService.clearFilters();
    searchService.getRecentContent();
  }
  
  Future<void> _loadContent() async {
    if (!mounted) return;
    
    final searchService = Provider.of<SearchService>(context, listen: false);
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await searchService.getRecentContent();
      
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
        
        context.showErrorSnackBar(
          'Error loading content: ${e.toString()}',
          showRetry: true,
          retryOperation: _loadContent,
        );
      }
    }
  }
  
  Future<void> _loadTrendingContent() async {
    if (!mounted) return;
    
    final searchService = Provider.of<SearchService>(context, listen: false);
    
    setState(() {
      _isTrendingLoading = true;
    });
    
    try {
      final trending = await searchService.getTrendingContent();
      
      if (mounted) {
        setState(() {
          _trendingContent = trending;
          _isTrendingLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTrendingLoading = false;
        });
        
        context.showErrorSnackBar(
          'Error loading trending content: ${e.toString()}',
          showRetry: true,
          retryOperation: _loadTrendingContent,
        );
      }
    }
  }
  
  Future<void> _loadRecommendedContent() async {
    try {
      final searchService = Provider.of<SearchService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      
      if (authService.currentUser != null) {
        final recommended = await searchService.getRecommendedContent(authService.currentUser!.uid);
        
        if (mounted) {
          setState(() {
            _recommendedContent = recommended;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading recommended content: $e');
    }
  }
  
  void _handleSearch(String query) {
    final searchService = Provider.of<SearchService>(context, listen: false);
    searchService.searchContent(query);
  }
  
  void _applyFilters() {
    _loadContent();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = Provider.of<AuthService>(context);
    final searchService = Provider.of<SearchService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.translate('discoverContent') ?? 'Discover Content'),
        actions: [
          Builder(
  builder: (context) => LanguageSwitcher(
    showLabel: false,
    useIconButton: true,
  ),
),
IconButton(
  icon: const Icon(Icons.history),
  tooltip: 'Recently Viewed',
  onPressed: () => context.push('/buyer/recent-views'),
),
          IconButton(
            icon: const Icon(Icons.favorite_border),
            tooltip: 'Favorites',
            onPressed: () => context.push('/buyer/favorites'),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile',
            onPressed: () => context.push('/buyer/profile'),
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
          
          // Tab Bar
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: AppLocalizations.of(context)?.translate('discover') ?? 'Discover'),
              Tab(text: AppLocalizations.of(context)?.translate('trending') ?? 'Trending'),
              Tab(text: AppLocalizations.of(context)?.translate('forYou') ?? 'For You'),
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
                // Discover Tab
                _buildDiscoverTab(searchService),
                
                // Trending Tab
                _buildTrendingTab(),
                
                // For You Tab
                _buildRecommendedTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDiscoverTab(SearchService searchService) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : searchService.searchResults.isEmpty
            ? _buildEmptyState(searchService.isSearching)
            : RefreshIndicator(
                onRefresh: _loadContent,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (ScrollNotification scrollInfo) {
                      if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent &&
                          !searchService.isLoadingMore &&
                          searchService.hasMoreContent) {
                        // Load more content when reaching the end of the list
                        searchService.loadMoreContent();
                      }
                      return false;
                    },
                    child: ListView.builder(
                      itemCount: searchService.searchResults.length + (searchService.hasMoreContent ? 1 : 0),
                      itemBuilder: (context, index) {
                        // Show loading indicator at the bottom while loading more
                        if (index == searchService.searchResults.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        
                        final content = searchService.searchResults[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: ContentCard(
                            content: content,
                            onTap: () => context.push('/buyer/content/${content.id}'),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
  }
  
  Widget _buildTrendingTab() {
    return _trendingContent.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadTrendingContent,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView.builder(
                itemCount: _trendingContent.length,
                itemBuilder: (context, index) {
                  final content = _trendingContent[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: ContentCard(
                      content: content,
                      onTap: () => context.push('/buyer/content/${content.id}'),
                    ),
                  );
                },
              ),
            ),
          );
  }
  
  Widget _buildRecommendedTab() {
    final authService = Provider.of<AuthService>(context);
    
    if (authService.currentUser == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_outline,
              size: 64.0,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: 16.0),
            Text(
              AppLocalizations.of(context)?.translate('signInForRecommendations') ?? 'Sign in to see personalized recommendations',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return _recommendedContent.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadRecommendedContent,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView.builder(
                itemCount: _recommendedContent.length,
                itemBuilder: (context, index) {
                  final content = _recommendedContent[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: ContentCard(
                      content: content,
                      onTap: () => context.push('/buyer/content/${content.id}'),
                    ),
                  );
                },
              ),
            ),
          );
  }
  
  Widget _buildEmptyState(bool isSearching) {
    final theme = Theme.of(context);
    final searchService = Provider.of<SearchService>(context);
    final hasSearchQuery = searchService.searchResults.isEmpty && isSearching;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasSearchQuery
                ? Icons.search_off
                : Icons.image_not_supported_outlined,
            size: 64.0,
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 16.0),
          Text(
            hasSearchQuery
                ? AppLocalizations.of(context)?.translate('noResultsFound') ?? 'No results found'
                : AppLocalizations.of(context)?.translate('noContentAvailable') ?? 'No content available yet',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8.0),
          Text(
            hasSearchQuery
                ? AppLocalizations.of(context)?.translate('tryDifferentSearch') ?? 'Try a different search term or filter'
                : AppLocalizations.of(context)?.translate('checkBackLater') ?? 'Check back later for new content',
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