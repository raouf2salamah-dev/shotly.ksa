import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../models/content_model.dart';
import '../services/content_service.dart';
import 'content_card.dart';

class PaginatedContentList extends StatefulWidget {
  final String? category;
  final ContentType? contentType;
  final int itemsPerPage;
  final bool gridView;
  final ScrollController? scrollController;
  final Function(ContentModel)? onContentTap;
  final Widget? emptyWidget;
  final EdgeInsetsGeometry? padding;

  const PaginatedContentList({
    Key? key,
    this.category,
    this.contentType,
    this.itemsPerPage = 10,
    this.gridView = true,
    this.scrollController,
    this.onContentTap,
    this.emptyWidget,
    this.padding,
  }) : super(key: key);

  @override
  State<PaginatedContentList> createState() => _PaginatedContentListState();
}

class _PaginatedContentListState extends State<PaginatedContentList> {
  final List<ContentModel> _contentList = [];
  bool _isLoading = false;
  bool _hasMoreContent = true;
  String? _lastDocumentId;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController.addListener(_scrollListener);
    _loadInitialContent();
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    } else {
      _scrollController.removeListener(_scrollListener);
    }
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 500 &&
        !_isLoading &&
        _hasMoreContent) {
      _loadMoreContent();
    }
  }

  Future<void> _loadInitialContent() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final contentService = Provider.of<ContentService>(context, listen: false);
      final result = await contentService.getPaginatedContent(
        limit: widget.itemsPerPage,
        category: widget.category,
        contentType: widget.contentType,
      );

      if (mounted) {
        setState(() {
          _contentList.clear();
          _contentList.addAll(result.items);
          _lastDocumentId = result.lastDocumentId;
          _hasMoreContent = result.hasMore;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading initial content: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreContent() async {
    if (_isLoading || !_hasMoreContent) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final contentService = Provider.of<ContentService>(context, listen: false);
      final result = await contentService.getPaginatedContent(
        limit: widget.itemsPerPage,
        startAfterId: _lastDocumentId,
        category: widget.category,
        contentType: widget.contentType,
      );

      if (mounted) {
        setState(() {
          _contentList.addAll(result.items);
          _lastDocumentId = result.lastDocumentId;
          _hasMoreContent = result.hasMore;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading more content: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> refreshContent() async {
    _lastDocumentId = null;
    _hasMoreContent = true;
    await _loadInitialContent();
  }

  @override
  Widget build(BuildContext context) {
    if (_contentList.isEmpty && !_isLoading) {
      return widget.emptyWidget ?? const Center(child: Text('No content found'));
    }

    return RefreshIndicator(
      onRefresh: refreshContent,
      child: widget.gridView ? _buildGridView() : _buildListView(),
    );
  }

  Widget _buildGridView() {
    return MasonryGridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 8.0,
      crossAxisSpacing: 8.0,
      controller: _scrollController,
      padding: widget.padding ?? const EdgeInsets.all(16.0),
      itemCount: _contentList.length + (_isLoading && _hasMoreContent ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _contentList.length) {
          return const Center(child: CircularProgressIndicator());
        }
        
        return ContentCard(
          content: _contentList[index],
          onTap: () {
            if (widget.onContentTap != null) {
              widget.onContentTap!(_contentList[index]);
            }
          },
        );
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      controller: _scrollController,
      padding: widget.padding ?? const EdgeInsets.all(16.0),
      itemCount: _contentList.length + (_isLoading && _hasMoreContent ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _contentList.length) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          ));
        }
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: ContentCard(
            content: _contentList[index],
            onTap: () {
              if (widget.onContentTap != null) {
                widget.onContentTap!(_contentList[index]);
              }
            },
          ),
        );
      },
    );
  }
}