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
class CNSymbol {
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
}

/// Unified image source used by cupertino_native_plus widgets.
///
/// This abstracts over all supported image inputs:
/// - Native SF Symbols (`CNSymbol`)
/// - Flutter `IconData` rendered to an image
/// - Xcode asset catalog images (by name)
///
/// Other image variants are intentionally not modeled here to keep the public
/// API focused and predictable.
sealed class CNImageSource {
  const CNImageSource();

  /// SF Symbol-based image.
  const factory CNImageSource.symbol(CNSymbol symbol) = _CNSymbolImageSource;

  /// Image rendered from a Flutter [IconData].
  const factory CNImageSource.iconData(
    IconData iconData, {
    double? size,
    Color? color,
  }) = _CNIconDataImageSource;

  /// Image from an Xcode asset catalog.
  ///
  /// [name] is the asset name passed to `UIImage(named:)` / `NSImage(named:)`.
  const factory CNImageSource.xcasset(
    String name, {
    double? size,
    Color? color,
    CNSymbolRenderingMode? mode,
    bool? gradient,
    List<Color>? paletteColors,
  }) = _CNXcassetImageSource;

  /// Common effective size helper used by widgets when only a single size
  /// value is needed.
  double? effectiveSize() {
    return switch (this) {
      _CNSymbolImageSource s => s.symbol.size,
      _CNIconDataImageSource i => i.size,
      _CNXcassetImageSource x => x.size,
    };
  }
}

class _CNSymbolImageSource extends CNImageSource {
  const _CNSymbolImageSource(this.symbol);

  final CNSymbol symbol;
}

class _CNIconDataImageSource extends CNImageSource {
  const _CNIconDataImageSource(this.iconData, {this.size, this.color});

  final IconData iconData;
  final double? size;
  final Color? color;
}

class _CNXcassetImageSource extends CNImageSource {
  const _CNXcassetImageSource(
    this.name, {
    this.size,
    this.color,
    this.mode,
    this.gradient,
    this.paletteColors,
  });

  final String name;
  final double? size;
  final Color? color;
  final CNSymbolRenderingMode? mode;
  final bool? gradient;
  final List<Color>? paletteColors;
}
