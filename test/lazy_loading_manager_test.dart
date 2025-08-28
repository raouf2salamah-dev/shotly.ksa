import 'package:flutter_test/flutter_test.dart';
import 'dart:async';
import '../lib/src/utils/lazy_loading_manager.dart';

void main() {
  group('LazyLoadingManager Tests', () {
    late LazyLoadingManager manager;
    
    setUp(() {
      // Get the singleton instance and reset it for each test
      manager = LazyLoadingManager();
      manager.resetForTesting();
    });
    
    test('loadResource should load and cache a resource', () async {
      // Arrange
      const resourceId = 'test_resource';
      final testResource = 'test_data';
      
      // Act
      final result = await manager.loadResource(
        resourceId,
        () async => testResource,
        priority: 1,
      );
      
      // Assert
      expect(result, equals(testResource));
      expect(manager.getCachedResource(resourceId), equals(testResource));
    });
    
    test('loadResource should return cached resource if already loaded', () async {
      // Arrange
      const resourceId = 'test_resource';
      final testResource = 'test_data';
      int loaderCallCount = 0;
      
      // Load the resource first time
      await manager.loadResource(
        resourceId,
        () async {
          loaderCallCount++;
          return testResource;
        },
        priority: 1,
      );
      
      // Act - Load the same resource again
      final result = await manager.loadResource(
        resourceId,
        () async {
          loaderCallCount++;
          return 'different_data';
        },
        priority: 1,
      );
      
      // Assert
      expect(result, equals(testResource)); // Should return the original cached data
      expect(loaderCallCount, equals(1)); // Loader should only be called once
    });
    
    test('clearCache should remove all cached resources', () async {
      // Arrange
      const resourceId1 = 'test_resource_1';
      const resourceId2 = 'test_resource_2';
      
      // Load two resources
      await manager.loadResource(
        resourceId1,
        () async => 'data_1',
        priority: 1,
      );
      
      await manager.loadResource(
        resourceId2,
        () async => 'data_2',
        priority: 1,
      );
      
      // Verify both are loaded
      expect(manager.isResourceLoaded(resourceId1), isTrue);
      expect(manager.isResourceLoaded(resourceId2), isTrue);
      
      // Act
      manager.clearAllCache();
      
      // Assert
      expect(manager.getCachedResource(resourceId1), isNull);
      expect(manager.getCachedResource(resourceId2), isNull);
      expect(manager.getCachedResourcesCount(), equals(0));
    });
    
    test('prioritizeResource should update resource priority', () async {
      // Arrange
      const resourceId = 'test_resource';
      const initialPriority = 1;
      const newPriority = 5;
      
      // Load resource with initial priority
      await manager.loadResource(
        resourceId,
        () async => 'test_data',
        priority: initialPriority,
      );
      
      // Act
      manager.prioritizeVisibleResources([resourceId], priority: newPriority);
      
      // Assert - We can't directly test the priority as it's private,
      // but we can verify the method doesn't throw and the resource is still available
      expect(manager.isResourceLoaded(resourceId), isTrue);
    });
    
    test('getCachedResourcesCount should return correct count', () async {
      // Arrange - Initially empty
      expect(manager.getCachedResourcesCount(), equals(0));
      
      // Act - Load three resources
      await manager.loadResource(
        'resource_1',
        () async => 'data_1',
        priority: 1,
      );
      
      await manager.loadResource(
        'resource_2',
        () async => 'data_2',
        priority: 1,
      );
      
      await manager.loadResource(
        'resource_3',
        () async => 'data_3',
        priority: 1,
      );
      
      // Assert
      expect(manager.getCachedResourcesCount(), equals(3));
      
      // Act - Clear one resource
      manager.clearResourceCache('resource_2');
      
      // Assert
      expect(manager.getCachedResourcesCount(), equals(2));
    });
    
    test('clearResource should remove specific resource', () async {
      // Arrange
      const resourceId1 = 'test_resource_1';
      const resourceId2 = 'test_resource_2';
      
      // Load two resources
      await manager.loadResource(
        resourceId1,
        () async => 'data_1',
        priority: 1,
      );
      
      await manager.loadResource(
        resourceId2,
        () async => 'data_2',
        priority: 1,
      );
      
      // Act
      manager.clearResourceCache(resourceId1);
      
      // Assert
      expect(manager.isResourceLoaded(resourceId1), isFalse);
      expect(manager.isResourceLoaded(resourceId2), isTrue);
    });
    
    test('loadResource should respect maxConcurrentLoads limit', () async {
      // Create manager with max 2 concurrent loads
      final limitedManager = LazyLoadingManager();
      limitedManager.maxConcurrentLoads = 2;
      
      // Create a completer to control when loads complete
      final completer1 = Completer<String>();
      final completer2 = Completer<String>();
      final completer3 = Completer<String>();
      
      // Start 3 loads (only 2 should start immediately)
      Future<String> future1 = limitedManager.loadResource<String>(
        'resource_1',
        () => completer1.future,
        priority: 1,
      );
      
      Future<String> future2 = limitedManager.loadResource<String>(
        'resource_2',
        () => completer2.future,
        priority: 1,
      );
      
      bool thirdLoadStarted = false;
      Future<String> future3 = limitedManager.loadResource<String>(
        'resource_3',
        () {
          thirdLoadStarted = true;
          return completer3.future;
        },
        priority: 1,
      );
      
      // Allow some time for the first two loads to start
      await Future.delayed(Duration.zero);
      
      // The third load should not have started yet
      expect(thirdLoadStarted, isFalse);
      
      // Complete the first load
      completer1.complete('data_1');
      await future1;
      
      // Allow some time for the third load to start
      await Future.delayed(Duration.zero);
      
      // Now the third load should have started
      expect(thirdLoadStarted, isTrue);
      
      // Complete the remaining loads
      completer2.complete('data_2');
      completer3.complete('data_3');
      
      await Future.wait([future2, future3]);
    });
  });
}