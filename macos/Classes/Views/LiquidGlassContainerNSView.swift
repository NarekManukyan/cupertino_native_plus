import FlutterMacOS
import AppKit
import SwiftUI

@available(macOS 26.0, *)
class LiquidGlassContainerNSView: NSObject, FlutterPlatformView {
  private let container: NSView
  private var hostingController: NSHostingController<LiquidGlassContainerSwiftUI>
  private let channel: FlutterMethodChannel
  
  init(frame: CGRect, viewId: Int64, args: Any?, messenger: FlutterBinaryMessenger) {
    self.channel = FlutterMethodChannel(name: "\(ChannelConstants.viewIdCupertinoNativeLiquidGlassContainer)_\(viewId)", binaryMessenger: messenger)
    self.container = NSView(frame: frame)
    self.container.wantsLayer = true
    self.container.layer?.backgroundColor = NSColor.clear.cgColor
    self.container.layer?.masksToBounds = false

    let config = LiquidGlassContainerConfig.parse(from: args)
    let tint = config.tintARGB.map { ImageUtils.colorFromARGB($0) }

    let glassView = LiquidGlassContainerSwiftUI(
      effect: config.effect,
      shape: config.shape,
      cornerRadius: config.cornerRadius,
      tint: tint,
      interactive: config.interactive
    )
    
    self.hostingController = NSHostingController(rootView: glassView)
    self.hostingController.view.wantsLayer = true
    self.hostingController.view.layer?.backgroundColor = NSColor.clear.cgColor
    self.hostingController.view.appearance = NSAppearance(named: config.isDark ? .darkAqua : .aqua)

    super.init()
    
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
    hostingController.view.appearance = NSAppearance(named: config.isDark ? .darkAqua : .aqua)
  }
  
  func view() -> NSView {
    return container
  }
}

@available(macOS 26.0, *)
struct LiquidGlassContainerSwiftUI: View {
  let effect: String
  let shape: String
  let cornerRadius: CGFloat?
  let tint: NSColor?
  let interactive: Bool
  
  var body: some View {
    GeometryReader { geometry in
      shapeForConfig()
        .fill(Color.clear)
        .contentShape(shapeForConfig())
        .allowsHitTesting(false)
        .glassEffect(glassEffectForConfig(), in: shapeForConfig())
        .frame(width: geometry.size.width, height: geometry.size.height)
    }
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

// Fallback for macOS < 26
class FallbackLiquidGlassContainerNSView: NSObject, FlutterPlatformView {
  private let container: NSView
  
  init(frame: CGRect, viewId: Int64, args: Any?, messenger: FlutterBinaryMessenger) {
    self.container = NSView(frame: frame)
    self.container.wantsLayer = true
    self.container.layer?.backgroundColor = NSColor.clear.cgColor
    super.init()
  }
  
  func view() -> NSView {
    return container
  }
}

