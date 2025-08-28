import 'package:hive_flutter/hive_flutter.dart';

class PromptCache {
  static const String _boxName = 'prompts_box';
  
  /// Saves a list of prompts for a specific media type
  /// 
  /// [mediaType] - The type of media (e.g., 'image', 'video', 'audio')
  /// [prompts] - List of prompt strings to save
  static Future<void> savePrompt(String mediaType, List<String> prompts) async {
    final box = await Hive.openBox(_boxName);
    await box.put(mediaType, prompts);
    print('💾 Saved ${prompts.length} prompts for $mediaType');
  }
  
  /// Retrieves prompts for a specific media type
  /// 
  /// [mediaType] - The type of media (e.g., 'image', 'video', 'audio')
  /// Returns a list of prompt strings or null if none exist
  static Future<List<String>?> getPrompts(String mediaType) async {
    final box = await Hive.openBox(_boxName);
    final data = box.get(mediaType);
    
    if (data != null) {
      print('📖 Retrieved ${List<String>.from(data).length} prompts for $mediaType');
      return List<String>.from(data);
    }
    
    print('⚠️ No cached prompts found for $mediaType');
    return null;
  }
  
  /// Clears all prompts for a specific media type
  /// 
  /// [mediaType] - The type of media to clear prompts for
  static Future<void> clearPrompts(String mediaType) async {
    final box = await Hive.openBox(_boxName);
    await box.delete(mediaType);
    print('🧹 Cleared prompts for $mediaType');
  }
  
  /// Clears all cached prompts for all media types
  static Future<void> clearAllPrompts() async {
    final box = await Hive.openBox(_boxName);
    await box.clear();
    print('🧹 Cleared all cached prompts');
  }
  
  /// Gets all available media types that have cached prompts
  static Future<List<String>> getAvailableMediaTypes() async {
    final box = await Hive.openBox(_boxName);
    return box.keys.cast<String>().toList();
  }
  
  /// Checks if prompts exist for a specific media type
  /// 
  /// [mediaType] - The type of media to check
  /// Returns true if prompts exist, false otherwise
  static Future<bool> hasPrompts(String mediaType) async {
    final box = await Hive.openBox(_boxName);
    return box.containsKey(mediaType);
  }
}