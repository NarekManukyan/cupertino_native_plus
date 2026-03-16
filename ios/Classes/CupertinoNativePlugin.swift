import Flutter
import UIKit

public class CupertinoNativePlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: ChannelConstants.methodChannelName, binaryMessenger: registrar.messenger())
    let instance = CupertinoNativePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)

    // Setup native tab bar manager (runtime check inside)
    CNNativeTabBarManager.shared.setup(messenger: registrar.messenger())

    // Register platform view factories
    let sliderFactory = CupertinoSliderViewFactory(messenger: registrar.messenger())
    registrar.register(sliderFactory, withId: ChannelConstants.viewIdCupertinoNativeSlider)

    let switchFactory = CupertinoSwitchViewFactory(messenger: registrar.messenger())
    registrar.register(switchFactory, withId: ChannelConstants.viewIdCupertinoNativeSwitch)

    let segmentedFactory = CupertinoSegmentedControlViewFactory(messenger: registrar.messenger())
    registrar.register(segmentedFactory, withId: ChannelConstants.viewIdCupertinoNativeSegmentedControl)

    let iconFactory = CupertinoIconViewFactory(messenger: registrar.messenger())
    registrar.register(iconFactory, withId: ChannelConstants.viewIdCupertinoNativeIcon)

    let tabBarFactory = CupertinoTabBarViewFactory(messenger: registrar.messenger())
    registrar.register(tabBarFactory, withId: ChannelConstants.viewIdCupertinoNativeTabBar)

    let popupMenuFactory = CupertinoPopupMenuButtonViewFactory(messenger: registrar.messenger())
    registrar.register(popupMenuFactory, withId: ChannelConstants.viewIdCupertinoNativePopupMenuButton)

    let buttonFactory = CupertinoButtonViewFactory(messenger: registrar.messenger())
    registrar.register(buttonFactory, withId: ChannelConstants.viewIdCupertinoNativeButton)

    let glassButtonGroupFactory = CupertinoGlassButtonGroupFactory(messenger: registrar.messenger())
    registrar.register(glassButtonGroupFactory, withId: ChannelConstants.viewIdCupertinoNativeGlassButtonGroup)

    let liquidGlassContainerFactory = LiquidGlassContainerFactory(messenger: registrar.messenger())
    registrar.register(liquidGlassContainerFactory, withId: ChannelConstants.viewIdCupertinoNativeLiquidGlassContainer)

    let searchBarFactory = CupertinoSearchBarFactory(messenger: registrar.messenger())
    registrar.register(searchBarFactory, withId: ChannelConstants.viewIdCNSearchBar)

    let floatingIslandFactory = FloatingIslandFactory(messenger: registrar.messenger())
    registrar.register(floatingIslandFactory, withId: ChannelConstants.viewIdCNFloatingIsland)

    let searchScaffoldFactory = CNSearchScaffoldViewFactory(messenger: registrar.messenger())
    registrar.register(searchScaffoldFactory, withId: ChannelConstants.viewIdCNSearchScaffold)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case ChannelConstants.methodGetPlatformVersion:
      result("iOS " + UIDevice.current.systemVersion)
    case ChannelConstants.methodGetMajorOSVersion:
      let version = ProcessInfo.processInfo.operatingSystemVersion
      result(Int(version.majorVersion))
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
 
