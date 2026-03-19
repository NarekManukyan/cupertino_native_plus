import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Utility class for accessing theme data with fallback support.
///
/// This class provides methods to access theme properties that work
/// even when CupertinoApp is not in the widget tree (e.g., when using
/// MaterialApp with autoroute or other routing solutions).
class ThemeHelper {
  /// Gets the brightness (light/dark mode) from the theme.
  ///
  /// Tries to get brightness from:
  /// 1. CupertinoTheme (if CupertinoApp is present)
  /// 2. Material Theme (if MaterialApp is present)
  /// 3. System brightness (fallback)
  static Brightness getBrightness(BuildContext context) {
    try {
      final cupertinoTheme = CupertinoTheme.of(context);
      final brightness = cupertinoTheme.brightness;
      // Don't fall back to Brightness.light here — if brightness is null the
      // CupertinoTheme hasn't been explicitly set, so cascade to the actual
      // system/material brightness instead.
      if (brightness != null) return brightness;
    } catch (_) {
      // CupertinoApp not in tree, fall through to Material / system checks.
    }
    // Try Material theme next
    try {
      return Theme.of(context).brightness;
    } catch (_) {}
    // Final fallback: real system brightness
    return MediaQuery.of(context).platformBrightness;
  }

  /// Gets the primary/accent color from the theme.
  ///
  /// Tries to get color from:
  /// 1. CupertinoTheme primaryColor (if CupertinoApp is present)
  /// 2. Material Theme primaryColor (if MaterialApp is present)
  /// 3. System blue (fallback)
  static Color getPrimaryColor(BuildContext context) {
    try {
      final cupertinoTheme = CupertinoTheme.of(context);
      return cupertinoTheme.primaryColor;
    } catch (_) {
      // CupertinoApp not in tree, try Material theme
      try {
        final materialTheme = Theme.of(context);
        return materialTheme.primaryColor;
      } catch (_) {
        // No theme found, use system blue as fallback
        return CupertinoColors.systemBlue;
      }
    }
  }

  /// Checks if the current theme is dark mode.
  static bool isDark(BuildContext context) {
    return getBrightness(context) == Brightness.dark;
  }
}
