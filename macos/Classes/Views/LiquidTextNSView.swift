import FlutterMacOS
import AppKit
import SwiftUI

// MARK: - Config

@available(macOS 26.0, *)
struct LiquidTextMacConfig {
  let text: String
  let fontSize: CGFloat
  let fontWeight: Font.Weight
  let textColor: Color?
  let shape: String          // "capsule" | "rect" | "circle"
  let cornerRadius: CGFloat?
  let tint: Color?
  let interactive: Bool
  let padding: EdgeInsets
  let isDark: Bool

  static func parse(from args: Any?) -> LiquidTextMacConfig {
    guard let dict = args as? [String: Any] else { return .default }

    let text = dict["text"] as? String ?? ""
    let fontSize = (dict["fontSize"] as? NSNumber).map { CGFloat(truncating: $0) } ?? 16.0
    let fontWeight = parseFontWeight(dict["fontWeight"] as? String)

    let textColorARGB = (dict["textColor"] as? NSNumber)?.intValue
    let textColor = textColorARGB.map { Color(ImageUtils.colorFromARGB($0)) }

    let shape = dict["shape"] as? String ?? "capsule"
    let cornerRadius = (dict["cornerRadius"] as? NSNumber).map { CGFloat(truncating: $0) }

    let tintARGB = (dict["tint"] as? NSNumber)?.intValue
    let tint = tintARGB.map { Color(ImageUtils.colorFromARGB($0)) }

    let interactive = (dict["interactive"] as? NSNumber)?.boolValue ?? false
    let isDark = dict["isDark"] as? Bool ?? false

    let all: CGFloat? = (dict["padding"] as? NSNumber).map { CGFloat(truncating: $0) }
    let padding = EdgeInsets(
      top:      (dict["paddingTop"]    as? NSNumber).map { CGFloat(truncating: $0) } ?? all ?? 8.0,
      leading:  (dict["paddingLeft"]   as? NSNumber).map { CGFloat(truncating: $0) } ?? all ?? 12.0,
      bottom:   (dict["paddingBottom"] as? NSNumber).map { CGFloat(truncating: $0) } ?? all ?? 8.0,
      trailing: (dict["paddingRight"]  as? NSNumber).map { CGFloat(truncating: $0) } ?? all ?? 12.0
    )

    return LiquidTextMacConfig(
      text: text, fontSize: fontSize, fontWeight: fontWeight, textColor: textColor,
      shape: shape, cornerRadius: cornerRadius, tint: tint, interactive: interactive,
      padding: padding, isDark: isDark
    )
  }

  static var `default`: LiquidTextMacConfig {
    LiquidTextMacConfig(
      text: "", fontSize: 16, fontWeight: .regular, textColor: nil,
      shape: "capsule", cornerRadius: nil, tint: nil, interactive: false,
      padding: EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12), isDark: false
    )
  }

  private static func parseFontWeight(_ str: String?) -> Font.Weight {
    switch str {
    case "bold":       return .bold
    case "semibold":   return .semibold
    case "medium":     return .medium
    case "light":      return .light
    case "thin":       return .thin
    case "ultraLight": return .ultraLight
    case "heavy":      return .heavy
    case "black":      return .black
    default:           return .regular
    }
  }
}

// MARK: - SwiftUI View

@available(macOS 26.0, *)
struct LiquidTextSwiftUIMac: View {
  let config: LiquidTextMacConfig

  var body: some View {
    let s = glassShape
    styledText
      .padding(config.padding)
      .glassEffect(glassEffect, in: s)
      .animation(.easeInOut(duration: 0.25), value: animState)
  }

  @ViewBuilder
  private var styledText: some View {
    if let color = config.textColor {
      Text(config.text)
        .font(.system(size: config.fontSize, weight: config.fontWeight))
        .foregroundStyle(color)
    } else {
      Text(config.text)
        .font(.system(size: config.fontSize, weight: config.fontWeight))
    }
  }

  private var glassEffect: Glass {
    var glass = Glass.regular
    if let tint = config.tint { glass = glass.tint(tint) }
    if config.interactive { glass = glass.interactive() }
    return glass
  }

  private var glassShape: AnyShape {
    switch config.shape {
    case "rect":   return AnyShape(RoundedRectangle(cornerRadius: config.cornerRadius ?? 0))
    case "circle": return AnyShape(Circle())
    default:       return AnyShape(Capsule())
    }
  }

  // MARK: - Animation state

  private struct AnimState: Equatable {
    let text: String
    let fontSize: CGFloat
    let textColor: Color?
    let tint: Color?
    let interactive: Bool
    let shape: String
    let cornerRadius: CGFloat?
  }

  private var animState: AnimState {
    AnimState(
      text: config.text,
      fontSize: config.fontSize,
      textColor: config.textColor,
      tint: config.tint,
      interactive: config.interactive,
      shape: config.shape,
      cornerRadius: config.cornerRadius
    )
  }
}

// MARK: - Platform View (macOS 26+)

@available(macOS 26.0, *)
class LiquidTextNSView: NSObject, FlutterPlatformView {
  private let container: NSView
  private var hostingController: NSHostingController<LiquidTextSwiftUIMac>
  private let channel: FlutterMethodChannel

  init(frame: CGRect, viewId: Int64, args: Any?, messenger: FlutterBinaryMessenger) {
    self.channel = FlutterMethodChannel(
      name: "\(ChannelConstants.viewIdCNLiquidText)_\(viewId)",
      binaryMessenger: messenger
    )
    self.container = NSView(frame: frame)
    self.container.wantsLayer = true
    self.container.layer?.backgroundColor = NSColor.clear.cgColor

    let config = LiquidTextMacConfig.parse(from: args)
    self.hostingController = NSHostingController(rootView: LiquidTextSwiftUIMac(config: config))
    self.hostingController.view.wantsLayer = true
    self.hostingController.view.layer?.backgroundColor = NSColor.clear.cgColor
    self.hostingController.view.appearance = NSAppearance(named: config.isDark ? .darkAqua : .aqua)

    super.init()

    container.addSubview(hostingController.view)
    hostingController.view.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      hostingController.view.topAnchor.constraint(equalTo: container.topAnchor),
      hostingController.view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
      hostingController.view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
      hostingController.view.bottomAnchor.constraint(equalTo: container.bottomAnchor),
    ])

    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else { result(nil); return }
      switch call.method {
      case ChannelConstants.methodUpdateConfig:
        let cfg = LiquidTextMacConfig.parse(from: call.arguments)
        self.hostingController.rootView = LiquidTextSwiftUIMac(config: cfg)
        self.hostingController.view.appearance = NSAppearance(named: cfg.isDark ? .darkAqua : .aqua)
        result(nil)
      case ChannelConstants.methodSetBrightness:
        if let dict = call.arguments as? [String: Any],
           let isDark = (dict["isDark"] as? NSNumber)?.boolValue {
          self.hostingController.view.appearance = NSAppearance(named: isDark ? .darkAqua : .aqua)
          result(nil)
        } else {
          result(FlutterError(code: "bad_args", message: "Missing isDark", details: nil))
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  func view() -> NSView { container }
}

// MARK: - Fallback (macOS < 26)

class FallbackLiquidTextNSView: NSObject, FlutterPlatformView {
  private let container: NSView

  init(frame: CGRect, viewId: Int64, args: Any?, messenger: FlutterBinaryMessenger) {
    self.container = NSView(frame: frame)
    self.container.wantsLayer = true
    self.container.layer?.backgroundColor = NSColor.clear.cgColor
    super.init()
  }

  func view() -> NSView { container }
}
