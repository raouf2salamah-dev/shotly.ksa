import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AIUsageTracker {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  // Singleton pattern
  static final AIUsageTracker _instance = AIUsageTracker._internal();
  
  factory AIUsageTracker() {
    return _instance;
  }
  
  AIUsageTracker._internal();

  /// Track a new AI request
  /// 
  /// [model] - The AI model used (e.g., 'gemini-pro', 'gpt-3.5-turbo')
  /// [promptTokens] - Estimated number of tokens in the prompt
  /// [responseTokens] - Estimated number of tokens in the response
  /// [userId] - Optional user ID for per-user tracking
  Future<void> trackRequest({
    required String model,
    required int promptTokens,
    required int responseTokens,
    String? userId,
  }) async {
    try {
      // Calculate estimated cost based on model
      final double estimatedCost = _calculateCost(
        model: model,
        promptTokens: promptTokens,
        responseTokens: responseTokens,
      );
      
      // Create usage record
      final usageData = {
        'model': model,
        'promptTokens': promptTokens,
        'responseTokens': responseTokens,
        'totalTokens': promptTokens + responseTokens,
        'estimatedCost': estimatedCost,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': userId,
      };
      
      // Save to Firestore
      await _db.collection('ai_usage').add(usageData);
      
      // Update monthly usage statistics
      await _updateMonthlyStats(model, promptTokens, responseTokens, estimatedCost, userId);
      
    } catch (e) {
      debugPrint('Error tracking AI usage: $e');
    }
  }
  
  /// Calculate estimated cost based on model and token usage
  double _calculateCost({
    required String model,
    required int promptTokens,
    required int responseTokens,
  }) {
    // Pricing per 1000 tokens (as of 2023)
    switch (model) {
      case 'gemini-pro':
        // Gemini Pro pricing
        return (promptTokens / 1000 * 0.00025) + (responseTokens / 1000 * 0.0005);
      
      case 'gemini-1.5-flash':
        // Gemini 1.5 Flash pricing
        return (promptTokens / 1000 * 0.0003) + (responseTokens / 1000 * 0.0004);
      
      case 'gpt-3.5-turbo':
        // GPT-3.5 Turbo pricing
        return (promptTokens / 1000 * 0.0015) + (responseTokens / 1000 * 0.002);
      
      default:
        // Default fallback pricing
        return (promptTokens / 1000 * 0.001) + (responseTokens / 1000 * 0.002);
    }
  }
  
  /// Update monthly usage statistics
  Future<void> _updateMonthlyStats(
    String model,
    int promptTokens,
    int responseTokens,
    double cost,
    String? userId,
  ) async {
    try {
      // Get current month and year for tracking
      final now = DateTime.now();
      final monthYear = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      
      // Reference to monthly stats document
      final statsRef = _db.collection('ai_monthly_stats').doc(monthYear);
      
      // Update stats using transactions to handle concurrent updates
      await _db.runTransaction((transaction) async {
        final statsDoc = await transaction.get(statsRef);
        
        if (statsDoc.exists) {
          // Update existing stats
          final Map<String, dynamic> data = statsDoc.data() as Map<String, dynamic>;
          
          // Update model-specific stats
          final modelStats = data['models'] ?? {};
          final currentModelStats = modelStats[model] ?? {
            'promptTokens': 0,
            'responseTokens': 0,
            'totalTokens': 0,
            'cost': 0.0,
            'requests': 0,
          };
          
          currentModelStats['promptTokens'] += promptTokens;
          currentModelStats['responseTokens'] += responseTokens;
          currentModelStats['totalTokens'] += (promptTokens + responseTokens);
          currentModelStats['cost'] += cost;
          currentModelStats['requests'] += 1;
          
          modelStats[model] = currentModelStats;
          
          // Update totals
          transaction.update(statsRef, {
            'totalTokens': FieldValue.increment(promptTokens + responseTokens),
            'totalCost': FieldValue.increment(cost),
            'totalRequests': FieldValue.increment(1),
            'models': modelStats,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        } else {
          // Create new stats document
          final modelStats = {
            model: {
              'promptTokens': promptTokens,
              'responseTokens': responseTokens,
              'totalTokens': promptTokens + responseTokens,
              'cost': cost,
              'requests': 1,
            }
          };
          
          transaction.set(statsRef, {
            'month': now.month,
            'year': now.year,
            'monthYear': monthYear,
            'totalTokens': promptTokens + responseTokens,
            'totalCost': cost,
            'totalRequests': 1,
            'models': modelStats,
            'created': FieldValue.serverTimestamp(),
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
      });
      
      // If userId is provided, update user-specific stats
      if (userId != null) {
        await _updateUserStats(userId, model, promptTokens, responseTokens, cost);
      }
      
    } catch (e) {
      debugPrint('Error updating monthly stats: $e');
    }
  }
  
  /// Update user-specific usage statistics
  Future<void> _updateUserStats(
    String userId,
    String model,
    int promptTokens,
    int responseTokens,
    double cost,
  ) async {
    try {
      final now = DateTime.now();
      final monthYear = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      
      // Reference to user stats document
      final userStatsRef = _db
          .collection('users')
          .doc(userId)
          .collection('ai_usage')
          .doc(monthYear);
      
      await _db.runTransaction((transaction) async {
        final userStatsDoc = await transaction.get(userStatsRef);
        
        if (userStatsDoc.exists) {
          // Update existing user stats
          final modelStats = userStatsDoc.data()?['models'] ?? {};
          final currentModelStats = modelStats[model] ?? {
            'promptTokens': 0,
            'responseTokens': 0,
            'totalTokens': 0,
            'cost': 0.0,
            'requests': 0,
          };
          
          currentModelStats['promptTokens'] += promptTokens;
          currentModelStats['responseTokens'] += responseTokens;
          currentModelStats['totalTokens'] += (promptTokens + responseTokens);
          currentModelStats['cost'] += cost;
          currentModelStats['requests'] += 1;
          
          modelStats[model] = currentModelStats;
          
          transaction.update(userStatsRef, {
            'totalTokens': FieldValue.increment(promptTokens + responseTokens),
            'totalCost': FieldValue.increment(cost),
            'totalRequests': FieldValue.increment(1),
            'models': modelStats,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        } else {
          // Create new user stats document
          final modelStats = {
            model: {
              'promptTokens': promptTokens,
              'responseTokens': responseTokens,
              'totalTokens': promptTokens + responseTokens,
              'cost': cost,
              'requests': 1,
            }
          };
          
          transaction.set(userStatsRef, {
            'month': now.month,
            'year': now.year,
            'monthYear': monthYear,
            'totalTokens': promptTokens + responseTokens,
            'totalCost': cost,
            'totalRequests': 1,
            'models': modelStats,
            'created': FieldValue.serverTimestamp(),
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      debugPrint('Error updating user stats: $e');
    }
  }
  
  /// Get current month's usage statistics
  Future<Map<String, dynamic>> getCurrentMonthStats() async {
    try {
      final now = DateTime.now();
      final monthYear = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      
      final statsDoc = await _db.collection('ai_monthly_stats').doc(monthYear).get();
      
      if (statsDoc.exists) {
        return statsDoc.data() as Map<String, dynamic>;
      } else {
        return {
          'month': now.month,
          'year': now.year,
          'monthYear': monthYear,
          'totalTokens': 0,
          'totalCost': 0.0,
          'totalRequests': 0,
          'models': {},
        };
      }
    } catch (e) {
      debugPrint('Error getting monthly stats: $e');
      return {};
    }
  }
  
  /// Get user's current month usage statistics
  Future<Map<String, dynamic>> getUserMonthStats(String userId) async {
    try {
      final now = DateTime.now();
      final monthYear = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      
      final userStatsDoc = await _db
          .collection('users')
          .doc(userId)
          .collection('ai_usage')
          .doc(monthYear)
          .get();
      
      if (userStatsDoc.exists) {
        return userStatsDoc.data() as Map<String, dynamic>;
      } else {
        return {
          'month': now.month,
          'year': now.year,
          'monthYear': monthYear,
          'totalTokens': 0,
          'totalCost': 0.0,
          'totalRequests': 0,
          'models': {},
        };
      }
    } catch (e) {
      debugPrint('Error getting user monthly stats: $e');
      return {};
    }
  }
  
  /// Check if usage is within budget limits
  /// Returns true if within budget, false if exceeded
  Future<bool> checkBudgetLimits({
    double? monthlyBudget,
    String? userId,
  }) async {
    try {
      if (monthlyBudget == null) {
        // No budget set, assume within limits
        return true;
      }
      
      // Get current month stats
      final Map<String, dynamic> stats;
      
      if (userId != null) {
        // Check user-specific budget
        stats = await getUserMonthStats(userId);
      } else {
        // Check overall budget
        stats = await getCurrentMonthStats();
      }
      
      final double currentCost = stats['totalCost'] ?? 0.0;
      
      // Return true if within budget, false if exceeded
      return currentCost < monthlyBudget;
      
    } catch (e) {
      debugPrint('Error checking budget limits: $e');
      // Default to allowing usage in case of error
      return true;
    }
  }
  
  /// Estimate token count from text
  /// This is a simple estimation - for production use a proper tokenizer
  static int estimateTokenCount(String text) {
    if (text.isEmpty) return 0;
    
    // Simple estimation: ~4 chars per token for English text
    return (text.length / 4).ceil();
  }
}