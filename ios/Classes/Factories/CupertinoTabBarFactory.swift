import Flutter
import UIKit

class CupertinoTabBarViewFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    super.init()
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    return FlutterStandardMessageCodec.sharedInstance()
  }

  func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
    // Check if search is enabled and we're on iOS 26+
    var hasSearch = false
    if let dict = args as? [String: Any] {
      hasSearch = (dict["hasSearch"] as? NSNumber)?.boolValue ?? false
    }

    // Use SwiftUI-based implementation for iOS 26+ with search enabled
    if #available(iOS 26.0, *), hasSearch {
      return CupertinoTabBarSearchPlatformView(frame: frame, viewId: viewId, args: args, messenger: messenger)
    }

    // Default to UIKit-based implementation
    return CupertinoTabBarPlatformView(frame: frame, viewId: viewId, args: args, messenger: messenger)
  }
}
