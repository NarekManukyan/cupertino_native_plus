import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../channel/view_types.dart';
import '../style/sf_symbol.dart';
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
  }) async {
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

    // Enable native tab bar
    await _channel.invokeMethod('enable', {
      'tabs': tabs
          .map(
            (tab) => {
              'title': tab.title,
              'sfSymbol': tab.sfSymbol?.name,
              'activeSfSymbol': tab.activeSfSymbol?.name,
              'isSearch': tab.isSearchTab,
              'badgeCount': tab.badgeCount,
            },
          )
          .toList(),
      'selectedIndex': selectedIndex,
      'isDark': isDark ?? false,
      if (tintColor != null) 'tint': tintColor.toARGB32(),
      if (unselectedTintColor != null)
        'unselectedTint': unselectedTintColor.toARGB32(),
    });

    _isEnabled = true;
  }

  /// Disables the native tab bar and restores Flutter-only mode.
  ///
  /// Call this in [State.dispose] of the widget that called [enable].
  /// No-op when the native tab bar is not already enabled.
  static Future<void> disable() async {
    if (!_isEnabled) {
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
/// Each tab can have a title, SF Symbol icon, and optionally be marked as a search tab.
///
/// Example:
/// ```dart
/// CNTab(
///   title: 'Home',
///   sfSymbol: CNSymbol('house.fill'),
/// )
/// ```
class CNTab extends Equatable {
  /// Title shown below the tab icon.
  final String title;

  /// SF Symbol for the unselected state.
  final CNSymbol? sfSymbol;

  /// SF Symbol for the selected state.
  ///
  /// Falls back to [sfSymbol] when not provided.
  final CNSymbol? activeSfSymbol;

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
    this.isSearchTab = false,
    this.badgeCount,
  });

  @override
  List<Object?> get props => [
    title,
    sfSymbol,
    activeSfSymbol,
    isSearchTab,
    badgeCount,
  ];
}
