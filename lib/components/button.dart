import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../channel/params.dart';
import '../channel/view_types.dart';
import '../style/button_style.dart';
import '../style/button_theme.dart';
import '../utils/platform_view_builder.dart';
import '../style/image_placement.dart';
import '../style/sf_symbol.dart';
import '../utils/icon_renderer.dart';
import '../utils/theme_helper.dart';
import '../utils/version_detector.dart';
import 'icon.dart';

/// Configuration for CNButton with default values.
class CNButtonConfig extends Equatable {
  /// Padding for button content.
  /// If null, uses default EdgeInsets(top: 8.0, leading: 12.0, bottom: 8.0, trailing: 12.0).
  final EdgeInsets? padding;

  /// Border radius for button corners.
  /// If null, uses capsule shape (always round).
  final double? borderRadius;

  /// Minimum height for the button.
  final double? minHeight;

  /// Padding between image and text (spacing in HStack).
  final double? imagePadding;

  /// Image placement relative to text when both are present.
  final CNImagePlacement imagePlacement;

  /// Visual style to apply.
  final CNButtonStyle style;

  /// Fixed width used in icon/round mode.
  final double? width;

  /// If true, sizes the control to its intrinsic width.
  final bool shrinkWrap;

  /// Optional ID for glass effect union.
  ///
  /// When multiple buttons share the same `glassEffectUnionId`, they will
  /// be combined into a single unified Liquid Glass effect. This is useful
  /// for creating grouped button effects that appear as one cohesive shape.
  ///
  /// Only applies on iOS 26+ and macOS 26+ when using glass styles.
  final String? glassEffectUnionId;

  /// Optional ID for glass effect morphing transitions.
  ///
  /// When a button with a `glassEffectId` appears or disappears within a
  /// glass effect container, it will morph into/out of other buttons with
  /// the same ID or nearby buttons. This enables smooth transitions.
  ///
  /// Only applies on iOS 26+ and macOS 26+ when using glass styles.
  final String? glassEffectId;

  /// Whether to make the glass effect interactive.
  ///
  /// Interactive glass effects respond to touch and pointer interactions
  /// in real time, providing the same responsive reactions that glass
  /// provides to standard buttons.
  ///
  /// Only applies on iOS 26+ and macOS 26+ when using glass styles.
  final bool glassEffectInteractive;

  /// Maximum number of lines for button text.
  ///
  /// Defaults to 1 to prevent text wrapping. Set to null for unlimited lines.
  /// When limited, text will be truncated with ellipsis if too long.
  final int? maxLines;

  /// Creates a configuration for [CNButton].
  const CNButtonConfig({
    this.padding,
    this.borderRadius,
    this.minHeight,
    this.imagePadding,
    this.imagePlacement = CNImagePlacement.leading,
    this.style = CNButtonStyle.glass,
    this.width,
    this.shrinkWrap = false,
    this.glassEffectUnionId,
    this.glassEffectId,
    this.glassEffectInteractive = true,
    this.maxLines = 1,
  });

  @override
  List<Object?> get props => [
    padding,
    borderRadius,
    minHeight,
    imagePadding,
    imagePlacement,
    style,
    width,
    shrinkWrap,
    glassEffectUnionId,
    glassEffectId,
    glassEffectInteractive,
    maxLines,
  ];
}

/// A Cupertino-native push button.
///
/// Embeds a native UIButton/NSButton for authentic visuals and behavior on
/// iOS and macOS. Falls back to [CupertinoButton] on other platforms.
///
/// All buttons are round by default. Use [config] to customize appearance.
class CNButton extends StatefulWidget {
  /// Creates a text button variant of [CNButton].
  ///
  /// Can optionally include an [icon] to create a button with both text and icon.
  const CNButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.enabled = true,
    this.tint,
    this.theme = const CNButtonTheme(),
    this.config = const CNButtonConfig(),
  }) : super();

  /// Creates a round, icon-only variant of [CNButton].
  ///
  /// When padding, width, and minHeight are not provided in [config],
  /// the button will be automatically sized to be circular based on the icon size.
  ///
  /// [icon] must be provided.
  const CNButton.icon({
    super.key,
    required this.icon,
    this.onPressed,
    this.enabled = true,
    this.tint,
    this.theme = const CNButtonTheme(),
    this.config = const CNButtonConfig(style: CNButtonStyle.glass),
  }) : label = null,
       super();

  /// Button text (null in icon-only mode).
  final String? label;

  /// Icon/image asset for the button. Use [CNImageAsset.symbol], [CNImageAsset.xcasset],
  /// [CNImageAsset.asset], [CNImageAsset.png], [CNImageAsset.svg], etc.
  /// Priority: xcasset > asset/bytes > symbol.
  final CNImageAsset? icon;

  /// Callback when pressed.
  final VoidCallback? onPressed;

  /// Whether the control is interactive and tappable.
  final bool enabled;

  /// Accent/tint color.
  final Color? tint;

  /// Unified color and material theme. [theme.tint] takes priority over [tint].
  final CNButtonTheme theme;

  /// Button configuration.
  final CNButtonConfig config;

  /// Whether this instance has an icon.
  bool get isIcon => icon != null;

  /// Whether the button is round (always true).
  bool get round => true;

  @override
  State<CNButton> createState() => _CNButtonState();
}

class _CNButtonState extends State<CNButton> {
  MethodChannel? _channel;
  bool? _lastIsDark;
  int? _lastTint;
  String? _lastTitle;
  double? _intrinsicWidth;
  double? _intrinsicHeight;
  CNButtonStyle? _lastStyle;
  CNImagePlacement? _lastImagePlacement;
  double? _lastImagePadding;
  EdgeInsets? _lastPadding;
  Map<String, dynamic>? _lastIconMap;
  CNButtonTheme? _lastTheme;
  Offset? _downPosition;
  bool _pressed = false;
  Future<String>? _assetPathFuture;
  String? _lastAssetPath;

  bool get _isDark => ThemeHelper.isDark(context);

  Color? get _effectiveTint => widget.theme.tint ?? widget.tint;

  @override
  void dispose() {
    _channel?.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CNButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPropsToNativeIfNeeded();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncBrightnessIfNeeded();
    _syncPropsToNativeIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    final isIOSOrMacOS =
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
    final shouldUseNative =
        isIOSOrMacOS && PlatformVersion.shouldUseNativeGlass;

    if (!shouldUseNative) {
      if (!isIOSOrMacOS) return _buildMaterialFallback(context);
      return _buildCupertinoFallback(context);
    }

    // If the icon is an asset path source, resolve the path for pixel-ratio variants.
    // Cache the future so rebuilds don't create a new unresolved Future each time,
    // which would unmount and recreate the platform view on every setState.
    final assetPath = widget.icon?.toMap()['assetPath'] as String?;
    if (assetPath != null) {
      if (assetPath != _lastAssetPath) {
        _lastAssetPath = assetPath;
        _assetPathFuture = resolveAssetPathForPixelRatio(assetPath);
      }
      return FutureBuilder<String>(
        future: _assetPathFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            final defaultHeight = widget.config.minHeight ?? 44.0;
            return SizedBox(
              height: defaultHeight,
              width: widget.config.width ?? defaultHeight,
            );
          }
          return _buildNativeButton(context, resolvedAssetPath: snapshot.data!);
        },
      );
    }

    return _buildNativeButton(context);
  }

  Widget _buildNativeButton(BuildContext context, {String? resolvedAssetPath}) {
    const viewType = ViewTypes.cupertinoNativeButton;

    final iconMap = widget.icon?.toMap() ?? {};
    final iconWidth = (iconMap['iconWidth'] as double?) ?? 20.0;
    final iconHeight = (iconMap['iconHeight'] as double?) ?? 20.0;
    final iconColor = widget.icon?.color != null
        ? resolveColorToArgb(widget.icon!.color, context)
        : null;

    const double kMinimumTouchTarget = 44.0;
    final isIconButton = widget.isIcon && widget.label == null;
    EdgeInsets? effectivePadding = widget.config.padding;
    if (isIconButton &&
        effectivePadding == null &&
        widget.config.width == null &&
        widget.config.minHeight == null) {
      final calculatedSize = iconWidth + (iconWidth * 0.5) * 2;
      final finalSize = calculatedSize.clamp(
        kMinimumTouchTarget,
        double.infinity,
      );
      final calculatedPadding = (finalSize - iconWidth) / 2;
      effectivePadding = EdgeInsets.all(calculatedPadding);
    }

    final creationParams = <String, dynamic>{
      if (widget.label != null) 'buttonTitle': widget.label,
      if (iconMap['iconName'] != null) 'buttonIconName': iconMap['iconName'],
      if (iconMap['xcassetName'] != null)
        'buttonXcassetName': iconMap['xcassetName'],
      if (resolvedAssetPath != null)
        'buttonAssetPath': resolvedAssetPath
      else if (iconMap['assetPath'] != null)
        'buttonAssetPath': iconMap['assetPath'],
      if (iconMap['imageBytes'] != null)
        'buttonImageData': iconMap['imageBytes'],
      if (iconMap['imageFormat'] != null)
        'buttonImageFormat': iconMap['imageFormat'],
      if (widget.icon != null) ...{
        'buttonIconWidth': iconWidth,
        'buttonIconHeight': iconHeight,
        'buttonIconSize': iconWidth, // legacy key
      },
      if (iconMap['boxFit'] != null) 'buttonBoxFit': iconMap['boxFit'],
      if (iconColor != null) 'buttonIconColor': iconColor,
      if (widget.icon?.mode != null)
        'buttonIconRenderingMode': widget.icon!.mode!.name,
      'round': true,
      'buttonStyle': widget.config.style.name,
      'enabled': (widget.enabled && widget.onPressed != null),
      'isDark': _isDark,
      'style': encodeStyle(context, tint: _effectiveTint),
      'imagePlacement': widget.config.imagePlacement.name,
      if (widget.config.imagePadding != null)
        'imagePadding': widget.config.imagePadding,
      if (effectivePadding != null) ...{
        'paddingTop': effectivePadding.top,
        'paddingBottom': effectivePadding.bottom,
        'paddingLeft': effectivePadding.left,
        'paddingRight': effectivePadding.right,
        'paddingHorizontal': effectivePadding.left,
        'paddingVertical': effectivePadding.top,
      },
      if (widget.config.borderRadius != null)
        'borderRadius': widget.config.borderRadius,
      if (widget.config.minHeight != null) 'minHeight': widget.config.minHeight,
      if (widget.config.width != null) 'buttonWidth': widget.config.width,
      'buttonExpandWidth':
          !(widget.isIcon && widget.label == null) &&
          !widget.config.shrinkWrap &&
          widget.config.width == null,
      'glassMaterial': widget.theme.glassMaterial.name,
      if (widget.config.glassEffectUnionId != null)
        'glassEffectUnionId': widget.config.glassEffectUnionId,
      if (widget.config.glassEffectId != null)
        'glassEffectId': widget.config.glassEffectId,
      'glassEffectInteractive': widget.config.glassEffectInteractive,
      // CNButtonTheme colors
      if (resolveColorToArgb(widget.theme.labelColor, context) != null)
        'labelColor': resolveColorToArgb(widget.theme.labelColor, context),
      if (resolveColorToArgb(widget.theme.iconColor, context) != null)
        'themeIconColor': resolveColorToArgb(widget.theme.iconColor, context),
      if (resolveColorToArgb(widget.theme.backgroundColor, context) != null)
        'backgroundColor': resolveColorToArgb(
          widget.theme.backgroundColor,
          context,
        ),
    };

    final platformView = buildCupertinoPlatformView(
      context,
      viewType: viewType,
      creationParams: creationParams,
      onPlatformViewCreated: _onCreated,
      gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
        Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
      },
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final hasBoundedWidth = constraints.hasBoundedWidth;
        // Loose-width containers (e.g. Wrap) give children minWidth=0 with a
        // finite maxWidth.  Buttons should shrink to their content in this case
        // rather than expanding to fill the row and overlapping each other.
        final isLooseWidth = hasBoundedWidth && constraints.minWidth == 0;
        final preferIntrinsic =
            widget.config.shrinkWrap || !hasBoundedWidth || isLooseWidth;

        const double kMinimumTouchTarget = 44.0;
        double? calculatedSize;
        if (isIconButton &&
            widget.config.padding == null &&
            widget.config.width == null &&
            widget.config.minHeight == null) {
          calculatedSize = (iconWidth + (iconWidth * 0.5) * 2).clamp(
            kMinimumTouchTarget,
            double.infinity,
          );
        }

        final defaultHeight = widget.config.minHeight ?? calculatedSize ?? 44.0;
        double? width;
        if (isIconButton) {
          width = widget.config.width ?? calculatedSize ?? defaultHeight;
        } else if (preferIntrinsic) {
          width = _intrinsicWidth ?? (widget.isIcon ? 160.0 : 80.0);
        }

        final needsDynamicHeight = widget.icon != null;
        final isVerticalPlacement =
            widget.config.imagePlacement == CNImagePlacement.top ||
            widget.config.imagePlacement == CNImagePlacement.bottom;
        final height =
            (needsDynamicHeight &&
                isVerticalPlacement &&
                _intrinsicHeight != null)
            ? _intrinsicHeight!
            : defaultHeight;

        return Listener(
          onPointerDown: (e) {
            _downPosition = e.position;
            _setPressed(true);
          },
          onPointerMove: (e) {
            final start = _downPosition;
            if (start != null && _pressed) {
              final moved = (e.position - start).distance;
              if (moved > kTouchSlop) _setPressed(false);
            }
          },
          onPointerUp: (_) {
            _setPressed(false);
            _downPosition = null;
          },
          onPointerCancel: (_) {
            _setPressed(false);
            _downPosition = null;
          },
          child: ClipRect(
            child: SizedBox(height: height, width: width, child: platformView),
          ),
        );
      },
    );
  }

  void _onCreated(int id) {
    final ch = ViewTypes.methodChannelFor(ViewTypes.cupertinoNativeButton, id);
    _channel = ch;
    ch.setMethodCallHandler(_onMethodCall);
    _intrinsicWidth = null;
    _intrinsicHeight = null;
    _lastTint = resolveColorToArgb(_effectiveTint, context);
    _lastIsDark = _isDark;
    _lastTitle = widget.label;
    _lastStyle = widget.config.style;
    _lastImagePlacement = widget.config.imagePlacement;
    _lastImagePadding = widget.config.imagePadding;
    _lastPadding = widget.config.padding;
    _lastIconMap = widget.icon?.toMap();
    _lastTheme = widget.theme;
    scheduleMicrotask(() {
      if (mounted && _channel != null) _requestIntrinsicSize();
    });
  }

  Future<dynamic> _onMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'pressed':
        if (widget.enabled && widget.onPressed != null) {
          widget.onPressed!();
        }
        break;
    }
    return null;
  }

  Future<void> _requestIntrinsicSize() async {
    final ch = _channel;
    if (ch == null) return;
    try {
      final size = await ch.invokeMethod<Map>('getIntrinsicSize');
      final w = (size?['width'] as num?)?.toDouble();
      final h = (size?['height'] as num?)?.toDouble();
      if (mounted) {
        setState(() {
          if (w != null) _intrinsicWidth = w;
          if (h != null) _intrinsicHeight = h;
        });
      }
    } catch (_) {}
  }

  Future<void> _syncPropsToNativeIfNeeded() async {
    final ch = _channel;
    if (ch == null) return;

    // Resolve all colors before any async gap.
    final tint = resolveColorToArgb(_effectiveTint, context);
    final themeLabelColor = resolveColorToArgb(
      widget.theme.labelColor,
      context,
    );
    final themeIconColor = resolveColorToArgb(widget.theme.iconColor, context);
    final themeBackgroundColor = resolveColorToArgb(
      widget.theme.backgroundColor,
      context,
    );
    final capturedTheme = widget.theme;

    if (_lastTint != tint && tint != null) {
      await ch.invokeMethod('setStyle', <String, dynamic>{'tint': tint});
      _lastTint = tint;
    }
    if (_lastStyle != widget.config.style) {
      await ch.invokeMethod('setStyle', {
        'buttonStyle': widget.config.style.name,
      });
      _lastStyle = widget.config.style;
    }
    await ch.invokeMethod('setEnabled', {
      'enabled': (widget.enabled && widget.onPressed != null),
    });
    if (_lastTitle != widget.label && widget.label != null) {
      await ch.invokeMethod('setButtonTitle', {'title': widget.label});
      _lastTitle = widget.label;
      _requestIntrinsicSize();
    }
    if (_lastImagePlacement != widget.config.imagePlacement) {
      await ch.invokeMethod('setImagePlacement', {
        'placement': widget.config.imagePlacement.name,
      });
      _lastImagePlacement = widget.config.imagePlacement;
      _requestIntrinsicSize();
    }
    if (_lastImagePadding != widget.config.imagePadding) {
      if (widget.config.imagePadding != null) {
        await ch.invokeMethod('setImagePadding', {
          'padding': widget.config.imagePadding,
        });
      } else {
        await ch.invokeMethod('setImagePadding', null);
      }
      _lastImagePadding = widget.config.imagePadding;
      _requestIntrinsicSize();
    }
    if (_lastPadding != widget.config.padding) {
      _requestIntrinsicSize();
      _lastPadding = widget.config.padding;
    }

    // Sync icon
    if (widget.icon != null) {
      final currentMap = widget.icon!.toMap();
      if (!_iconMapsEqual(_lastIconMap, currentMap)) {
        final updates = <String, dynamic>{};

        if (currentMap['iconName'] != null) {
          updates['buttonIconName'] = currentMap['iconName'];
        }
        if (currentMap['xcassetName'] != null) {
          updates['buttonXcassetName'] = currentMap['xcassetName'];
        }
        final assetPath = currentMap['assetPath'] as String?;
        if (assetPath != null) {
          final resolved = await resolveAssetPathForPixelRatio(assetPath);
          if (!mounted) return;
          updates['buttonAssetPath'] = resolved;
        }
        if (currentMap['imageBytes'] != null) {
          updates['buttonImageData'] = currentMap['imageBytes'];
        }
        if (currentMap['imageFormat'] != null) {
          updates['buttonImageFormat'] = currentMap['imageFormat'];
        }
        final w = (currentMap['iconWidth'] as double?) ?? 20.0;
        final h = (currentMap['iconHeight'] as double?) ?? 20.0;
        updates['buttonIconWidth'] = w;
        updates['buttonIconHeight'] = h;
        updates['buttonIconSize'] = w;
        if (currentMap['boxFit'] != null) {
          updates['buttonBoxFit'] = currentMap['boxFit'];
        }
        if (widget.icon!.color != null && mounted) {
          updates['buttonIconColor'] = resolveColorToArgb(
            widget.icon!.color,
            context,
          );
        }
        if (widget.icon!.mode != null) {
          updates['buttonIconRenderingMode'] = widget.icon!.mode!.name;
        }

        if (updates.isNotEmpty) {
          await ch.invokeMethod('setButtonIcon', updates);
          _requestIntrinsicSize();
        }
        _lastIconMap = currentMap;
      }
    }

    // Sync theme colors — resolve all colors before async gap
    if (_lastTheme != widget.theme) {
      final themeUpdates = <String, dynamic>{
        'glassMaterial': widget.theme.glassMaterial.name,
      };
      if (tint != null) themeUpdates['tint'] = tint;
      if (themeLabelColor != null) themeUpdates['labelColor'] = themeLabelColor;
      if (themeIconColor != null) {
        themeUpdates['themeIconColor'] = themeIconColor;
      }
      if (themeBackgroundColor != null) {
        themeUpdates['backgroundColor'] = themeBackgroundColor;
      }
      await ch.invokeMethod('setStyle', themeUpdates);
      _lastTheme = capturedTheme;
    }
  }

  /// Shallow comparison of icon maps for change detection.
  bool _iconMapsEqual(Map<String, dynamic>? a, Map<String, dynamic>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }

  Future<void> _syncBrightnessIfNeeded() async {
    final ch = _channel;
    if (ch == null) return;
    final isDark = _isDark;
    final tint = resolveColorToArgb(_effectiveTint, context);
    if (_lastIsDark != isDark) {
      await ch.invokeMethod('setBrightness', {'isDark': isDark});
      _lastIsDark = isDark;
    }
    if (_lastTint != tint && tint != null) {
      await ch.invokeMethod('setStyle', <String, dynamic>{'tint': tint});
      _lastTint = tint;
    }
  }

  Future<void> _setPressed(bool pressed) async {
    final ch = _channel;
    if (ch == null) return;
    if (_pressed == pressed) return;
    _pressed = pressed;
    try {
      await ch.invokeMethod('setPressed', {'pressed': pressed});
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // Fallback renderers
  // ---------------------------------------------------------------------------

  /// Builds an icon widget for non-native fallback rendering.
  Widget? _buildFallbackIconWidget() {
    final icon = widget.icon;
    if (icon == null) return null;
    final map = icon.toMap();
    final symbolName = map['iconName'] as String?;
    final w = (map['iconWidth'] as double?) ?? 20.0;

    if (symbolName != null) {
      return CNIcon(
        symbol: CNSymbol(
          symbolName,
          size: w,
          color: icon.color,
          mode: icon.mode,
        ),
        size: w,
      );
    }
    // Non-symbol assets: show placeholder in non-native fallback.
    return Icon(CupertinoIcons.photo, size: w, color: icon.color);
  }

  Widget _buildCupertinoFallback(BuildContext context) {
    final iconWidget = _buildFallbackIconWidget();
    final iconSize = widget.icon?.size.width ?? 20.0;

    Widget child;
    final isIconOnlyButton = widget.isIcon && widget.label == null;
    if (isIconOnlyButton) {
      child = iconWidget ?? const SizedBox.shrink();
    } else if (iconWidget != null && widget.label != null) {
      child = _buildLabelWithIcon(iconWidget);
    } else {
      child = Text(
        widget.label ?? '',
        maxLines: widget.config.maxLines,
        overflow: widget.config.maxLines != null ? TextOverflow.ellipsis : null,
      );
    }

    const double kMinimumTouchTarget = 44.0;
    double? calculatedSize;
    EdgeInsets? effectivePadding = widget.config.padding;
    if (widget.isIcon &&
        widget.label == null &&
        effectivePadding == null &&
        widget.config.width == null &&
        widget.config.minHeight == null) {
      final calculatedSizeValue = iconSize + (iconSize * 0.5) * 2;
      calculatedSize = calculatedSizeValue.clamp(
        kMinimumTouchTarget,
        double.infinity,
      );
      effectivePadding = EdgeInsets.all((calculatedSize - iconSize) / 2);
    }

    final defaultHeight = widget.config.minHeight ?? calculatedSize ?? 44.0;
    final buttonWidth = isIconOnlyButton
        ? (widget.config.width ?? calculatedSize ?? defaultHeight)
        : null;
    final buttonPadding = isIconOnlyButton
        ? (effectivePadding ?? const EdgeInsets.all(8))
        : (widget.config.padding ??
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8));
    final borderRadius = widget.config.borderRadius ?? defaultHeight / 2;

    return SizedBox(
      height: defaultHeight,
      width: buttonWidth,
      child: CupertinoButton(
        // ignore: deprecated_member_use
        minSize: 0,
        padding: buttonPadding,
        borderRadius: BorderRadius.circular(borderRadius),
        pressedOpacity: 0.4,
        color: _getCupertinoButtonColor(context),
        onPressed: (widget.enabled && widget.onPressed != null)
            ? widget.onPressed
            : null,
        child: child,
      ),
    );
  }

  Widget _buildMaterialFallback(BuildContext context) {
    final iconWidget = _buildFallbackIconWidget();
    final iconSize = widget.icon?.size.width ?? 20.0;

    Widget child;
    final isIconOnlyButton = widget.isIcon && widget.label == null;
    if (isIconOnlyButton) {
      child = iconWidget ?? const SizedBox.shrink();
    } else if (iconWidget != null && widget.label != null) {
      child = _buildLabelWithIcon(iconWidget);
    } else {
      child = Text(
        widget.label ?? '',
        maxLines: widget.config.maxLines,
        overflow: widget.config.maxLines != null ? TextOverflow.ellipsis : null,
      );
    }

    const double kMinimumTouchTarget = 44.0;
    double? calculatedSize;
    EdgeInsets? effectivePadding = widget.config.padding;
    if (widget.isIcon &&
        widget.label == null &&
        effectivePadding == null &&
        widget.config.width == null &&
        widget.config.minHeight == null) {
      final calculatedSizeValue = iconSize + (iconSize * 0.5) * 2;
      calculatedSize = calculatedSizeValue.clamp(
        kMinimumTouchTarget,
        double.infinity,
      );
      effectivePadding = EdgeInsets.all((calculatedSize - iconSize) / 2);
    }

    final defaultHeight = widget.config.minHeight ?? calculatedSize ?? 44.0;
    return SizedBox(
      height: defaultHeight,
      width: isIconOnlyButton
          ? (widget.config.width ?? calculatedSize ?? defaultHeight)
          : null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: (widget.enabled && widget.onPressed != null)
              ? widget.onPressed
              : null,
          borderRadius: BorderRadius.circular(defaultHeight / 2),
          child: Container(
            padding: widget.isIcon
                ? (effectivePadding ?? const EdgeInsets.all(4))
                : (widget.config.padding ??
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4)),
            decoration: BoxDecoration(
              color: _getMaterialButtonColor(context),
              borderRadius: BorderRadius.circular(defaultHeight / 2),
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }

  Widget _buildLabelWithIcon(Widget iconWidget) {
    switch (widget.config.imagePlacement) {
      case CNImagePlacement.trailing:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.label ?? '',
              maxLines: widget.config.maxLines,
              overflow: widget.config.maxLines != null
                  ? TextOverflow.ellipsis
                  : null,
            ),
            if (widget.config.imagePadding != null)
              SizedBox(width: widget.config.imagePadding!),
            iconWidget,
          ],
        );
      case CNImagePlacement.top:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconWidget,
            if (widget.config.imagePadding != null)
              SizedBox(height: widget.config.imagePadding!),
            Text(
              widget.label ?? '',
              maxLines: widget.config.maxLines,
              overflow: widget.config.maxLines != null
                  ? TextOverflow.ellipsis
                  : null,
            ),
          ],
        );
      case CNImagePlacement.bottom:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.label ?? '',
              maxLines: widget.config.maxLines,
              overflow: widget.config.maxLines != null
                  ? TextOverflow.ellipsis
                  : null,
            ),
            if (widget.config.imagePadding != null)
              SizedBox(height: widget.config.imagePadding!),
            iconWidget,
          ],
        );
      default: // leading
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconWidget,
            if (widget.config.imagePadding != null)
              SizedBox(width: widget.config.imagePadding!),
            Text(
              widget.label ?? '',
              maxLines: widget.config.maxLines,
              overflow: widget.config.maxLines != null
                  ? TextOverflow.ellipsis
                  : null,
            ),
          ],
        );
    }
  }

  Color? _getCupertinoButtonColor(BuildContext context) {
    switch (widget.config.style) {
      case CNButtonStyle.filled:
      case CNButtonStyle.borderedProminent:
      case CNButtonStyle.prominentGlass:
        return _effectiveTint;
      case CNButtonStyle.glass:
        return _effectiveTint?.withValues(alpha: 0.1);
      default:
        return null;
    }
  }

  Color? _getMaterialButtonColor(BuildContext context) {
    switch (widget.config.style) {
      case CNButtonStyle.filled:
      case CNButtonStyle.borderedProminent:
      case CNButtonStyle.prominentGlass:
        return _effectiveTint ?? Theme.of(context).primaryColor;
      case CNButtonStyle.glass:
        return Theme.of(context).primaryColor.withValues(alpha: 0.1);
      default:
        return Colors.transparent;
    }
  }
}
