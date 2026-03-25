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

  @override
  List<Object?> get props => [
    tint,
    labelColor,
    iconColor,
    backgroundColor,
    glassMaterial,
  ];
}
