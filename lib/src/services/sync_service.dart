import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/document.dart';
import 'bundle_service.dart';
import '../utils/logger.dart';

class SyncService {
  /// Logger instance for this class
  final _logger = Logger('SyncService');
  // Dependencies
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final BundleService _bundleService = BundleService();
  final Connectivity _connectivity = Connectivity();
  
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  bool _isOnline = true;
  
  // Singleton pattern
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  
  SyncService._internal() {
    // Initialize connectivity monitoring
    _initConnectivity();
  }
  
  // Public getters
  bool get isOnline => _isOnline;
  Stream<ConnectivityResult> get connectivityStream => _connectivity.onConnectivityChanged;
  
  Future<void> _initConnectivity() async {
    try {
      // Check initial connectivity
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
      
      // If online, sync data
      if (_isOnline) {
        syncDataWhenOnline();
      }
      
      // Listen for connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
        final wasOnline = _isOnline;
        _updateConnectionStatus(result);
        
        // If we just came back online, sync data
        if (!wasOnline && _isOnline) {
          _logger.i('🔄 Network reconnected, syncing data...');
          syncDataWhenOnline();
        }
      });
    } catch (e) {
      _logger.e('Failed to get connectivity', error: e);
    }
  }
  
  // Update connection status based on connectivity result
  void _updateConnectionStatus(ConnectivityResult result) {
    _isOnline = result != ConnectivityResult.none;
    _logger.i('📡 Connectivity status: ${_isOnline ? 'Online' : 'Offline'}');
  }
  
  // Download and store bundles when online
  Future<void> syncDataWhenOnline() async {
    if (!_isOnline) {
      _logger.w('⚠️ Cannot sync data: Device is offline');
      return;
    }
    
    try {
      // List of collections to sync
      final collections = ['users', 'content', 'settings'];
      
      for (final collection in collections) {
        // Check if bundle needs updating
        final isValid = await _bundleService.isBundleValid(collection);
        
        if (!isValid) {
          _logger.i('🔄 Syncing collection: $collection');
          await _bundleService.downloadBundle(collection);
        } else {
          _logger.i('✅ Collection already synced: $collection');
        }
      }
      
      _logger.i('✅ All collections synced successfully');
    } catch (e) {
      _logger.e('❌ Error syncing data', error: e);
    }
  }
  
  // Serve cached data when offline
  Future<List<Document>> getDataOffline(String collection) async {
    // Use BundleService to read cached data
    return _bundleService.readBundleData(collection);
  }
  
  // Get data with automatic online/offline handling
  Future<List<Document>> getData(String collection) async {
    if (_isOnline) {
      try {
        // Try to get fresh data from Firestore
        final snapshot = await _firestore.collection(collection).get();
        final documents = snapshot.docs
            .map((doc) => Document.fromFirestore(doc, collection))
            .toList();
        
        // Update the bundle in the background
        _bundleService.downloadBundle(collection);
        
        return documents;
      } catch (e) {
        _logger.w('⚠️ Error fetching online data, falling back to offline: $e');
        return getDataOffline(collection);
      }
    } else {
      // Use offline data
      _logger.i('📱 Using offline data for: $collection');
      return getDataOffline(collection);
    }
  }
  
  // Force sync a specific collection
  Future<void> forceSyncCollection(String collection) async {
    if (!_isOnline) {
      _logger.w('⚠️ Cannot force sync: Device is offline');
      return;
    }
    
    try {
      await _bundleService.downloadBundle(collection);
      _logger.i('✅ Force synced collection: $collection');
    } catch (e) {
      _logger.e('❌ Error force syncing collection: $e', error: e);
      rethrow;
    }
  }
  
  // Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
  }
}