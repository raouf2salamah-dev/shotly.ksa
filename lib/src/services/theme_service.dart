import 'package:flutter/material.dart';
import 'secure_storage_service.dart';

class ThemeService extends ChangeNotifier {
  // Theme mode key for shared preferences
  static const String _themeModeKey = 'theme_mode';
  
  // Default theme mode
  ThemeMode _themeMode = ThemeMode.system;
  
  // Getter for theme mode
  ThemeMode get themeMode => _themeMode;
  
  // Constructor
  ThemeService() {
    _loadThemeMode();
  }
  
  // Load theme mode from secure storage
  Future<void> _loadThemeMode() async {
    try {
      final themeModeIndexStr = await SecureStorageService.read(_themeModeKey);
      
      if (themeModeIndexStr != null) {
        final themeModeIndex = int.tryParse(themeModeIndexStr);
        if (themeModeIndex != null) {
          _themeMode = ThemeMode.values[themeModeIndex];
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error loading theme mode: $e');
    }
  }
  
  // Save theme mode to secure storage
  Future<void> _saveThemeMode(ThemeMode mode) async {
    try {
      await SecureStorageService.write(_themeModeKey, mode.index.toString());
    } catch (e) {
      debugPrint('Error saving theme mode: $e');
    }
  }
  
  // Set theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    
    _themeMode = mode;
    await _saveThemeMode(mode);
    notifyListeners();
  }
  
  // Toggle between light and dark mode
  Future<void> toggleTheme() async {
    final newMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    
    await setThemeMode(newMode);
  }
  
  // Check if dark mode is active
  bool isDarkMode(BuildContext context) {
    if (_themeMode == ThemeMode.system) {
      return MediaQuery.of(context).platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }
}