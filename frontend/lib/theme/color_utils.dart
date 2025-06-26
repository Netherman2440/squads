import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Utility class for easy access to app colors and color manipulation
class ColorUtils {
  // Direct access to all colors
  static const Color bgDark = AppColors.bgDark;
  static const Color bg = AppColors.bg;
  static const Color bgLight = AppColors.bgLight;
  static const Color text = AppColors.text;
  static const Color textMuted = AppColors.textMuted;
  static const Color highlight = AppColors.highlight;
  static const Color border = AppColors.border;
  static const Color borderMuted = AppColors.borderMuted;
  static const Color primary = AppColors.primary;
  static const Color secondary = AppColors.secondary;
  static const Color danger = AppColors.danger;
  static const Color warning = AppColors.warning;
  static const Color success = AppColors.success;
  static const Color info = AppColors.info;

  /// Get semantic color based on status
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'completed':
      case 'won':
        return success;
      case 'warning':
      case 'pending':
      case 'draw':
        return warning;
      case 'error':
      case 'failed':
      case 'lost':
        return danger;
      case 'info':
      case 'info':
        return info;
      default:
        return textMuted;
    }
  }

  /// Create a color with opacity
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }

  /// Get a lighter version of a color
  static Color lighten(Color color, double amount) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
    return hslLight.toColor();
  }

  /// Get a darker version of a color
  static Color darken(Color color, double amount) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  /// Get background color based on elevation level
  static Color getBackgroundColor(int elevation) {
    switch (elevation) {
      case 0:
        return bg;
      case 1:
        return bgLight;
      case 2:
        return lighten(bgLight, 0.05);
      case 3:
        return lighten(bgLight, 0.1);
      default:
        return bgLight;
    }
  }

  /// Get text color based on background color
  static Color getTextColorForBackground(Color backgroundColor) {
    // Calculate luminance to determine if we need light or dark text
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? bgDark : text;
  }

  /// Create a gradient from two colors
  static LinearGradient createGradient(Color startColor, Color endColor, {
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
  }) {
    return LinearGradient(
      begin: begin,
      end: end,
      colors: [startColor, endColor],
    );
  }

  /// Create a primary gradient
  static LinearGradient get primaryGradient => createGradient(
    primary,
    secondary,
  );

  /// Create a background gradient
  static LinearGradient get backgroundGradient => createGradient(
    bgDark,
    bg,
  );
} 