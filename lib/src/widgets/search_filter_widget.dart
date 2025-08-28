import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/content_model.dart';
import '../services/search_service.dart';
import 'custom_button.dart';

class SearchFilterWidget extends StatefulWidget {
  final VoidCallback onApplyFilters;
  
  const SearchFilterWidget({Key? key, required this.onApplyFilters}) : super(key: key);

  @override
  State<SearchFilterWidget> createState() => _SearchFilterWidgetState();
}

class _SearchFilterWidgetState extends State<SearchFilterWidget> {
  ContentType? _selectedContentType;
  String? _selectedCategory;
  SortOption _selectedSortOption = SortOption.newest;
  PriceRange _selectedPriceRange = PriceRange.all;
  
  @override
  void initState() {
    super.initState();
    final searchService = Provider.of<SearchService>(context, listen: false);
    _selectedContentType = searchService.selectedContentType;
    _selectedCategory = searchService.selectedCategory;
    _selectedSortOption = searchService.sortOption;
    _selectedPriceRange = searchService.priceRange;
  }
  
  @override
  Widget build(BuildContext context) {
    final searchService = Provider.of<SearchService>(context);
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)?.translate('filterContent') ?? 'Filter Content',
                style: theme.textTheme.titleLarge,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Content Type Filter
          Text(
            AppLocalizations.of(context)?.translate('contentType') ?? 'Content Type',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _buildFilterChip(
                label: AppLocalizations.of(context)?.translate('all') ?? 'All',
                selected: _selectedContentType == null,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedContentType = null);
                  }
                },
              ),
              _buildFilterChip(
                label: AppLocalizations.of(context)?.translate('images') ?? 'Images',
                selected: _selectedContentType == ContentType.image,
                onSelected: (selected) {
                  setState(() => _selectedContentType = selected ? ContentType.image : null);
                },
              ),
              _buildFilterChip(
                label: AppLocalizations.of(context)?.translate('videos') ?? 'Videos',
                selected: _selectedContentType == ContentType.video,
                onSelected: (selected) {
                  setState(() => _selectedContentType = selected ? ContentType.video : null);
                },
              ),
              _buildFilterChip(
                label: 'GIFs',
                selected: _selectedContentType == ContentType.gif,
                onSelected: (selected) {
                  setState(() => _selectedContentType = selected ? ContentType.gif : null);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Category Filter
          Text(
            'Category',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip(
                  label: 'All',
                  selected: _selectedCategory == null,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedCategory = null);
                    }
                  },
                ),
                ...searchService.availableCategories.map((category) => 
                  _buildFilterChip(
                    label: category,
                    selected: _selectedCategory == category,
                    onSelected: (selected) {
                      setState(() => _selectedCategory = selected ? category : null);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Price Range Filter
          Text(
            'Price Range',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _buildFilterChip(
                label: 'All',
                selected: _selectedPriceRange == PriceRange.all,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedPriceRange = PriceRange.all);
                  }
                },
              ),
              _buildFilterChip(
                label: 'Free',
                selected: _selectedPriceRange == PriceRange.free,
                onSelected: (selected) {
                  setState(() => _selectedPriceRange = selected ? PriceRange.free : PriceRange.all);
                },
              ),
              _buildFilterChip(
                label: 'Under \$5',
                selected: _selectedPriceRange == PriceRange.under5,
                onSelected: (selected) {
                  setState(() => _selectedPriceRange = selected ? PriceRange.under5 : PriceRange.all);
                },
              ),
              _buildFilterChip(
                label: 'Under \$10',
                selected: _selectedPriceRange == PriceRange.under10,
                onSelected: (selected) {
                  setState(() => _selectedPriceRange = selected ? PriceRange.under10 : PriceRange.all);
                },
              ),
              _buildFilterChip(
                label: 'Under \$20',
                selected: _selectedPriceRange == PriceRange.under20,
                onSelected: (selected) {
                  setState(() => _selectedPriceRange = selected ? PriceRange.under20 : PriceRange.all);
                },
              ),
              _buildFilterChip(
                label: 'Over \$20',
                selected: _selectedPriceRange == PriceRange.over20,
                onSelected: (selected) {
                  setState(() => _selectedPriceRange = selected ? PriceRange.over20 : PriceRange.all);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Sort Options
          Text(
            'Sort By',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _buildFilterChip(
                label: 'Newest',
                selected: _selectedSortOption == SortOption.newest,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedSortOption = SortOption.newest);
                  }
                },
              ),
              _buildFilterChip(
                label: 'Oldest',
                selected: _selectedSortOption == SortOption.oldest,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedSortOption = SortOption.oldest);
                  }
                },
              ),
              _buildFilterChip(
                label: 'Price: High to Low',
                selected: _selectedSortOption == SortOption.priceHighToLow,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedSortOption = SortOption.priceHighToLow);
                  }
                },
              ),
              _buildFilterChip(
                label: 'Price: Low to High',
                selected: _selectedSortOption == SortOption.priceLowToHigh,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedSortOption = SortOption.priceLowToHigh);
                  }
                },
              ),
              _buildFilterChip(
                label: 'Popular',
                selected: _selectedSortOption == SortOption.popular,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedSortOption = SortOption.popular);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Clear All',
                  onPressed: () {
                    setState(() {
                      _selectedContentType = null;
                      _selectedCategory = null;
                      _selectedSortOption = SortOption.newest;
                      _selectedPriceRange = PriceRange.all;
                    });
                  },
                  isOutlined: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomButton(
                  text: 'Apply Filters',
                  onPressed: () {
                    // Apply filters to the search service
                    final searchService = Provider.of<SearchService>(context, listen: false);
                    searchService.setContentTypeFilter(_selectedContentType);
                    searchService.setCategoryFilter(_selectedCategory);
                    searchService.setSortOption(_selectedSortOption);
                    searchService.setPriceRange(_selectedPriceRange);
                    
                    // Close the bottom sheet and refresh the content
                    Navigator.pop(context);
                    widget.onApplyFilters();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required Function(bool) onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: onSelected,
        backgroundColor: Theme.of(context).cardColor,
        selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        checkmarkColor: Theme.of(context).colorScheme.primary,
        labelStyle: TextStyle(
          color: selected 
              ? Theme.of(context).colorScheme.primary 
              : Theme.of(context).textTheme.bodyMedium?.color,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: selected 
                ? Theme.of(context).colorScheme.primary 
                : Theme.of(context).dividerColor,
          ),
        ),
      ),
    );
  }
}