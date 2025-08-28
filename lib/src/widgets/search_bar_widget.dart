import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/search_service.dart';
import 'search_filter_widget.dart';

class SearchBarWidget extends StatefulWidget {
  final Function(String) onSearch;
  final VoidCallback onFilterApplied;
  
  const SearchBarWidget({
    Key? key,
    required this.onSearch,
    required this.onFilterApplied,
  }) : super(key: key);

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _showClearButton = false;
  
  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _showClearButton = _searchController.text.isNotEmpty;
      });
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
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
            onApplyFilters: widget.onFilterApplied,
          ),
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final searchService = Provider.of<SearchService>(context);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    // Check if any filters are applied
    final hasFilters = searchService.selectedContentType != null ||
        searchService.selectedCategory != null ||
        searchService.priceRange != PriceRange.all ||
        searchService.sortOption != SortOption.newest;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          // Search Icon
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Icon(
              Icons.search,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          
          // Search TextField
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)?.translate('searchForContent') ?? 'Search for content...',
                hintStyle: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              style: theme.textTheme.bodyMedium,
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  widget.onSearch(value);
                }
              },
            ),
          ),
          
          // Clear Button (only shown when text is entered)
          if (_showClearButton)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                widget.onSearch('');
                _searchFocusNode.unfocus();
              },
            ),
          
          // Filter Button
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(
                  Icons.filter_list,
                  color: hasFilters 
                      ? theme.colorScheme.primary 
                      : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                ),
                onPressed: _showFilterBottomSheet,
              ),
              if (hasFilters)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}