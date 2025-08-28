import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'logger.dart';

/// A utility class to handle deep links in the application
/// This class provides methods to parse and navigate to the correct screen
/// based on deep link URLs
class DeepLinkHandler {
  /// Logger instance for this class
  final _logger = Logger('DeepLinkHandler');
  /// Singleton instance
  static final DeepLinkHandler _instance = DeepLinkHandler._internal();
  
  /// Factory constructor to return the singleton instance
  factory DeepLinkHandler() => _instance;
  
  /// Internal constructor
  DeepLinkHandler._internal();
  
  /// Initialize deep link handling
  /// This should be called early in the app lifecycle
  Future<void> initDeepLinks() async {
    // Additional initialization if needed
    _logger.i('Initialized');
    return Future.value();
  }
  
  /// Handle incoming links and navigate to the appropriate screen
  /// 
  /// [uri] - The URI from the deep link
  /// [context] - The BuildContext for navigation
  void handleLink(Uri uri, BuildContext context) {
    // Extract path and query parameters
    final path = uri.path;
    final params = uri.queryParameters;
    
    // Log the deep link for debugging
    _logger.i('Deep link received: $uri');
    _logger.d('Path: $path');
    _logger.d('Query parameters: $params');
    
    // Handle content sharing deep links
    if (path.contains('/content/')) {
      final contentId = path.split('/').last;
      if (contentId.isNotEmpty) {
        context.go('/buyer/content/$contentId');
        return;
      }
    }
    
    // Handle search deep links
    if (path.contains('/search')) {
      final query = params['q'];
      if (query != null && query.isNotEmpty) {
        context.go('/buyer/search', extra: {'query': query});
        return;
      }
    }
    
    // Handle profile deep links
    if (path.contains('/profile/')) {
      final userId = path.split('/').last;
      if (userId.isNotEmpty) {
        // Navigate to profile with userId
        context.go('/buyer/profile', extra: {'userId': userId});
        return;
      }
    }
    
    // Handle transitions demo deep links
    if (path.contains('/transitions/')) {
      final type = path.split('/').last;
      if (type.isNotEmpty) {
        context.go('/transitions-example/$type');
        return;
      }
    }
    
    // Handle direct transitions demo deep links
    if (path == '/transitions') {
      context.go('/transitions-demo');
      return;
    }
    
    // Default fallback - go to home if no specific path matched
    if (path.isEmpty || path == '/') {
      context.go('/buyer');
    }
  }
  
  /// Parse a URI and return the appropriate route path
  /// 
  /// [uri] - The URI to parse
  /// Returns a route path string or null if URI can't be handled
  String? handleUri(Uri uri) {
    if (uri.toString().isEmpty) return null;
    
    _logger.i('Received URI: ${uri.toString()}');
    
    // Handle different URI schemes
    if (uri.scheme == 'shotly' || uri.host == 'shotly.example.com') {
      final path = uri.path;
      
      // Handle content sharing
      if (path.startsWith('/share/')) {
        final contentId = path.replaceFirst('/share/', '');
        return '/content/$contentId';
      }
      
      // Handle search
      if (path.startsWith('/search/')) {
        final query = path.replaceFirst('/search/', '');
        return '/search?q=$query';
      }
      
      // Handle profile
      if (path.startsWith('/profile/')) {
        final userId = path.replaceFirst('/profile/', '');
        return '/profile/$userId';
      }
      
      // Handle transitions demo
      if (path.startsWith('/transitions/')) {
        final type = path.replaceFirst('/transitions/', '');
        return '/transitions-example/$type';
      }
      
      // Handle direct transitions demo
      if (path == '/transitions') {
        return '/transitions-demo';
      }
    }
    
    return null;
  }
  
  /// Generate a deep link URI for transitions demo
  /// 
  /// [type] - The type of transition to demonstrate
  /// Returns a URI that can be used for deep linking to transitions
  Uri generateTransitionsLink(String type) {
    return Uri.parse('shotly://transitions/$type');
  }
  
  /// Generate a shareable link for content
  /// 
  /// [contentId] - The ID of the content to share
  /// Returns a URI string that can be shared
  String generateContentShareLink(String contentId) {
    return 'https://shotly.example.com/content/$contentId';
  }
  
  /// Generate a deep link URI for content
  /// 
  /// [contentId] - The ID of the content
  /// Returns a URI that can be used for deep linking
  Uri generateContentDeepLink(String contentId) {
    return Uri.parse('shotly://content/$contentId');
  }
}