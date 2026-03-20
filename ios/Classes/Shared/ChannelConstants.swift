import Foundation

/// Centralized channel names and view-type IDs. Keep in sync with Dart [ViewTypes].
enum ChannelConstants {
  /// Method channel name for the plugin.
  static let methodChannelName = "cupertino_native"

  /// Native tab bar method channel (single channel, not per-view).
  static let cnNativeTabBarChannel = "cn_native_tab_bar"

  // MARK: - View type IDs (must match lib/channel/view_types.dart)

  static let viewIdCupertinoNativeButton = "CupertinoNativeButton"
  static let viewIdCupertinoNativeGlassButtonGroup = "CupertinoNativeGlassButtonGroup"
  static let viewIdCupertinoNativeIcon = "CupertinoNativeIcon"
  static let viewIdCupertinoNativeLiquidGlassContainer = "CupertinoNativeLiquidGlassContainer"
  static let viewIdCupertinoNativePopupMenuButton = "CupertinoNativePopupMenuButton"
  static let viewIdCupertinoNativeSegmentedControl = "CupertinoNativeSegmentedControl"
  static let viewIdCupertinoNativeSlider = "CupertinoNativeSlider"
  static let viewIdCupertinoNativeSwitch = "CupertinoNativeSwitch"
  static let viewIdCupertinoNativeTabBar = "CupertinoNativeTabBar"
  static let viewIdCNFloatingIsland = "CNFloatingIsland"
  static let viewIdCNGlassCardWithSpotlight = "CNGlassCardWithSpotlight"
  static let viewIdCNGlassCard = "CNGlassCard"
  static let viewIdCNSearchBar = "CNSearchBar"
  static let viewIdCNSearchScaffold = "CNSearchScaffold"
  static let viewIdCNLiquidText = "CNLiquidText"

  // MARK: - Method names

  static let methodGetPlatformVersion = "getPlatformVersion"
  static let methodGetMajorOSVersion = "getMajorOSVersion"
  static let methodUpdateConfig = "updateConfig"
  static let methodSetBrightness = "setBrightness"
  static let methodPressed = "pressed"
  static let methodValueChanged = "valueChanged"
  static let methodItemSelected = "itemSelected"
  static let methodExpanded = "expanded"
  static let methodCollapsed = "collapsed"
  static let methodTapped = "tapped"
}
