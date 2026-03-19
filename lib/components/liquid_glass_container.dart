import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../channel/params.dart';
import '../channel/view_types.dart';
import '../style/glass_effect.dart';
import '../utils/platform_view_builder.dart';
import '../utils/theme_helper.dart';
import '../utils/version_detector.dart';

/// A container that applies Liquid Glass effects to its child widget.
///
/// On iOS 26+ and macOS 26+, this uses native SwiftUI rendering to apply
/// the glass effect. On older versions or other platforms, the child is
/// returned unchanged.
class LiquidGlassContainer extends StatefulWidget {
  /// Creates a Liquid Glass container.
  ///
  /// The [child] is the widget to apply the glass effect to.
  /// The [config] contains the glass effect configuration.
  const LiquidGlassContainer({
    super.key,
    required this.child,
    required this.config,
  });

  /// The child widget to apply the glass effect to.
  final Widget child;

  /// The glass effect configuration.
  final LiquidGlassConfig config;

  @override
  State<LiquidGlassContainer> createState() => _LiquidGlassContainerState();
}

class _LiquidGlassContainerState extends State<LiquidGlassContainer> {
  MethodChannel? _channel;
  bool? _lastIsDark;
  // Stable key: never changes for the lifetime of this State so Flutter
  // always reuses the platform view instead of recreating it on config changes.
  // Config changes are applied via updateConfig over the method channel.
  final _viewKey = UniqueKey();

  bool get _isDark => ThemeHelper.isDark(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncBrightnessIfNeeded();
  }

  @override
  void didUpdateWidget(LiquidGlassContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config != widget.config) {
      _updateConfig();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIOSOrMacOS =
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
    final shouldUseNative = isIOSOrMacOS && PlatformVersion.supportsLiquidGlass;

    if (!shouldUseNative) {
      // On unsupported platforms or versions, just return the child
      return widget.child;
    }

    // For iOS 26+ and macOS 26+, use native LiquidGlassContainer
    return _buildNativeContainer(context);
  }

  Widget _buildNativeContainer(BuildContext context) {
    const viewType = ViewTypes.cupertinoNativeLiquidGlassContainer;

    // Convert config to creation params
    final creationParams = <String, dynamic>{
      'effect': widget.config.effect.name,
      'shape': widget.config.shape.name,
      if (widget.config.cornerRadius != null)
        'cornerRadius': widget.config.cornerRadius,
      if (widget.config.tint != null)
        'tint': resolveColorToArgb(widget.config.tint!, context),
      'interactive': widget.config.interactive,
      'isDark': ThemeHelper.isDark(context),
    };

    // Stable key: reuses the platform view across rebuilds; config changes
    // go through updateConfig via the method channel (no flash/recreation).
    final platformView = buildCupertinoPlatformView(
      context,
      key: _viewKey,
      viewType: viewType,
      creationParams: creationParams,
      onPlatformViewCreated: _onCreated,
    );

    // Stack sizes itself to its largest non-positioned child (widget.child).
    // Positioned.fill then fills those exact bounds with the native glass view.
    // IgnorePointer ensures the platform view never intercepts Flutter touches.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(child: IgnorePointer(child: platformView)),
        widget.child,
      ],
    );
  }

  void _onCreated(int id) {
    _channel = ViewTypes.methodChannelFor(
      ViewTypes.cupertinoNativeLiquidGlassContainer,
      id,
    );
    _channel!.setMethodCallHandler((call) async {
      // Handle any method calls from native side if needed
      return null;
    });
    _lastIsDark = _isDark;
  }

  Future<void> _updateConfig() async {
    final channel = _channel;
    if (channel == null) return;

    try {
      await channel.invokeMethod('updateConfig', {
        'effect': widget.config.effect.name,
        'shape': widget.config.shape.name,
        if (widget.config.cornerRadius != null)
          'cornerRadius': widget.config.cornerRadius,
        if (widget.config.tint != null)
          'tint': resolveColorToArgb(widget.config.tint!, context),
        'interactive': widget.config.interactive,
        'isDark': _isDark,
      });
    } catch (e) {
      // Ignore errors - view might not be ready yet
    }
  }

  Future<void> _syncBrightnessIfNeeded() async {
    final channel = _channel;
    if (channel == null) return;

    final isDark = _isDark;
    if (_lastIsDark != isDark) {
      _lastIsDark = isDark;
      // Trigger a view refresh to pick up the new system appearance
      await _updateConfig();
    }
  }
}
