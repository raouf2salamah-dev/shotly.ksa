import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show FirebaseFirestore, GetOptions, LoadBundleTask, QuerySnapshot, Source;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../bootstrap/security_bootstrap.dart';
import 'ai_usage_tracker.dart';

class AIService {
  final _db = FirebaseFirestore.instance;
  late final GenerativeModel _geminiModel;
  late final GenerativeModel _geminiFlashModel;
  final _usageTracker = AIUsageTracker();

  /// Initialize the AIService with Gemini models
  AIService() {
    _initializeGeminiModels();
  }

  /// Initialize the Gemini models with API key
  void _initializeGeminiModels() {
    // TODO: Replace with your actual API key
    const apiKey = 'YOUR_API_KEY_HERE'; // Replace with your actual API key
    _geminiModel = GenerativeModel(
      model: 'gemini-pro',
      apiKey: apiKey,
    );
    
    _geminiFlashModel = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
    );
  }

  /// Get AI response using Gemini model
  /// [prompt] - The user's prompt text
  /// [useGemini] - Whether to use Gemini (true) or OpenAI (false)
  /// [userId] - Optional user ID for tracking usage
  /// [monthlyBudget] - Optional monthly budget limit in USD
  Future<String> getAIResponse(
    String prompt, {
    bool useGemini = false,
    String? userId,
    double? monthlyBudget,
  }) async {
    // Check if within budget limits
    final withinBudget = await _usageTracker.checkBudgetLimits(
      monthlyBudget: monthlyBudget,
      userId: userId,
    );
    
    if (!withinBudget) {
      throw Exception("Monthly AI budget limit exceeded");
    }
    
    // Estimate prompt tokens
    final promptTokens = AIUsageTracker.estimateTokenCount(prompt);
    // 1️⃣ Check cache
    var cached = await _db
        .collection('ai_cache')
        .where('prompt', isEqualTo: prompt)
        .get();

    if (cached.docs.isNotEmpty) {
      print("💾 Using cached response");
      return cached.docs.first['response'];
    }
    
    String reply;
    int responseTokens = 0;
    String modelUsed;
    
    if (useGemini) {
      // 2️⃣ Use Google Generative AI (Gemini)
      modelUsed = 'gemini-pro';
      try {
        final content = [Content.text(prompt)];
        final response = await _geminiModel.generateContent(content);
        
        reply = response.text ?? "No response generated";
        responseTokens = AIUsageTracker.estimateTokenCount(reply);
      } catch (e) {
        throw Exception("Gemini request failed: $e");
      }
    } else {
      // 3️⃣ API request (OpenAI fallback)
      modelUsed = 'gpt-3.5-turbo';
      const url = "https://api.openai.com/v1/chat/completions";
      final options = Options(
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer YOUR_OPENAI_KEY" // replace with your free-tier key
        }
      );

      final data = {
        "model": "gpt-3.5-turbo",
        "messages": [
          {"role": "system", "content": "You are an AI sales assistant."},
          {"role": "user", "content": prompt}
        ],
        "max_tokens": 200
      };

      try {
        final response = await SecurityBootstrap.dio.post(url, data: data, options: options);
        if (response.statusCode == 200) {
          reply = response.data['choices'][0]['message']['content'];
          responseTokens = AIUsageTracker.estimateTokenCount(reply);
        } else {
          throw Exception("OpenAI request failed: ${response.statusCode}");
        }
      } catch (e) {
        if (e is DioException) {
          throw Exception("OpenAI request failed: ${e.response?.data ?? e.message}");
        }
        throw Exception("OpenAI request failed: $e");
      }
    }

    // 4️⃣ Save to cache
    await _db.collection('ai_cache').add({
      "prompt": prompt,
      "response": reply,
      "model": modelUsed,
      "timestamp": DateTime.now(),
      "promptTokens": promptTokens,
      "responseTokens": responseTokens,
      "userId": userId,
    });
    
    // 5️⃣ Track usage
    await _usageTracker.trackRequest(
      model: modelUsed,
      promptTokens: promptTokens,
      responseTokens: responseTokens,
      userId: userId,
    );

    return reply;
  }
  
  /// Get recommendations based on user preference using Gemini 1.5 Flash
  /// [userPreference] - The user's preference text
  /// [userId] - Optional user ID for tracking usage
  Future<String> getRecommendations(String userPreference, {String? userId}) async {
    // Check if within budget limits
    final withinBudget = await _usageTracker.checkBudgetLimits(
      userId: userId,
    );
    
    if (!withinBudget) {
      throw Exception("Monthly AI budget limit exceeded");
    }
    
    final prompt = 'Based on my preference for "$userPreference", suggest 5 unique and descriptive keywords for photos, videos, or GIFs a user might like. Provide them as a comma-separated list.';
    final content = [Content.text(prompt)];
    
    try {
      final response = await _geminiFlashModel.generateContent(content);
      final responseText = response.text ?? '';
      
      // Track usage
      await _usageTracker.trackRequest(
        model: 'gemini-1.5-flash',
        promptTokens: AIUsageTracker.estimateTokenCount(prompt),
        responseTokens: AIUsageTracker.estimateTokenCount(responseText),
        userId: userId,
      );
      
      return responseText;
    } catch (e) {
      throw Exception("Gemini request failed: $e");
    }
  }
  
  /// Start a chat session with the Gemini model
  /// Returns a ChatSession that can be used for ongoing conversation
  /// [userId] - Optional user ID for tracking usage
  /// [monthlyBudget] - Optional monthly budget limit in USD
  Future<ChatSession> startChat({String? userId, double? monthlyBudget}) async {
    // Check if within budget limits
    final withinBudget = await _usageTracker.checkBudgetLimits(
      monthlyBudget: monthlyBudget,
      userId: userId,
    );
    
    if (!withinBudget) {
      throw Exception("Monthly AI budget limit exceeded");
    }
    
    return ChatSession(_geminiModel, _usageTracker, userId);
  }
}

/// A wrapper class for managing an ongoing chat session
class ChatSession {
  final GenerativeModel _model;
  final AIUsageTracker _usageTracker;
  final String? _userId;
  
  // The chat instance from the Gemini model
  final GenerativeModel _chatModel;
  
  ChatSession(this._model, this._usageTracker, this._userId) : _chatModel = _model;
  
  /// Send a message to the chat and get a response
  /// [message] - The user's message text
  Future<String> sendMessage(String message) async {
    try {
      // Estimate prompt tokens
      final promptTokens = AIUsageTracker.estimateTokenCount(message);
      
      // Send the message to the model
      final content = [Content.text(message)];
      final response = await _chatModel.generateContent(content);
      final responseText = response.text ?? '';
      final responseTokens = AIUsageTracker.estimateTokenCount(responseText);
      
      // Track usage
      await _usageTracker.trackRequest(
        model: 'gemini-pro',
        promptTokens: promptTokens,
        responseTokens: responseTokens,
        userId: _userId,
      );
      
      return responseText;
    } catch (e) {
      throw Exception("Chat request failed: $e");
    }
  }
  
  /// Get the chat history (not implemented in this simplified version)
  List<Content> get history => [];
}

class BundleService {
  final _db = FirebaseFirestore.instance;
  
  /// Download and process a bundle from a URL
  /// [bundleUrl] - The URL of the bundle to download
  /// Returns the downloaded bundle as bytes
  Future<Uint8List> downloadBundle(String bundleUrl) async {
    try {
      final response = await SecurityBootstrap.dio.get(
        bundleUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to download bundle: ${response.statusCode}');
      }
      
      final buffer = response.data as Uint8List;
      
      // Store the download in Firestore for tracking
      await _db.collection('bundle_downloads').add({
        'bundleUrl': bundleUrl,
        'downloadTime': DateTime.now(),
        'contentLength': buffer.length,
      });
      
      return buffer;
    } catch (e) {
      throw Exception('Bundle download failed: $e');
    }
  }
  
  /// Load a Firestore bundle from a buffer
  /// [buffer] - The bundle data as Uint8List
  /// Returns a Future that completes when the bundle is loaded
  Future<void> loadBundle(Uint8List buffer) async {
    try {
      // Create a LoadBundleTask
      LoadBundleTask task = FirebaseFirestore.instance.loadBundle(buffer);
      
      // Wait for the bundle to finish loading
      final snapshot = await task.stream.last;
      
      // Log the bundle loading result
      await _db.collection('bundle_loads').add({
        'loadTime': DateTime.now(),
        'bytesLoaded': buffer.length,
        'documentsLoaded': snapshot.documentsLoaded,
      });
      
      return;
    } catch (e) {
      throw Exception('Bundle loading failed: $e');
    }
  }
  
  /// Read data from a collection after a bundle has been loaded
  /// [collectionPath] - The path to the collection to read from
  /// Returns a QuerySnapshot containing the documents from the cache
  Future<QuerySnapshot> readBundleData(String collectionPath) async {
    try {
      // Read the data from the cache
      final snapshot = await _db
          .collection(collectionPath)
          .get(const GetOptions(source: Source.cache));
      
      // Log the read operation
      await _db.collection('bundle_reads').add({
        'collectionPath': collectionPath,
        'readTime': DateTime.now(),
        'documentCount': snapshot.docs.length,
      });
      
      return snapshot;
    } catch (e) {
      throw Exception('Bundle data read failed: $e');
    }
  }
  
  /// Process documents from a bundle
  /// [snapshot] - The QuerySnapshot containing the documents
  /// [processor] - A function that processes each document
  void processBundleDocuments(QuerySnapshot snapshot, Function(Map<String, dynamic>) processor) {
    for (var doc in snapshot.docs) {
      processor(doc.data() as Map<String, dynamic>);
    }
  }
}