import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// WebhookService handles incoming webhook notifications from CI/CD pipelines
/// to automatically update the dashboard with the latest build and test information.
class WebhookService extends ChangeNotifier {
  bool _isActive = false;
  Timer? _pollingTimer;
  final List<Function> _listeners = [];
  Map<String, dynamic> _lastWebhookData = {};
  
  /// The port on which the webhook server will listen
  static const int port = 8080;
  
  /// The endpoint path for the webhook
  static const String endpoint = '/api/webhook/ci';
  
  /// Whether the webhook service is currently active
  bool get isActive => _isActive;
  
  /// The last data received from a webhook
  Map<String, dynamic> get lastWebhookData => _lastWebhookData;

  /// Initialize the webhook service
  Future<void> initialize() async {
    // In a real implementation, this would set up a server to listen for webhooks
    // For this demo, we'll simulate webhook events with polling
    _isActive = false;
  }

  /// Start listening for webhook events
  Future<void> startListening() async {
    if (_isActive) return;
    
    _isActive = true;
    
    // In a real implementation with a backend server, this would start a server
    // For GitHub Pages deployment, we'll use a combination of polling and
    // checking for updates in localStorage that would be set by incoming webhooks
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _checkForWebhookUpdates();
    });
    
    notifyListeners();
  }

  /// Stop listening for webhook events
  Future<void> stopListening() async {
    if (!_isActive) return;
    
    _isActive = false;
    _pollingTimer?.cancel();
    _pollingTimer = null;
    
    notifyListeners();
  }

  /// Add a listener for webhook events
  void addListener(Function listener) {
    _listeners.add(listener);
  }

  /// Remove a listener for webhook events
  void removeListener(Function listener) {
    _listeners.remove(listener);
  }

  /// Notify all listeners of a webhook event
  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
    notifyListeners();
  }

  /// Process an incoming webhook payload
  /// @param data The webhook payload data to process
  void processWebhook(Map<String, dynamic> data) {
    _lastWebhookData = data;
    _notifyListeners();
  }

  /// Check for webhook updates from localStorage
  void _checkForWebhookUpdates() {
    // In a real implementation with a backend server, this would check for new webhook data
    // For GitHub Pages deployment, we'll check localStorage for updates
    // that would be set by incoming webhook requests via JavaScript
    
    // For demo purposes, we'll still simulate webhook events
    _simulateWebhookEvent();
  }
  
  /// Simulate a webhook event for demo purposes
  void _simulateWebhookEvent() {
    // In a real implementation, this would be triggered by an actual webhook
    // For demo purposes, we'll simulate a webhook event with random data
    final buildNumber = (int.parse(_lastWebhookData['buildNumber'] ?? '42') + 1).toString();
    final passedTests = 115 + (DateTime.now().millisecond % 10);
    final totalTests = 120;
    final failedTests = totalTests - passedTests;
    
    final webhookData = {
      'buildNumber': buildNumber,
      'buildDate': DateTime.now().toIso8601String(),
      'branch': 'main',
      'commitHash': '${DateTime.now().millisecond}f4d76a',
      'buildStatus': failedTests == 0 ? 'success' : 'partial_success',
      'tests': {
        'total': totalTests,
        'passed': passedTests,
        'failed': failedTests,
      },
      'securityFeatures': {
        'SSL Pinning': true,
        'Jailbreak Detection': true,
        'Secure Storage': true,
        'App Obfuscation': true,
        'Biometric Authentication': DateTime.now().second % 5 == 0, // Randomly toggle
        'Screenshot Prevention': true,
      },
    };
    
    processWebhook(webhookData);
  }

  /// In a real implementation, this would be the endpoint that receives webhook requests
  Future<void> handleWebhookRequest(http.Request request) async {
    if (request.method != 'POST') {
      return;
    }
    
    try {
      final data = jsonDecode(await request.body) as Map<String, dynamic>;
      processWebhook(data);
    } catch (e) {
      debugPrint('Error processing webhook: $e');
    }
  }

  @override
  void dispose() {
    stopListening();
    _listeners.clear();
    super.dispose();
  }
}