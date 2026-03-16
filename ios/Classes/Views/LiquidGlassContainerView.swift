import Flutter
import UIKit
import SwiftUI

@available(iOS 26.0, *)
class LiquidGlassContainerPlatformView: NSObject, FlutterPlatformView {
  private let container: UIView
  private var hostingController: UIHostingController<LiquidGlassContainerSwiftUI>
  private let channel: FlutterMethodChannel
  
  init(frame: CGRect, viewId: Int64, args: Any?, messenger: FlutterBinaryMessenger) {
    self.channel = FlutterMethodChannel(name: "\(ChannelConstants.viewIdCupertinoNativeLiquidGlassContainer)_\(viewId)", binaryMessenger: messenger)
    self.container = UIView(frame: frame)
    self.container.backgroundColor = .clear
    self.container.clipsToBounds = false

    let config = LiquidGlassContainerConfig.parse(from: args)
    let tint = config.tintARGB.map { ImageUtils.colorFromARGB($0) }

    let glassView = LiquidGlassContainerSwiftUI(
      effect: config.effect,
      shape: config.shape,
      cornerRadius: config.cornerRadius,
      tint: tint,
      interactive: config.interactive
    )
    
    self.hostingController = UIHostingController(rootView: glassView)
    self.hostingController.view.backgroundColor = .clear
    self.hostingController.overrideUserInterfaceStyle = config.isDark ? .dark : .light
    
    super.init()
    
    // Sync Flutter's brightness mode with Swift at initialization
    if #available(iOS 13.0, *) {
      self.hostingController.overrideUserInterfaceStyle = config.isDark ? .dark : .light
    }
    
    // Add hosting controller as child
    container.addSubview(hostingController.view)
    hostingController.view.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      hostingController.view.topAnchor.constraint(equalTo: container.topAnchor),
      hostingController.view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
      hostingController.view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
      hostingController.view.bottomAnchor.constraint(equalTo: container.bottomAnchor),
    ])
    
    // Set up method channel handler
    channel.setMethodCallHandler { [weak self] (call, result) in
      if call.method == ChannelConstants.methodUpdateConfig {
        self?.updateConfig(args: call.arguments)
        result(nil)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }
  
  private func updateConfig(args: Any?) {
    let config = LiquidGlassContainerConfig.parse(from: args)
    let tint = config.tintARGB.map { ImageUtils.colorFromARGB($0) }
    let newGlassView = LiquidGlassContainerSwiftUI(
      effect: config.effect,
      shape: config.shape,
      cornerRadius: config.cornerRadius,
      tint: tint,
      interactive: config.interactive
    )
    hostingController.rootView = newGlassView
    hostingController.overrideUserInterfaceStyle = config.isDark ? .dark : .light
  }
  
  func view() -> UIView {
    return container
  }
}

@available(iOS 26.0, *)
struct LiquidGlassContainerSwiftUI: View {
  let effect: String
  let shape: String
  let cornerRadius: CGFloat?
  let tint: UIColor?
  let interactive: Bool
  
  var body: some View {
    GeometryReader { geometry in
      shapeForConfig()
        .fill(Color.clear)
        .contentShape(shapeForConfig())
        .allowsHitTesting(false)  // Always false - let Flutter handle gestures
        .glassEffect(glassEffectForConfig(), in: shapeForConfig())
        .frame(width: geometry.size.width, height: geometry.size.height)
        .animation(.easeInOut(duration: 0.25), value: configIdentity)
    }
  }

  /// Single Equatable value for animation to avoid multiple animation pipelines (reduces jank).
  private var configIdentity: String {
    "\(effect)|\(shape)|\(cornerRadius ?? -1)|\(interactive)"
  }
  
  private func glassEffectForConfig() -> Glass {
    // Always use .regular for now - prominent glass API may be available in future
    var glass = Glass.regular
    
    if let tintColor = tint {
      glass = glass.tint(Color(tintColor))
    }
    
    if interactive {
      glass = glass.interactive()
    }
    
    return glass
  }
  
  private func shapeForConfig() -> some Shape {
    switch shape {
    case "rect":
      if let radius = cornerRadius {
        return AnyShape(RoundedRectangle(cornerRadius: radius))
      }
      return AnyShape(RoundedRectangle(cornerRadius: 0))
    case "circle":
      return AnyShape(Circle())
    default: // capsule
      return AnyShape(Capsule())
    }
  }
}

// Fallback for iOS < 26
class FallbackLiquidGlassContainerView: NSObject, FlutterPlatformView {
  private let container: UIView
  
  init(frame: CGRect, viewId: Int64, args: Any?, messenger: FlutterBinaryMessenger) {
    self.container = UIView(frame: frame)
    self.container.backgroundColor = .clear
    super.init()
  }
  
  func view() -> UIView {
    return container
  }
}

