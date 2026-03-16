import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

/// Shared types and encoding for platform view creation params.
///
/// Common param keys sent to native (keep in sync with Swift ChannelConstants / view parsers):
/// - **Style (ARGB ints):** `tint`, `thumbTint`, `trackTint`, `trackBackgroundTint`, `iconColor`, `backgroundColor`
/// - **Layout:** `cornerRadius`, `effect`, `shape`, `interactive`, `isDark`
/// - **Control state:** `value`, `min`, `max`, `enabled`, `step`, `selectedIndex`
/// Use [encodeStyle] and [resolveColorToArgb] for style maps so keys stay consistent.

/// Codec used for platform view creation params. Use with [UiKitView] / [AppKitView].
const StandardMessageCodec creationParamsCodec = StandardMessageCodec();

/// Converts a [Color] to ARGB int (0xAARRGGBB). Private helper.
int? _argbFromColor(Color? color) {
  if (color == null) return null;
  // Use component accessors recommended by lints (.a/.r/.g/.b as doubles 0..1)
  final a = (color.a * 255.0).round() & 0xff;
  final r = (color.r * 255.0).round() & 0xff;
  final g = (color.g * 255.0).round() & 0xff;
  final b = (color.b * 255.0).round() & 0xff;
  return (a << 24) | (r << 16) | (g << 8) | b;
}

/// Resolves a possibly dynamic Cupertino color to a concrete ARGB int
/// for the current [BuildContext]. Falls back to the raw color if not dynamic.
int? resolveColorToArgb(Color? color, BuildContext context) {
  if (color == null) return null;
  if (color is CupertinoDynamicColor) {
    final resolved = color.resolveFrom(context);
    return _argbFromColor(resolved);
  }
  return _argbFromColor(color);
}

/// Creates a unified style map for platform views.
/// Keys (all ARGB ints):
/// - tint: general accent color
/// - thumbTint: slider/switch thumb color
/// - trackTint: active track color
/// - trackBackgroundTint: inactive track color
Map<String, dynamic> encodeStyle(
  BuildContext context, {
  Color? tint,
  Color? thumbTint,
  Color? trackTint,
  Color? trackBackgroundTint,
}) {
  final style = <String, dynamic>{};
  final tintInt = resolveColorToArgb(tint, context);
  final thumbInt = resolveColorToArgb(thumbTint, context);
  final trackInt = resolveColorToArgb(trackTint, context);
  final trackBgInt = resolveColorToArgb(trackBackgroundTint, context);
  if (tintInt != null) style['tint'] = tintInt;
  if (thumbInt != null) style['thumbTint'] = thumbInt;
  if (trackInt != null) style['trackTint'] = trackInt;
  if (trackBgInt != null) style['trackBackgroundTint'] = trackBgInt;
  return style;
}
