import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      : super(ThemeState(primaryColor: appThemes[0], fontSize: AppFontSize.medium));

  void changeColor(Color color) => state = state.copyWith(primaryColor: color);

  void changeFontSize(AppFontSize size) => state = state.copyWith(fontSize: size);
}

// Global Provider
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier();
});