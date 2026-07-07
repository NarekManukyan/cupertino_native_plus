import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../channel/view_types.dart';
import '../style/sf_symbol.dart';
import '../utils/icon_renderer.dart';
import '../utils/version_detector.dart';

/// iOS 26+ Native Tab Bar with Search Support
///
/// This enables the native iOS 26 tab bar with search functionality.
/// When enabled, it replaces the Flutter app's root with a native UITabBarController,
/// giving you the true iOS 26 liquid glass morphing search effect.
///
/// **Important**: This replaces your app's root view controller.
/// The Flutter content will be displayed within the selected tab.
///
/// Example:
/// ```dart
/// @override
/// void initState() {
///   super.initState();
///   CNTabBarNative.enable(
///     tabs: [
///       CNTab(title: 'Home', sfSymbol: CNSymbol('house.fill')),
///       CNTab(title: 'Search', sfSymbol: CNSymbol('magnifyingglass'), isSearchTab: true),
///       CNTab(title: 'Profile', sfSymbol: CNSymbol('person.fill')),
///     ],
///     onTabSelected: (index) {
///       setState(() => _selectedIndex = index);
///     },
///     onSearchChanged: (query) {
///       print('Search query: $query');
///     },
///   );
/// }
///
/// @override
/// void dispose() {
///   CNTabBarNative.disable();
///   super.dispose();
/// }
/// ```
class CNTabBarNative {
  static const MethodChannel _channel = MethodChannel(
    ViewTypes.cnNativeTabBarChannel,
  );

  static bool _isEnabled = false;
  static void Function(int index)? _onTabSelected;
  static void Function(String query)? _onSearchChanged;
  static void Function(String query)? _onSearchSubmitted;
  static VoidCallback? _onSearchCancelled;
  static void Function(bool isActive)? _onSearchActiveChanged;

  /// Enable native tab bar mode
  ///
  /// This will replace your app's root view controller with a native
  /// UITabBarController. Your Flutter content will be displayed within
  /// the selected tab.
  ///
  /// Pass [textDirection] (e.g. `Directionality.of(context)`) so the native
  /// tab bar mirrors its layout for right-to-left locales.
  ///
  /// Only works on iOS 26+. On older versions, this is a no-op.
  static Future<void> enable({
    required List<CNTab> tabs,
    int selectedIndex = 0,
    void Function(int index)? onTabSelected,
    void Function(String query)? onSearchChanged,
    void Function(String query)? onSearchSubmitted,
    VoidCallback? onSearchCancelled,
    void Function(bool isActive)? onSearchActiveChanged,
    Color? tintColor,
    Color? unselectedTintColor,
    bool? isDark,
    bool shrinkWhileScroll = false,
    double shrinkOffset = 16,
    List<int?>? badgeCounts,
    CNTabBarMinimizeBehavior minimizeBehavior =
        CNTabBarMinimizeBehavior.automatic,
    TextDirection textDirection = TextDirection.ltr,
  }) async {
    assert(
      badgeCounts == null || badgeCounts.length == tabs.length,
      'badgeCounts.length must match tabs.length',
    );
    // Only works on iOS 26+
    if (defaultTargetPlatform != TargetPlatform.iOS ||
        !PlatformVersion.shouldUseNativeGlass) {
      return;
    }

    if (_isEnabled) {
      return;
    }

    // Store callbacks
    _onTabSelected = onTabSelected;
    _onSearchChanged = onSearchChanged;
    _onSearchSubmitted = onSearchSubmitted;
    _onSearchCancelled = onSearchCancelled;
    _onSearchActiveChanged = onSearchActiveChanged;

    // Setup method call handler for callbacks
    _channel.setMethodCallHandler(_handleMethodCall);

    // Resolve Flutter asset paths for custom icons (skipped for xcasset
    // entries, which the native side loads directly by name).
    final imageAssetPaths = await Future.wait(
      tabs.map((tab) async {
        final icon = tab.icon;
        if (icon == null ||
            icon.assetPath.isEmpty ||
            (icon.xcassetName ?? '').isNotEmpty) {
          return '';
        }
        return resolveAssetPathForPixelRatio(icon.assetPath);
      }),
    );
    final activeImageAssetPaths = await Future.wait(
      tabs.map((tab) async {
        final icon = tab.activeIcon;
        if (icon == null ||
            icon.assetPath.isEmpty ||
            (icon.xcassetName ?? '').isNotEmpty) {
          return '';
        }
        return resolveAssetPathForPixelRatio(icon.assetPath);
      }),
    );

    // Enable native tab bar
    await _channel.invokeMethod('enable', {
      'tabs': [
        for (var i = 0; i < tabs.length; i++)
          {
            'title': tabs[i].title,
            'sfSymbol':
                tabs[i].icon?.toMap()['iconName'] as String? ??
                tabs[i].sfSymbol?.name,
            'activeSfSymbol':
                tabs[i].activeIcon?.toMap()['iconName'] as String? ??
                tabs[i].activeSfSymbol?.name,
            'xcassetName': tabs[i].icon?.xcassetName ?? '',
            'activeXcassetName': tabs[i].activeIcon?.xcassetName ?? '',
            'imageAssetPath': imageAssetPaths[i],
            'activeImageAssetPath': activeImageAssetPaths[i],
            'imageData': tabs[i].icon?.imageData,
            'activeImageData': tabs[i].activeIcon?.imageData,
            'imageFormat':
                tabs[i].icon?.imageFormat ??
                detectImageFormat(imageAssetPaths[i], tabs[i].icon?.imageData),
            'activeImageFormat':
                tabs[i].activeIcon?.imageFormat ??
                detectImageFormat(
                  activeImageAssetPaths[i],
                  tabs[i].activeIcon?.imageData,
                ),
            'isSearch': tabs[i].isSearchTab,
            'badgeCount': tabs[i].badgeCount,
          },
      ],
      'selectedIndex': selectedIndex,
      'isDark': isDark ?? false,
      'shrinkWhileScroll': shrinkWhileScroll,
      'shrinkOffset': shrinkOffset,
      'badgeCounts': badgeCounts,
      'minimizeBehavior': minimizeBehavior.rawValue,
      'isRTL': textDirection == TextDirection.rtl,
      if (tintColor != null) 'tint': tintColor.toARGB32(),
      if (unselectedTintColor != null)
        'unselectedTint': unselectedTintColor.toARGB32(),
    });

    _isEnabled = true;
  }

  /// Disables the native tab bar and restores Flutter-only mode.
  ///
  /// Call this in [State.dispose] of the widget that called [enable].
  /// No-op when the native tab bar is not already enabled, unless
  /// [forceDisable] is `true`, which sends the disable call regardless
  /// of tracked state (useful to recover from a desynced [_isEnabled] flag).
  static Future<void> disable({bool forceDisable = false}) async {
    if (!_isEnabled && !forceDisable) {
      return;
    }

    await _channel.invokeMethod('disable');
    _channel.setMethodCallHandler(null);
    _isEnabled = false;
    _onTabSelected = null;
    _onSearchChanged = null;
    _onSearchSubmitted = null;
    _onSearchCancelled = null;
    _onSearchActiveChanged = null;
  }

  /// Selects the tab at [index] in the native tab bar.
  ///
  /// No-op when the native tab bar is not enabled.
  static Future<void> setSelectedIndex(int index) async {
    if (!_isEnabled) return;
    await _channel.invokeMethod('setSelectedIndex', {'index': index});
  }

  /// Navigates to the search tab and focuses the search field.
  ///
  /// No-op when the native tab bar is not enabled.
  static Future<void> activateSearch() async {
    if (!_isEnabled) return;
    await _channel.invokeMethod('activateSearch');
  }

  /// Dismisses the search bar and returns to the previously selected tab.
  ///
  /// No-op when the native tab bar is not enabled.
  static Future<void> deactivateSearch() async {
    if (!_isEnabled) return;
    await _channel.invokeMethod('deactivateSearch');
  }

  /// Sets the search field text to [text] without triggering the keyboard.
  ///
  /// No-op when the native tab bar is not enabled.
  static Future<void> setSearchText(String text) async {
    if (!_isEnabled) return;
    await _channel.invokeMethod('setSearchText', {'text': text});
  }

  /// Updates badge counts for each tab.
  ///
  /// Provide `null` for a tab to clear its badge.
  /// The list length should match the number of tabs passed to [enable].
  /// No-op when the native tab bar is not enabled.
  static Future<void> setBadgeCounts(List<int?> badgeCounts) async {
    if (!_isEnabled) return;
    await _channel.invokeMethod('setBadgeCounts', {'badgeCounts': badgeCounts});
  }

  /// Updates the tint colors of the native tab bar.
  ///
  /// Pass `null` for either parameter to keep its current value.
  /// No-op when the native tab bar is not enabled.
  static Future<void> setStyle({
    Color? tintColor,
    Color? unselectedTintColor,
  }) async {
    if (!_isEnabled) return;
    await _channel.invokeMethod('setStyle', {
      if (tintColor != null) 'tint': tintColor.toARGB32(),
      if (unselectedTintColor != null)
        'unselectedTint': unselectedTintColor.toARGB32(),
    });
  }

  /// Notifies the native tab bar of a light/dark mode change.
  ///
  /// Call this when [MediaQuery.platformBrightness] changes if you have not
  /// enabled automatic brightness propagation.
  /// No-op when the native tab bar is not enabled.
  static Future<void> setBrightness({required bool isDark}) async {
    if (!_isEnabled) return;
    await _channel.invokeMethod('setBrightness', {'isDark': isDark});
  }

  /// Notifies the native tab bar of an app text-direction change.
  ///
  /// Call this when [Directionality.of(context)] changes (e.g. a locale
  /// switch between LTR and RTL) if it was not already current in [enable].
  /// No-op when the native tab bar is not enabled.
  static Future<void> setTextDirection(TextDirection textDirection) async {
    if (!_isEnabled) return;
    await _channel.invokeMethod('setTextDirection', {
      'isRTL': textDirection == TextDirection.rtl,
    });
  }

  /// Updates the iOS 26 native `UITabBarController.tabBarMinimizeBehavior`.
  ///
  /// Mirrors SwiftUI's `TabView.tabBarMinimizeBehavior(_:)`. No-op on iOS < 26.
  /// No-op when the native tab bar is not enabled.
  static Future<void> setMinimizeBehavior(
    CNTabBarMinimizeBehavior behavior,
  ) async {
    if (!_isEnabled) return;
    await _channel.invokeMethod('setMinimizeBehavior', {
      'minimizeBehavior': behavior.rawValue,
    });
  }

  static double _lastSentOffset = 0;
  static int _lastSentTimestampMs = 0;

  /// Reports the current scroll offset so the native tab bar can shrink/expand.
  ///
  /// Call this inside a [ScrollController] listener or a
  /// [NotificationListener<ScrollNotification>] when [shrinkWhileScroll] was
  /// set to `true` in [enable]. The tab bar hides while scrolling down and
  /// reappears when scrolling up or when the list is at the top.
  ///
  /// No-op when the native tab bar is not enabled.
  static Future<void> reportScrollOffset(double offset) async {
    if (!_isEnabled) return;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final deltaAbs = (offset - _lastSentOffset).abs();
    final elapsedMs = nowMs - _lastSentTimestampMs;
    if (deltaAbs < 4 && elapsedMs < 33) return;
    _lastSentOffset = offset;
    _lastSentTimestampMs = nowMs;
    await _channel.invokeMethod('updateScrollOffset', {'offset': offset});
  }

  /// Returns `true` if the native tab bar is currently active on the platform side.
  static Future<bool> checkIsEnabled() async {
    try {
      final result = await _channel.invokeMethod<bool>('isEnabled');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Whether the native tab bar is currently enabled.
  ///
  /// Returns `true` after [enable] completes and before [disable] is called.
  static bool get isEnabled => _isEnabled;

  static Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onTabSelected':
        final index = call.arguments['index'] as int;
        _onTabSelected?.call(index);
        break;
      case 'onSearchChanged':
        final query = call.arguments['query'] as String;
        _onSearchChanged?.call(query);
        break;
      case 'onSearchSubmitted':
        final query = call.arguments['query'] as String;
        _onSearchSubmitted?.call(query);
        break;
      case 'onSearchCancelled':
        _onSearchCancelled?.call();
        break;
      case 'onSearchActiveChanged':
        final isActive = call.arguments['isActive'] as bool;
        _onSearchActiveChanged?.call(isActive);
        break;
      case 'onTabAppeared':
        // Tab appeared - could be used for analytics
        break;
    }
  }
}

/// Configuration for a native tab in [CNTabBarNative].
///
/// Each tab can have a title, an icon, and optionally be marked as a search tab.
///
/// Example:
/// ```dart
/// CNTab(
///   title: 'Home',
///   sfSymbol: CNSymbol('house.fill'),
/// )
///
/// // Custom artwork instead of an SF Symbol:
/// CNTab(
///   title: 'Home',
///   icon: CNIcon.asset('assets/icons/home.svg'),
/// )
/// ```
class CNTab extends Equatable {
  /// Title shown below the tab icon.
  final String title;

  /// SF Symbol for the unselected state.
  ///
  /// Ignored when [icon] is provided.
  final CNSymbol? sfSymbol;

  /// SF Symbol for the selected state.
  ///
  /// Falls back to [sfSymbol] when not provided. Ignored when [activeIcon]
  /// (or [icon], as its fallback) is provided.
  final CNSymbol? activeSfSymbol;

  /// Custom icon for the unselected state — takes precedence over [sfSymbol].
  ///
  /// Accepts any [CNIcon] source: [CNIcon.asset] (Flutter asset path, format
  /// auto-detected), [CNIcon.svg]/[CNIcon.png]/[CNIcon.jpg] (raw bytes), or
  /// [CNIcon.xcasset] (app bundle asset catalog).
  final CNIcon? icon;

  /// Custom icon for the selected state — takes precedence over
  /// [activeSfSymbol]. Falls back to [icon] when not provided.
  final CNIcon? activeIcon;

  /// Whether this tab triggers the iOS 26 native search bar.
  ///
  /// Only one tab should be marked as a search tab. When selected, the native
  /// search bar appears with the Liquid Glass morphing effect.
  final bool isSearchTab;

  /// Badge count shown on the tab. Pass `null` for no badge.
  final int? badgeCount;

  /// Creates a tab configuration for [CNTabBarNative].
  const CNTab({
    required this.title,
    this.sfSymbol,
    this.activeSfSymbol,
    this.icon,
    this.activeIcon,
    this.isSearchTab = false,
    this.badgeCount,
  });

  @override
  List<Object?> get props => [
    title,
    sfSymbol,
    activeSfSymbol,
    icon,
    activeIcon,
    isSearchTab,
    badgeCount,
  ];
}

/// Mirrors `UITabBarController.MinimizeBehavior` on iOS 26+.
///
/// Equivalent to the SwiftUI `TabBarMinimizeBehavior` values used by
/// `TabView.tabBarMinimizeBehavior(_:)`.
enum CNTabBarMinimizeBehavior {
  /// Never minimize the tab bar.
  never('never'),

  /// Minimize the tab bar when the user scrolls down.
  onScrollDown('onScrollDown'),

  /// Minimize the tab bar when the user scrolls up.
  onScrollUp('onScrollUp'),

  /// System-chosen default minimization behavior.
  automatic('automatic');

  const CNTabBarMinimizeBehavior(this.rawValue);

  /// Wire-format string sent to the iOS side.
  final String rawValue;
}
