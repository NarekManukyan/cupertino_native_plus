import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';

/// Rendering modes for SF Symbols.
enum CNSymbolRenderingMode {
  /// Single-color glyph.
  monochrome,

  /// Hierarchical (shaded) rendering.
  hierarchical,

  /// Uses provided palette colors.
  palette,

  /// Uses built-in multicolor assets.
  multicolor,
}

/// Describes an SF Symbol to render natively.
class CNSymbol extends Equatable {
  /// The SF Symbol name, e.g. `chevron.down`.
  final String name;

  /// Desired point size for the symbol.
  final double size; // point size
  /// Preferred icon color (for monochrome/hierarchical modes).
  final Color? color; // preferred icon color (monochrome/hierarchical)
  /// Palette colors for multi-color/palette modes.
  final List<Color>? paletteColors; // multi-color palette
  /// Optional per-icon rendering mode.
  final CNSymbolRenderingMode? mode; // per-icon rendering mode
  /// Whether to enable the built-in gradient when available.
  final bool? gradient; // prefer built-in gradient when available

  /// Creates a symbol description for native rendering.
  const CNSymbol(
    this.name, {
    this.size = 24.0,
    this.color,
    this.paletteColors,
    this.mode,
    this.gradient,
  });

  @override
  List<Object?> get props => [name, size, color, paletteColors, mode, gradient];
}

/// Describes a custom image asset to render natively.
class CNImageAsset extends Equatable {
  /// Flutter asset path (e.g., 'assets/icons/my_icon.svg').
  final String assetPath;

  /// Raw image data (PNG, SVG, etc. bytes).
  /// If provided, this takes precedence over [assetPath].
  final Uint8List? imageData;

  /// Image format hint for [imageData] ('png', 'svg', 'jpg', etc.).
  /// Used by native code to determine how to process the data.
  final String? imageFormat;

  /// Desired point size for the image.
  final double size;

  /// Preferred image color (for monochrome rendering).
  final Color? color;

  /// Optional rendering mode.
  final CNSymbolRenderingMode? mode;

  /// Whether to enable gradient effects when available.
  final bool? gradient;

  /// Optional name of an xcasset image in the host app bundle.
  ///
  /// When provided, native code prefers this over [assetPath] and [imageData]
  /// and loads the image via `UIImage(named:)` / NSImage equivalents.
  final String? xcassetName;

  /// Creates an image asset description for native rendering.
  const CNImageAsset(
    this.assetPath, {
    this.imageData,
    this.imageFormat,
    this.size = 24.0,
    this.color,
    this.mode,
    this.gradient,
    this.xcassetName,
  });

  @override
  List<Object?> get props => [
    assetPath,
    imageData,
    imageFormat,
    size,
    color,
    mode,
    gradient,
    xcassetName,
  ];

  /// Convenience constructor for xcasset-backed images.
  ///
  /// Uses [xcassetName] and leaves [assetPath] empty so that native code
  /// can load the image directly from the app bundle.
  const CNImageAsset.xcasset(
    String xcassetName, {
    double size = 24.0,
    Color? color,
    CNSymbolRenderingMode? mode,
    bool? gradient,
  }) : this(
         '',
         size: size,
         color: color,
         mode: mode,
         gradient: gradient,
         xcassetName: xcassetName,
       );
}
