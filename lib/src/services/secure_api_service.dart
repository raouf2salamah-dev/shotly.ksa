import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shotly/src/services/prompt_cache.dart';
import '../../../bootstrap/security_bootstrap.dart';

/// SecureApiService implements the same functionality as ApiService
/// but with added security features like certificate pinning
class SecureApiService {
  final Dio _dio;
  final String _baseUrl;
  
  SecureApiService({
    String baseUrl = "https://api.yourdomain.com", // Update with your actual API domain
    Dio? dio,
  }) : _baseUrl = baseUrl,
       _dio = dio ?? SecurityBootstrap.dio {
    // Configure Dio
    _dio.options.baseUrl = _baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    
    // Add interceptors for logging and error handling
    _dio.interceptors.add(LogInterceptor(responseBody: false));
  }
  
  /// Fetches prompts for a specific media type with caching
  /// 
  /// [mediaType] - The type of media (e.g., 'image', 'video', 'audio')
  /// Returns a list of prompt strings
  Future<List<String>> fetchPrompts(String mediaType) async {
    try {
      // Step 1: Check local cache first
      final cachedPrompts = await PromptCache.getPrompts(mediaType);
      if (cachedPrompts != null) {
        print("✅ Loading prompts from cache for $mediaType...");
        return cachedPrompts;
      }

      // Step 2: If not in cache, call the API
      print("🔄 Fetching prompts from API for $mediaType...");
      return await _fetchFromApi(mediaType);
    } catch (e) {
      // Step 3: Handle errors gracefully
      print("❌ Error fetching prompts: $e");
      
      // Try to return cached data even if it's expired as a fallback
      final cachedPrompts = await PromptCache.getPrompts(mediaType);
      if (cachedPrompts != null) {
        print("⚠️ Using cached prompts after error");
        return cachedPrompts;
      }
      
      // If no cache available, return default prompts
      return _getDefaultPromptsForMediaType(mediaType);
    }
  }
  
  /// Fetches prompts from the API and updates the cache
  /// 
  /// [mediaType] - The type of media (e.g., 'image', 'video', 'audio')
  Future<List<String>> _fetchFromApi(String mediaType) async {
    try {
      final response = await _dio.get(
        '/prompts',
        queryParameters: {'media_type': mediaType},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        final List<dynamic> promptsJson = data['prompts'];
        final List<String> prompts = promptsJson.cast<String>();

        // Save the result to the cache
        await PromptCache.savePrompt(mediaType, prompts);
        print("💾 Saved ${prompts.length} prompts to cache for $mediaType");

        return prompts;
      } else {
        throw Exception('Failed to load prompts: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('Error fetching from API: $e');
      throw _handleDioError(e);
    } catch (e) {
      print('Unexpected error: $e');
      throw e;
    }
  }
  
  /// Refreshes the cache for a specific media type
  /// 
  /// [mediaType] - The type of media to refresh
  /// Returns a list of fresh prompt strings
  Future<List<String>> refreshPrompts(String mediaType) async {
    try {
      print("🔄 Refreshing prompts for $mediaType...");
      
      // Clear existing cache for this media type
      await PromptCache.clearPrompts(mediaType);
      
      // Fetch fresh data from API
      return await _fetchFromApi(mediaType);
    } catch (e) {
      print("❌ Error refreshing prompts: $e");
      return _getDefaultPromptsForMediaType(mediaType);
    }
  }
  
  /// Adds a new prompt to the cache and syncs with the API
  /// 
  /// [mediaType] - The type of media
  /// [prompt] - The new prompt to add
  Future<List<String>> addPrompt(String mediaType, String prompt) async {
    try {
      // Get current prompts (from cache or API)
      List<String> currentPrompts = await fetchPrompts(mediaType);
      
      // Add the new prompt if it doesn't already exist
      if (!currentPrompts.contains(prompt)) {
        currentPrompts.add(prompt);
        
        // Update the cache
        await PromptCache.savePrompt(mediaType, currentPrompts);
        print("➕ Added new prompt to cache for $mediaType");
        
        // TODO: Sync with API (would require a POST endpoint)
        // This would be implemented when the API supports adding prompts
      }
      
      return currentPrompts;
    } catch (e) {
      print("❌ Error adding prompt: $e");
      throw e;
    }
  }
  
  /// Get default prompts for a specific media type
  /// 
  /// [mediaType] - The type of media
  /// Returns a list of default prompts
  List<String> _getDefaultPromptsForMediaType(String mediaType) {
    switch (mediaType) {
      case 'image':
        return [
          'Describe your image in detail',
          'What emotions does this image convey?',
          'Explain the composition of this image'
        ];
      case 'video':
        return [
          'Describe your video content',
          'What is the main theme of this video?',
          'Describe the visual style of this video'
        ];
      case 'gif':
        return [
          'Describe your GIF content',
          'What emotions does this GIF convey?',
          'Explain the animation in this GIF'
        ];
      default:
        return _getDefaultPrompts();
    }
  }
  
  /// Gets all available media types with cached prompts
  Future<List<String>> getAvailableMediaTypes() async {
    return await PromptCache.getAvailableMediaTypes();
  }
  
  /// Checks if a media type has cached prompts
  Future<bool> hasPromptsForMediaType(String mediaType) async {
    return await PromptCache.hasPrompts(mediaType);
  }
  
  /// Clears all cached prompts
  Future<void> clearAllPrompts() async {
    await PromptCache.clearAllPrompts();
    print("🧹 Cleared all cached prompts");
  }

  // Default prompts if API fetch fails
  List<String> _getDefaultPrompts() {
    return [
      'Describe your digital product in detail',
      'Create a compelling marketing description',
      'List the key features of your product',
      'Write a product description targeting beginners',
      'Create a technical description for advanced users'
    ];
  }
  
  // Handle Dio errors and convert them to appropriate exceptions
  Exception _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException('Connection timed out');
      case DioExceptionType.badCertificate:
        return SecurityException('Certificate validation failed - possible security breach detected');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data['message'] ?? 'Unknown server error';
        return ApiException(statusCode ?? 500, message);
      case DioExceptionType.cancel:
        return RequestCancelledException('Request was cancelled');
      case DioExceptionType.connectionError:
        return ConnectivityException('No internet connection');
      default:
        return UnknownException('An unexpected error occurred');
    }
  }
}

// Custom exceptions
class ApiException implements Exception {
  final int statusCode;
  final String message;
  
  ApiException(this.statusCode, this.message);
  
  @override
  String toString() => 'ApiException: [$statusCode] $message';
}

class TimeoutException implements Exception {
  final String message;
  
  TimeoutException(this.message);
  
  @override
  String toString() => 'TimeoutException: $message';
}

class SecurityException implements Exception {
  final String message;
  
  SecurityException(this.message);
  
  @override
  String toString() => 'SecurityException: $message';
}

class RequestCancelledException implements Exception {
  final String message;
  
  RequestCancelledException(this.message);
  
  @override
  String toString() => 'RequestCancelledException: $message';
}

class ConnectivityException implements Exception {
  final String message;
  
  ConnectivityException(this.message);
  
  @override
  String toString() => 'ConnectivityException: $message';
}

class UnknownException implements Exception {
  final String message;
  
  UnknownException(this.message);
  
  @override
  String toString() => 'UnknownException: $message';
}