import 'package:flutter/material.dart';

class AppColors {
  // Background colors
  static const Color bgDark = Color(0xFF18140F); // oklch(0.1 0.025 72)
  static const Color bg = Color(0xFF241D13); // oklch(0.15 0.025 72)
  static const Color bgLight = Color(0xFF30281A); // oklch(0.2 0.025 72)
  // Light mode backgrounds
  static const Color lightBg = Color(0xFFF8F5F2); // oklch(0.96 0.05 72)
  static const Color lightSurface = Color(0xFFFFFFFF);
  // Text colors
  static const Color text = Color(0xFFF8F5F2); // oklch(0.96 0.05 72)
  static const Color textMuted = Color(0xFFCCC2B8); // oklch(0.76 0.05 72)
  static const Color lightText = Color(0xFF18140F);
  static const Color lightTextMuted = Color(0xFF66573A);
  // Highlight and border colors
  static const Color highlight = Color(0xFF7C6B4A); // oklch(0.5 0.05 72)
  static const Color border = Color(0xFF66573A); // oklch(0.4 0.05 72)
  static const Color borderMuted = Color(0xFF4D3F28); // oklch(0.3 0.05 72)
  // Semantic colors
  static const Color primary = Color(0xFFE3A15A); // oklch(0.76 0.1 72)
  static const Color secondary = Color(0xFF7DA6F6); // oklch(0.76 0.1 252)
  static const Color danger = Color(0xFFE3B07A); // oklch(0.7 0.05 30)
  static const Color warning = Color(0xFFE3D37A); // oklch(0.7 0.05 100)
  static const Color success = Color(0xFF8BE37A); // oklch(0.7 0.05 160)
  static const Color info = Color(0xFF7A9FE3); // oklch(0.7 0.05 260)
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // Color scheme
      colorScheme: const ColorScheme.dark(
        background: AppColors.bg,
        surface: AppColors.bgLight,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        error: AppColors.danger,
        onBackground: AppColors.text,
        onSurface: AppColors.text,
        onPrimary: AppColors.bgDark,
        onSecondary: AppColors.bgDark,
        onError: AppColors.text,
        outline: AppColors.border,
        outlineVariant: AppColors.borderMuted,
      ),
      
      // Scaffold background
      scaffoldBackgroundColor: AppColors.bg,
      
      // App bar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bgDark,
        foregroundColor: AppColors.text,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      
      // Card theme
      cardTheme: CardTheme(
        color: AppColors.bgLight,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.borderMuted),
        ),
      ),
      
      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.bgDark,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      
      // Outlined button theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      
      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
        ),
      ),
      
      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        labelStyle: const TextStyle(color: AppColors.textMuted),
        hintStyle: const TextStyle(color: AppColors.textMuted),
      ),
      
      // Text theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: AppColors.text),
        displayMedium: TextStyle(color: AppColors.text),
        displaySmall: TextStyle(color: AppColors.text),
        headlineLarge: TextStyle(color: AppColors.text),
        headlineMedium: TextStyle(color: AppColors.text),
        headlineSmall: TextStyle(color: AppColors.text),
        titleLarge: TextStyle(color: AppColors.text),
        titleMedium: TextStyle(color: AppColors.text),
        titleSmall: TextStyle(color: AppColors.text),
        bodyLarge: TextStyle(color: AppColors.text),
        bodyMedium: TextStyle(color: AppColors.text),
        bodySmall: TextStyle(color: AppColors.textMuted),
        labelLarge: TextStyle(color: AppColors.text),
        labelMedium: TextStyle(color: AppColors.text),
        labelSmall: TextStyle(color: AppColors.textMuted),
      ),
      
      // Icon theme
      iconTheme: const IconThemeData(
        color: AppColors.text,
        size: 24,
      ),
      
      // Floating action button theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.bgDark,
      ),
      
      // Bottom navigation bar theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.bgDark,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
      ),
      
      // Divider theme
      dividerTheme: const DividerThemeData(
        color: AppColors.borderMuted,
        thickness: 1,
      ),
      
      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.bgLight,
        selectedColor: AppColors.primary,
        labelStyle: const TextStyle(color: AppColors.text),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderMuted),
        ),
      ),
    );
  }
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        background: AppColors.lightBg,
        surface: AppColors.lightSurface,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        error: AppColors.danger,
        onBackground: AppColors.lightText,
        onSurface: AppColors.lightText,
        onPrimary: AppColors.lightSurface,
        onSecondary: AppColors.lightSurface,
        onError: AppColors.lightText,
        outline: Colors.transparent,
        outlineVariant: Colors.transparent,
      ),
      scaffoldBackgroundColor: AppColors.lightBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightSurface,
        foregroundColor: AppColors.lightText,
        elevation: 2,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardTheme(
        color: AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          side: BorderSide.none,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.lightSurface,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        labelStyle: const TextStyle(color: AppColors.lightTextMuted),
        hintStyle: const TextStyle(color: AppColors.lightTextMuted),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: AppColors.lightText),
        displayMedium: TextStyle(color: AppColors.lightText),
        displaySmall: TextStyle(color: AppColors.lightText),
        headlineLarge: TextStyle(color: AppColors.lightText),
        headlineMedium: TextStyle(color: AppColors.lightText),
        headlineSmall: TextStyle(color: AppColors.lightText),
        titleLarge: TextStyle(color: AppColors.lightText),
        titleMedium: TextStyle(color: AppColors.lightText),
        titleSmall: TextStyle(color: AppColors.lightText),
        bodyLarge: TextStyle(color: AppColors.lightText),
        bodyMedium: TextStyle(color: AppColors.lightText),
        bodySmall: TextStyle(color: AppColors.lightTextMuted),
        labelLarge: TextStyle(color: AppColors.lightText),
        labelMedium: TextStyle(color: AppColors.lightText),
        labelSmall: TextStyle(color: AppColors.lightTextMuted),
      ),
      iconTheme: const IconThemeData(
        color: AppColors.lightText,
        size: 24,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.lightSurface,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.lightTextMuted,
        type: BottomNavigationBarType.fixed,
      ),
      dividerTheme: const DividerThemeData(
        color: Colors.transparent,
        thickness: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightSurface,
        selectedColor: AppColors.primary,
        labelStyle: const TextStyle(color: AppColors.lightText),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide.none,
        ),
      ),
    );
  }
  
  // Semantic color getters for easy access
  static Color get successColor => AppColors.success;
  static Color get warningColor => AppColors.warning;
  static Color get infoColor => AppColors.info;
  static Color get dangerColor => AppColors.danger;
} 