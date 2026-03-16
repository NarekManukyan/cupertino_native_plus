import 'package:flutter/services.dart';

/// Centralized view-type identifiers for platform views.
///
/// Use these constants when creating UiKitView/AppKitView and when
/// registering method channels so Dart and native stay in sync.
abstract final class ViewTypes {
  ViewTypes._();

  /// View type for [CNButton].
  static const String cupertinoNativeButton = 'CupertinoNativeButton';

  /// View type for [CNGlassButtonGroup].
  static const String cupertinoNativeGlassButtonGroup =
      'CupertinoNativeGlassButtonGroup';

  /// View type for [CNIcon].
  static const String cupertinoNativeIcon = 'CupertinoNativeIcon';

  /// View type for [LiquidGlassContainer].
  static const String cupertinoNativeLiquidGlassContainer =
      'CupertinoNativeLiquidGlassContainer';

  /// View type for [CNPopupMenuButton].
  static const String cupertinoNativePopupMenuButton =
      'CupertinoNativePopupMenuButton';

  /// View type for [CNSegmentedControl].
  static const String cupertinoNativeSegmentedControl =
      'CupertinoNativeSegmentedControl';

  /// View type for [CNSlider].
  static const String cupertinoNativeSlider = 'CupertinoNativeSlider';

  /// View type for [CNSwitch].
  static const String cupertinoNativeSwitch = 'CupertinoNativeSwitch';

  /// View type for [CNTabBar].
  static const String cupertinoNativeTabBar = 'CupertinoNativeTabBar';

  /// View type for [CNFloatingIsland].
  static const String cnFloatingIsland = 'CNFloatingIsland';

  /// View type for [CNGlassCard] platform view.
  static const String cnGlassCardWithSpotlight = 'CNGlassCardWithSpotlight';

  /// Channel name prefix for [CNGlassCard] (method channel uses this + id).
  static const String cnGlassCard = 'CNGlassCard';

  /// View type for [CNSearchBar].
  static const String cnSearchBar = 'CNSearchBar';

  /// View type for [CNSearchScaffold].
  static const String cnSearchScaffold = 'CNSearchScaffold';

  /// Method channel name for the native tab bar (single channel, not per-view).
  static const String cnNativeTabBarChannel = 'cn_native_tab_bar';

  /// Returns a [MethodChannel] for the given [viewType] and [id].
  static MethodChannel methodChannelFor(String viewType, int id) {
    return MethodChannel('${viewType}_$id');
  }
}
