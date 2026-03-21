import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

import 'glass_effect.dart';

/// Unified color and material theme for glass buttons.
///
/// When [tint] or [tintDark] is provided, it takes priority over
/// [labelColor]/[labelColorDark] and [iconColor]/[iconColorDark].
///
/// Example:
/// ```dart
/// CNButtonTheme(
///   tint: Colors.blue,
///   tintDark: Colors.lightBlue,
///   glassMaterial: CNButtonGlassMaterial.regular,
/// )
/// ```
class CNButtonTheme extends Equatable {
  /// Creates a button theme.
  const CNButtonTheme({
    this.tint,
    this.tintDark,
    this.labelColor,
    this.labelColorDark,
    this.iconColor,
    this.iconColorDark,
    this.glassMaterial = CNButtonGlassMaterial.regular,
  });

  /// Tint applied to both label and icon in light mode.
  /// Takes priority over [labelColor] and [iconColor].
  final Color? tint;

  /// Tint applied to both label and icon in dark mode.
  /// Takes priority over [labelColorDark] and [iconColorDark].
  final Color? tintDark;

  /// Text label color in light mode. Used when [tint] is null.
  final Color? labelColor;

  /// Text label color in dark mode. Used when [tintDark] is null.
  final Color? labelColorDark;

  /// Icon color in light mode. Used when [tint] is null.
  final Color? iconColor;

  /// Icon color in dark mode. Used when [tintDark] is null.
  final Color? iconColorDark;

  /// Glass material for the button effect on iOS 26+ / macOS 26+.
  final CNButtonGlassMaterial glassMaterial;

  @override
  List<Object?> get props => [
    tint,
    tintDark,
    labelColor,
    labelColorDark,
    iconColor,
    iconColorDark,
    glassMaterial,
  ];
}
