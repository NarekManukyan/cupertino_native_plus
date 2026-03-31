import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

import 'glass_effect.dart';

/// Unified color and material theme for glass buttons.
///
/// When [tint] is provided, it takes priority over [labelColor] and [iconColor].
///
/// Example:
/// ```dart
/// CNButtonTheme(
///   tint: Colors.blue,
///   backgroundColor: Colors.blue.withOpacity(0.2),
///   glassMaterial: CNButtonGlassMaterial.regular,
/// )
/// ```
class CNButtonTheme extends Equatable {
  /// Creates a button theme.
  const CNButtonTheme({
    this.tint,
    this.labelColor,
    this.iconColor,
    this.backgroundColor,
    this.glassMaterial = CNButtonGlassMaterial.regular,
    this.labelStyle,
  });

  /// Tint applied to both label and icon. Takes priority over [labelColor] and [iconColor].
  final Color? tint;

  /// Text label color. Used when [tint] is null.
  final Color? labelColor;

  /// Icon color. Used when [tint] is null.
  final Color? iconColor;

  /// Glass background tint color.
  final Color? backgroundColor;

  /// Glass material for the button effect on iOS 26+ / macOS 26+.
  final CNButtonGlassMaterial glassMaterial;

  /// Optional text style for the button label.
  ///
  /// When set, overrides the default label font, size, weight, and color on
  /// supported platforms. On native iOS/macOS this is applied via attributed
  /// title; on the Flutter fallback it is passed directly to [Text.style].
  final TextStyle? labelStyle;

  /// Creates a copy of this theme with the given fields replaced.
  CNButtonTheme copyWith({
    Color? tint,
    Color? labelColor,
    Color? iconColor,
    Color? backgroundColor,
    CNButtonGlassMaterial? glassMaterial,
    TextStyle? labelStyle,
  }) {
    return CNButtonTheme(
      tint: tint ?? this.tint,
      labelColor: labelColor ?? this.labelColor,
      iconColor: iconColor ?? this.iconColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      glassMaterial: glassMaterial ?? this.glassMaterial,
      labelStyle: labelStyle ?? this.labelStyle,
    );
  }

  @override
  List<Object?> get props => [
    tint,
    labelColor,
    iconColor,
    backgroundColor,
    glassMaterial,
    labelStyle,
  ];
}
