import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

// ---------------------------------------------------------------------------
// Rendering mode
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Internal source type discriminator
// ---------------------------------------------------------------------------

enum _CNSourceType { symbol, xcasset, asset, bytes }

// ---------------------------------------------------------------------------
// CNIcon
// ---------------------------------------------------------------------------

/// Describes an image or icon asset for native rendering.
///
/// Use the named constructors to create assets from different sources:
/// - [CNIcon.symbol] — SF Symbol (system icon)
/// - [CNIcon.xcasset] — Image from the app's asset catalog
/// - [CNIcon.asset] — Flutter asset path (svg/png/jpg auto-detected)
/// - [CNIcon.svg] — SVG bytes
/// - [CNIcon.png] — PNG bytes
/// - [CNIcon.jpg] — JPG bytes
/// - [CNIcon.data] — Generic bytes with explicit format
class CNIcon extends Equatable {
  const CNIcon._({
    required _CNSourceType type,
    String? name,
    String? path,
    String? format,
    Uint8List? bytes,
    this.size = const Size(24, 24),
    this.fit = BoxFit.contain,
    this.color,
    this.mode,
  }) : _type = type,
       _name = name,
       _path = path,
       _format = format,
       _bytes = bytes;

  final _CNSourceType _type;
  // Symbol name or xcasset name.
  final String? _name;
  // Flutter asset path.
  final String? _path;
  // Format hint ('svg', 'png', 'jpg', etc.).
  final String? _format;
  // Raw bytes for bytes-based sources.
  final Uint8List? _bytes;

  /// Desired render size. Defaults to 24×24 points.
  final Size size;

  /// How the image should be scaled within [size]. Defaults to [BoxFit.contain].
  final BoxFit fit;

  /// Per-asset tint/icon color. Overridden by `CNButtonTheme` colors when set.
  final Color? color;

  /// Optional rendering mode (applies to SF Symbols).
  final CNSymbolRenderingMode? mode;

  // -------------------------------------------------------------------------
  // Named constructors
  // -------------------------------------------------------------------------

  /// SF Symbol — renders via `Image(systemName:)` in SwiftUI.
  const CNIcon.symbol(
    String name, {
    Size size = const Size(24, 24),
    Color? color,
    CNSymbolRenderingMode? mode,
    BoxFit fit = BoxFit.contain,
  }) : this._(
         type: _CNSourceType.symbol,
         name: name,
         size: size,
         color: color,
         mode: mode,
         fit: fit,
       );

  /// xcasset image from the app bundle — loaded via `UIImage(named:)`.
  const CNIcon.xcasset(
    String name, {
    Size size = const Size(24, 24),
    Color? color,
    BoxFit fit = BoxFit.contain,
  }) : this._(
         type: _CNSourceType.xcasset,
         name: name,
         size: size,
         color: color,
         fit: fit,
       );

  /// Flutter asset path — format is auto-detected from the file extension.
  const CNIcon.asset(
    String path, {
    Size size = const Size(24, 24),
    Color? color,
    String? format,
    BoxFit fit = BoxFit.contain,
  }) : this._(
         type: _CNSourceType.asset,
         path: path,
         format: format,
         size: size,
         color: color,
         fit: fit,
       );

  /// SVG bytes.
  const CNIcon.svg(
    Uint8List data, {
    Size size = const Size(24, 24),
    Color? color,
    BoxFit fit = BoxFit.contain,
  }) : this._(
         type: _CNSourceType.bytes,
         bytes: data,
         format: 'svg',
         size: size,
         color: color,
         fit: fit,
       );

  /// PNG bytes.
  const CNIcon.png(
    Uint8List data, {
    Size size = const Size(24, 24),
    Color? color,
    BoxFit fit = BoxFit.contain,
  }) : this._(
         type: _CNSourceType.bytes,
         bytes: data,
         format: 'png',
         size: size,
         color: color,
         fit: fit,
       );

  /// JPG bytes.
  const CNIcon.jpg(
    Uint8List data, {
    Size size = const Size(24, 24),
    Color? color,
    BoxFit fit = BoxFit.contain,
  }) : this._(
         type: _CNSourceType.bytes,
         bytes: data,
         format: 'jpg',
         size: size,
         color: color,
         fit: fit,
       );

  /// Generic bytes with an explicit format string (e.g. `'png'`, `'svg'`).
  const CNIcon.data(
    Uint8List bytes,
    String format, {
    Size size = const Size(24, 24),
    Color? color,
    BoxFit fit = BoxFit.contain,
  }) : this._(
         type: _CNSourceType.bytes,
         bytes: bytes,
         format: format,
         size: size,
         color: color,
         fit: fit,
       );

  // -------------------------------------------------------------------------
  // Serialization
  // -------------------------------------------------------------------------

  /// Returns the serialization dict entries for this asset (without color).
  /// Callers should merge in `iconColor` separately using a resolved ARGB int.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'iconWidth': size.width,
      'iconHeight': size.height,
      'boxFit': fit.name,
    };
    switch (_type) {
      case _CNSourceType.symbol:
        map['iconName'] = _name;
      case _CNSourceType.xcasset:
        map['xcassetName'] = _name;
      case _CNSourceType.asset:
        map['assetPath'] = _path;
        if (_format != null) map['imageFormat'] = _format;
      case _CNSourceType.bytes:
        map['imageBytes'] = _bytes;
        map['imageFormat'] = _format;
    }
    return map;
  }

  // -------------------------------------------------------------------------
  // Backward-compat accessors (used by CNIconView, CNTabBar, CNPopupMenuButton)
  // -------------------------------------------------------------------------

  /// Flutter asset path for [CNIcon.asset] sources. Empty string otherwise.
  String get assetPath => _path ?? '';

  /// xcasset catalog name for [CNIcon.xcasset] sources. Null otherwise.
  String? get xcassetName => _type == _CNSourceType.xcasset ? _name : null;

  /// Raw bytes for bytes-based sources. Null otherwise.
  Uint8List? get imageData => _bytes;

  /// Format string for bytes/asset sources ('svg', 'png', 'jpg'). Null otherwise.
  String? get imageFormat => _format;

  /// Gradient rendering flag. Always null — gradient was removed in 0.0.7.
  bool? get gradient => null;

  @override
  List<Object?> get props => [
    _type,
    _name,
    _path,
    _format,
    _bytes,
    size,
    fit,
    color,
    mode,
  ];
}

// ---------------------------------------------------------------------------
// CNSymbol (legacy — kept for source compatibility)
// ---------------------------------------------------------------------------

/// Describes an SF Symbol to render natively.
///
/// Prefer [CNIcon.symbol] for new code.
class CNSymbol extends Equatable {
  /// The SF Symbol name, e.g. `chevron.down`.
  final String name;

  /// Desired point size for the symbol.
  final double size;

  /// Preferred icon color (for monochrome/hierarchical modes).
  final Color? color;

  /// Palette colors for multi-color/palette modes.
  final List<Color>? paletteColors;

  /// Optional per-icon rendering mode.
  final CNSymbolRenderingMode? mode;

  /// Whether to enable the built-in gradient when available.
  final bool? gradient;

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
