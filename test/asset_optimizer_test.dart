import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../lib/src/utils/asset_optimizer.dart';

// Generate mocks
@GenerateMocks([ImageCompressor, File, Directory])
import 'asset_optimizer_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  late MockImageCompressor mockCompressor;
  
  setUp(() {
    mockCompressor = MockImageCompressor();
    AssetOptimizer.compressor = mockCompressor;
    const MethodChannel('plugins.flutter.io/path_provider')
      .setMockMethodCallHandler((MethodCall methodCall) async {
        if (methodCall.method == 'getTemporaryDirectory') {
          return '/tmp';
        }
        return null;
      });
  });

  test('compressFile should compress file and return bytes', () async {
    // Arrange
    final mockFile = MockFile();
    final mockCompressedFile = MockFile();
    final mockParent = MockDirectory();
    final compressedBytes = Uint8List.fromList([1, 2, 3]);
    
    when(mockFile.absolute).thenReturn(mockFile);
    when(mockFile.path).thenReturn('/test/path/image.png');
    when(mockFile.parent).thenReturn(mockParent);
    when(mockParent.path).thenReturn('/test/path');
    when(mockFile.uri).thenReturn(Uri.file('/test/path/image.png'));
    
    when(mockCompressor.compressAndGetFile(
      any,
      any,
      minWidth: anyNamed('minWidth'),
      minHeight: anyNamed('minHeight'),
      quality: anyNamed('quality'),
      format: anyNamed('format'),
    )).thenAnswer((_) async => mockCompressedFile);
    
    when(mockCompressedFile.readAsBytes()).thenAnswer((_) async => compressedBytes);
    
    // Act
    final result = await AssetOptimizer.compressFile(
      file: mockFile,
      quality: 85,
      maxWidth: 1200,
      format: CompressFormat.png,
    );
    
    // Assert
    expect(result, equals(compressedBytes));
    verify(mockCompressor.compressAndGetFile(
      '/test/path/image.png',
      any,
      minWidth: 1200,
      minHeight: 1,
      quality: 85,
      format: CompressFormat.png,
    )).called(1);
    verify(mockCompressedFile.readAsBytes()).called(1);
  });
  
  test('compressImage should compress raw image data', () async {
    // Arrange
    final testBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
    final compressedBytes = Uint8List.fromList([1, 2, 3]);
    
    when(mockCompressor.compressWithList(
      any,
      minWidth: anyNamed('minWidth'),
      minHeight: anyNamed('minHeight'),
      quality: anyNamed('quality'),
      format: anyNamed('format'),
    )).thenAnswer((_) async => compressedBytes);
    
    // Act
    final result = await AssetOptimizer.compressImage(
      bytes: testBytes,
      quality: 90,
      format: CompressFormat.webp,
    );
    
    // Assert
    expect(result, equals(compressedBytes));
    verify(mockCompressor.compressWithList(
      testBytes,
      minWidth: 1,
      minHeight: 1,
      quality: 90,
      format: CompressFormat.webp,
    )).called(1);
  });
  
  test('getRecommendedSettings should return appropriate settings for each use case', () {
    // Act & Assert
    final thumbnailSettings = AssetOptimizer.getRecommendedSettings(AssetUseCase.thumbnail);
    expect(thumbnailSettings['quality'], equals(75));
    expect(thumbnailSettings['maxWidth'], equals(200));
    expect(thumbnailSettings['maxHeight'], equals(200));
    expect(thumbnailSettings['format'], equals(CompressFormat.webp));
    expect(thumbnailSettings['useSvgForIcons'], isTrue);
    
    final listItemSettings = AssetOptimizer.getRecommendedSettings(AssetUseCase.listItem);
    expect(listItemSettings['quality'], equals(80));
    expect(listItemSettings['maxWidth'], equals(400));
    expect(listItemSettings['maxHeight'], equals(400));
    expect(listItemSettings['format'], equals(CompressFormat.webp));
    expect(listItemSettings['useSvgForIcons'], isTrue);
    
    final fullscreenSettings = AssetOptimizer.getRecommendedSettings(AssetUseCase.fullscreen);
    expect(fullscreenSettings['quality'], equals(85));
    expect(fullscreenSettings['maxWidth'], equals(1080));
    expect(fullscreenSettings['maxHeight'], equals(1920));
    expect(fullscreenSettings['format'], equals(CompressFormat.webp));
    expect(fullscreenSettings['useSvgForIcons'], isTrue);
    
    final iconSettings = AssetOptimizer.getRecommendedSettings(AssetUseCase.icon);
    expect(iconSettings['quality'], equals(90));
    expect(iconSettings['maxWidth'], equals(64));
    expect(iconSettings['maxHeight'], equals(64));
    expect(iconSettings['format'], equals(CompressFormat.webp));
    expect(iconSettings['useSvgForIcons'], isTrue);
    
    final hdpiSettings = AssetOptimizer.getRecommendedSettings(AssetUseCase.hdpi);
    expect(hdpiSettings['quality'], equals(85));
    expect(hdpiSettings['maxWidth'], equals(720));
    expect(hdpiSettings['maxHeight'], equals(1280));
    expect(hdpiSettings['format'], equals(CompressFormat.webp));
    expect(hdpiSettings['useSvgForIcons'], isTrue);
    
    final xhdpiSettings = AssetOptimizer.getRecommendedSettings(AssetUseCase.xhdpi);
    expect(xhdpiSettings['quality'], equals(85));
    expect(xhdpiSettings['maxWidth'], equals(1080));
    expect(xhdpiSettings['maxHeight'], equals(1920));
    expect(xhdpiSettings['format'], equals(CompressFormat.webp));
    expect(xhdpiSettings['useSvgForIcons'], isTrue);
    
    final xxhdpiSettings = AssetOptimizer.getRecommendedSettings(AssetUseCase.xxhdpi);
    expect(xxhdpiSettings['quality'], equals(90));
    expect(xxhdpiSettings['maxWidth'], equals(1440));
    expect(xxhdpiSettings['maxHeight'], equals(2560));
    expect(xxhdpiSettings['format'], equals(CompressFormat.webp));
    expect(xxhdpiSettings['useSvgForIcons'], isTrue);
  });
  
  test('shouldCompress should return correct decision based on size', () {
    final smallBytes = Uint8List(100 * 1024);
    final largeBytes = Uint8List(100 * 1024 + 1);
    
    expect(AssetOptimizer.shouldCompress(smallBytes), isFalse);
    expect(AssetOptimizer.shouldCompress(largeBytes), isTrue);
  });
}