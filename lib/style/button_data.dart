import 'package:flutter/widgets.dart';

import 'button_style.dart';
import 'button_theme.dart';
import 'sf_symbol.dart';
import 'image_placement.dart';

/// Data model for button configuration in CNGlassButtonGroup.
///
/// This class holds all the properties needed to render a button without
/// being a widget itself. Use this with [CNGlassButtonGroup] for cleaner
/// data-driven button groups.
///
/// Example:
/// ```dart
/// CNGlassButtonGroup(
///   buttons: [
///     CNButtonData.icon(
///       icon: CNIcon.symbol('house'),
///       onPressed: () => print('Home'),
///     ),
///     CNButtonData.icon(
///       icon: CNIcon.symbol('gear'),
///       onPressed: () => print('Settings'),
///     ),
///   ],
/// )
/// ```
class CNButtonData {
  /// Creates a button data model with a label.
  const CNButtonData({
    required this.label,
    this.icon,
    this.onPressed,
    this.enabled = true,
    this.theme = const CNButtonTheme(),
    this.config = const CNButtonDataConfig(),
  }) : isIcon = false;

  /// Creates an icon-only button data model.
  const CNButtonData.icon({
    this.icon,
    this.onPressed,
    this.enabled = true,
    this.theme = const CNButtonTheme(),
    this.config = const CNButtonDataConfig(),
  }) : label = null,
       isIcon = true;

  /// The text label for the button. Null for icon-only buttons.
  final String? label;

  /// Image/icon asset to display. Use [CNIcon.symbol], [CNIcon.xcasset],
  /// [CNIcon.asset], [CNIcon.png], [CNIcon.svg], etc.
  final CNIcon? icon;

  /// Callback when the button is pressed.
  final VoidCallback? onPressed;

  /// Whether the button is enabled.
  final bool enabled;

  /// Color and material theme for this button.
  final CNButtonTheme theme;

  /// Configuration for the button appearance.
  final CNButtonDataConfig config;

  /// Whether this is an icon-only button.
  final bool isIcon;

  /// Creates a copy of this data with the given fields replaced.
  CNButtonData copyWith({
    String? label,
    CNIcon? icon,
    VoidCallback? onPressed,
    bool? enabled,
    CNButtonTheme? theme,
    CNButtonDataConfig? config,
  }) {
    if (isIcon) {
      return CNButtonData.icon(
        icon: icon ?? this.icon,
        onPressed: onPressed ?? this.onPressed,
        enabled: enabled ?? this.enabled,
        theme: theme ?? this.theme,
        config: config ?? this.config,
      );
    }
    return CNButtonData(
      label: label ?? this.label!,
      icon: icon ?? this.icon,
      onPressed: onPressed ?? this.onPressed,
      enabled: enabled ?? this.enabled,
      theme: theme ?? this.theme,
      config: config ?? this.config,
    );
  }
}

/// Configuration options for CNButtonData.
///
/// This mirrors [CNButtonConfig] but is designed for data models rather
/// than direct widget usage.
class CNButtonDataConfig {
  /// Creates button data configuration.
  const CNButtonDataConfig({
    this.width,
    this.style = CNButtonStyle.glass,
    this.padding,
    this.borderRadius,
    this.minHeight,
    this.imagePadding,
    this.imagePlacement,
    this.glassEffectUnionId,
    this.glassEffectId,
    this.glassEffectInteractive = true,
  });

  /// Fixed width for the button.
  final double? width;

  /// Visual style of the button.
  final CNButtonStyle style;

  /// Internal padding.
  final EdgeInsets? padding;

  /// Corner radius for the button.
  final double? borderRadius;

  /// Minimum height constraint.
  final double? minHeight;

  /// Spacing between icon/image and label.
  final double? imagePadding;

  /// Position of the image relative to the label.
  final CNImagePlacement? imagePlacement;

  /// Glass effect union ID for effect blending.
  final String? glassEffectUnionId;

  /// Glass effect ID for individual effect identification.
  final String? glassEffectId;

  /// Whether the glass effect responds to touches.
  final bool glassEffectInteractive;

  /// Creates a copy with the given fields replaced.
  CNButtonDataConfig copyWith({
    double? width,
    CNButtonStyle? style,
    EdgeInsets? padding,
    double? borderRadius,
    double? minHeight,
    double? imagePadding,
    CNImagePlacement? imagePlacement,
    String? glassEffectUnionId,
    String? glassEffectId,
    bool? glassEffectInteractive,
  }) {
    return CNButtonDataConfig(
      width: width ?? this.width,
      style: style ?? this.style,
      padding: padding ?? this.padding,
      borderRadius: borderRadius ?? this.borderRadius,
      minHeight: minHeight ?? this.minHeight,
      imagePadding: imagePadding ?? this.imagePadding,
      imagePlacement: imagePlacement ?? this.imagePlacement,
      glassEffectUnionId: glassEffectUnionId ?? this.glassEffectUnionId,
      glassEffectId: glassEffectId ?? this.glassEffectId,
      glassEffectInteractive:
          glassEffectInteractive ?? this.glassEffectInteractive,
    );
  }
}
