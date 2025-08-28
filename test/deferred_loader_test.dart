import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import '../lib/src/utils/deferred_loader.dart';

void main() {
  group('DeferredLoader Tests', () {
    test('ensureLoaded should load a library once', () async {
      // Arrange
      int loadCount = 0;
      final loader = DeferredLoader(() async {
        loadCount++;
        await Future.delayed(const Duration(milliseconds: 50));
        return;
      });
      
      // Act
      await loader.ensureLoaded();
      await loader.ensureLoaded(); // Call again
      
      // Assert
      expect(loadCount, equals(1)); // Should only load once
      expect(loader.isLoaded, isTrue);
    });
    
    test('concurrent calls should only load once', () async {
      // Arrange
      int loadCount = 0;
      final loader = DeferredLoader(() async {
        loadCount++;
        await Future.delayed(const Duration(milliseconds: 100));
        return;
      });
      
      // Act - Call multiple times concurrently
      final futures = <Future>[];
      for (int i = 0; i < 5; i++) {
        futures.add(loader.ensureLoaded());
      }
      
      await Future.wait(futures);
      
      // Assert
      expect(loadCount, equals(1)); // Should only load once
      expect(loader.isLoaded, isTrue);
    });
    
    test('ensureLoaded should respect timeout', () async {
      // Arrange
      final loader = DeferredLoader(() async {
        await Future.delayed(const Duration(milliseconds: 200));
        return;
      });
      
      // Act & Assert
      expect(
        () => loader.ensureLoaded(timeout: const Duration(milliseconds: 50)),
        throwsA(isA<TimeoutException>()),
      );
      
      // Should not be marked as loaded after timeout
      expect(loader.isLoaded, isFalse);
    });
    
    test('ensureLoaded should handle errors', () async {
      // Arrange
      final loader = DeferredLoader(() async {
        throw Exception('Test error');
      });
      
      // Act & Assert
      expect(
        () => loader.ensureLoaded(),
        throwsException,
      );
      
      // Should not be marked as loaded after error
      expect(loader.isLoaded, isFalse);
    });
  });
}