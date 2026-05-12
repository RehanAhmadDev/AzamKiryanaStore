import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 🚀 NAYA

// --- 🎨 10 Professional Themes List ---
final List<Color> appThemes = [
  const Color(0xFF0F172A), // Slate Dark (Default)
  const Color(0xFF1E3A8A), // Royal Blue
  const Color(0xFF065F46), // Deep Emerald
  const Color(0xFF991B1B), // Crimson Red
  const Color(0xFF5B21B6), // Vivid Purple
  const Color(0xFF374151), // Graphite
  const Color(0xFF155E75), // Ocean Cyan
  const Color(0xFF854D0E), // Golden Brown
  const Color(0xFF1E40AF), // Cobalt
  const Color(0xFF000000), // Pure Black
];

// --- 📏 Font Size Options ---
enum AppFontSize { small, medium, large }

// --- 🏗️ Theme State Model ---
class ThemeState {
  final Color primaryColor;
  final AppFontSize fontSize;

  ThemeState({required this.primaryColor, required this.fontSize});

  ThemeState copyWith({Color? primaryColor, AppFontSize? fontSize}) {
    return ThemeState(
      primaryColor: primaryColor ?? this.primaryColor,
      fontSize: fontSize ?? this.fontSize,
    );
  }
}

// --- 🚀 Theme Notifier ---
class ThemeNotifier extends StateNotifier<ThemeState> {
  ThemeNotifier()
      : super(ThemeState(primaryColor: appThemes[0], fontSize: AppFontSize.medium)) {
    _loadTheme(); // 🚀 NAYA: Start hotay hi purana theme load karein
  }

  // 🚀 NAYA: main.dart se color receive karne ke liye
  void loadSavedTheme(Color color) {
    state = state.copyWith(primaryColor: color);
  }

  // 🚀 NAYA: Saved color ko disk se uthana
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final int? colorValue = prefs.getInt('app_theme_color');
    if (colorValue != null) {
      state = state.copyWith(primaryColor: Color(colorValue));
    }
  }

  // 🚀 UPDATED: Color change karte hi save bhi karna
  Future<void> changeColor(Color color) async {
    state = state.copyWith(primaryColor: color);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('app_theme_color', color.value); // Disk mein save kar diya
  }

  void changeFontSize(AppFontSize size) => state = state.copyWith(fontSize: size);
}

// Global Provider
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier();
});