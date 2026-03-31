import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../channel/params.dart';
import '../channel/view_types.dart';
import '../style/glass_effect.dart';
import '../utils/platform_view_builder.dart';
import '../utils/theme_helper.dart';
import '../utils/version_detector.dart';

/// A native text widget with a Liquid Glass effect applied.
///
/// On iOS 26+, renders text using native SwiftUI `glassEffect()`.
/// On older platforms or non-iOS, falls back to a plain [Text] widget.
///
/// Example:
/// ```dart
/// CNLiquidText(
///   text: 'Hello',
///   fontSize: 18,
///   fontWeight: FontWeight.semiBold,
///   glassConfig: LiquidGlassConfig(interactive: true),
///   padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
/// )
/// ```
class CNLiquidText extends StatefulWidget {
  /// Creates a native text widget with a Liquid Glass effect.
  const CNLiquidText({
    super.key,
    required this.text,
    this.fontSize = 16.0,
    this.fontWeight = FontWeight.normal,
    this.textColor,
    this.glassConfig = const LiquidGlassConfig(),
    this.padding = const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
    this.fallbackStyle,
  });

  /// The text to display.
  final String text;

  /// Font size in logical pixels.
  final double fontSize;

  /// Font weight. Mapped to the nearest Swift `Font.Weight` value.
  final FontWeight fontWeight;

  /// Optional text color. When null, the native side uses semantic `.primary`.
  final Color? textColor;

  /// Glass effect configuration (shape, tint, interactive, …).
  final LiquidGlassConfig glassConfig;

  /// Padding around the text inside the glass bubble.
  final EdgeInsets padding;

  /// [TextStyle] used on platforms where the native view is not available.
  final TextStyle? fallbackStyle;

  @override
  State<CNLiquidText> createState() => _CNLiquidTextState();
}

class _CNLiquidTextState extends State<CNLiquidText> {
  MethodChannel? _channel;
  bool? _lastIsDark;
  final _viewKey = UniqueKey();

  bool get _isDark => ThemeHelper.isDark(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncBrightnessIfNeeded();
  }

  @override
  void didUpdateWidget(CNLiquidText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.fontSize != widget.fontSize ||
        oldWidget.fontWeight != widget.fontWeight ||
        oldWidget.textColor != widget.textColor ||
        oldWidget.glassConfig != widget.glassConfig ||
        oldWidget.padding != widget.padding) {
      _updateConfig();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.iOS ||
        !PlatformVersion.supportsLiquidGlass) {
      return Text(
        widget.text,
        style:
            widget.fallbackStyle ??
            TextStyle(fontSize: widget.fontSize, color: widget.textColor),
      );
    }

    return buildCupertinoPlatformView(
      context,
      key: _viewKey,
      viewType: ViewTypes.cnLiquidText,
      creationParams: _buildParams(context),
      onPlatformViewCreated: _onCreated,
    );
  }

  // MARK: - Helpers

  Map<String, dynamic> _buildParams(BuildContext context) {
    final config = widget.glassConfig;
    return {
      'text': widget.text,
      'fontSize': widget.fontSize,
      'fontWeight': _fontWeightName(widget.fontWeight),
      if (widget.textColor != null)
        'textColor': resolveColorToArgb(widget.textColor, context),
      'shape': config.shape.name,
      if (config.cornerRadius != null) 'cornerRadius': config.cornerRadius,
      if (config.tint != null) 'tint': resolveColorToArgb(config.tint, context),
      'interactive': config.interactive,
      'paddingTop': widget.padding.top,
      'paddingBottom': widget.padding.bottom,
      'paddingLeft': widget.padding.left,
      'paddingRight': widget.padding.right,
      'isDark': _isDark,
    };
  }

  void _onCreated(int id) {
    _channel = ViewTypes.methodChannelFor(ViewTypes.cnLiquidText, id);
    _lastIsDark = _isDark;
  }

  Future<void> _updateConfig() async {
    final channel = _channel;
    if (channel == null) return;
    try {
      await channel.invokeMethod('updateConfig', _buildParams(context));
    } catch (_) {}
  }

  Future<void> _syncBrightnessIfNeeded() async {
    final channel = _channel;
    if (channel == null) return;
    final isDark = _isDark;
    if (_lastIsDark != isDark) {
      _lastIsDark = isDark;
      await _updateConfig();
    }
  }

  /// Maps Flutter [FontWeight] to the Swift Font.Weight name expected by native.
  static String _fontWeightName(FontWeight w) {
    // FontWeight.values index goes from 0 (w100) to 8 (w900)
    const names = [
      'ultraLight', // w100
      'thin', // w200
      'light', // w300
      'regular', // w400
      'medium', // w500
      'semibold', // w600
      'bold', // w700
      'heavy', // w800
      'black', // w900
    ];
    final index = FontWeight.values.indexOf(w);
    return index >= 0 ? names[index] : 'regular';
  }
}
