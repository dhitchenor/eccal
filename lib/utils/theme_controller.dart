import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/themes.dart';
import '../services/logger_service.dart';

class ThemeController extends ChangeNotifier {
  AppColorFamily _family = AppColorFamily.cyan; // default
  bool _dark = false;

  AppColorFamily get family => _family;
  bool get isDark => _dark;

  ColorScheme get scheme => AppColorSchemes.getScheme(_family, _dark);

  // Initialize theme from saved preferences
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load saved theme family
    final savedFamily = prefs.getString('theme_family');
    if (savedFamily != null) {
      try {
        _family = AppColorFamily.values.firstWhere(
          (e) => e.name == savedFamily,
          orElse: () => AppColorFamily.cyan,
        );
      } catch (e) {
        logger.error('Error loading theme family: $e');
      }
    }
    
    // Load saved dark mode preference
    _dark = prefs.getBool('theme_dark') ?? false;
    
    notifyListeners();
  }

  Future<void> setFamily(AppColorFamily value) async {
    _family = value;
    
    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_family', value.name);
    
    notifyListeners();
  }

  Future<void> toggleDark(bool value) async {
    _dark = value;
    
    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('theme_dark', value);
    
    notifyListeners();
  }
}