import FlutterMacOS
import Cocoa

class CupertinoSegmentedControlNSView: NSView {
  private let channel: FlutterMethodChannel
  private let control: NSSegmentedControl
  private var labels: [String] = []
  private var symbols: [String] = []
  private var perSymbolSizes: [CGFloat?] = []
  private var defaultIconSize: CGFloat? = nil
  private var perSymbolModes: [String?] = []
  private var perSymbolGradientEnabled: [NSNumber?] = []
  private var defaultIconRenderingMode: String? = nil
  private var defaultIconGradientEnabled: Bool = false
  private var pendingLabelStyle: [String: Any]? = nil
  private var pendingActiveLabelStyle: [String: Any]? = nil

  // MARK: - Text style helpers

  private func parseTextStyle(_ dict: [String: Any]) -> NSFont? {
    let fontSize = (dict["fontSize"] as? NSNumber).map { CGFloat(truncating: $0) }
    let fontWeight = dict["fontWeight"] as? Int
    let fontFamily = dict["fontFamily"] as? String
    var font: NSFont? = nil
    if let fontSize = fontSize {
      if let fontFamily = fontFamily, let customFont = NSFont(name: fontFamily, size: fontSize) {
        font = customFont
      } else {
        let weight: NSFont.Weight
        switch fontWeight ?? 400 {
        case 100: weight = .ultraLight
        case 200: weight = .thin
        case 300: weight = .light
        case 400: weight = .regular
        case 500: weight = .medium
        case 600: weight = .semibold
        case 700: weight = .bold
        case 800: weight = .heavy
        case 900: weight = .black
        default:  weight = .regular
        }
        font = NSFont.systemFont(ofSize: fontSize, weight: weight)
      }
    }
    if (dict["italic"] as? Bool) == true, let f = font {
      let descriptor = f.fontDescriptor.withSymbolicTraits(.italic)
      font = NSFont(descriptor: descriptor, size: f.pointSize) ?? font
    }
    return font
  }

  /// Applies font from a text style dict to all segment labels.
  /// Note: NSSegmentedControl does not support per-state label styling.
  /// Both labelStyle and activeLabelStyle share the same font; color
  /// differentiation for active state is handled by the tint mechanism.
  private func applyLabelStyleToAllSegments(_ dict: [String: Any]?) {
    let font: NSFont? = dict.flatMap { parseTextStyle($0) }
    for i in 0..<control.segmentCount {
      let label = control.label(forSegment: i) ?? ""
      var attrs: [NSAttributedString.Key: Any] = [:]
      if let font = font { attrs[.font] = font }
      if attrs.isEmpty {
        control.setLabel(label, forSegment: i)
      } else {
        let attrStr = NSAttributedString(string: label, attributes: attrs)
        // NSSegmentedControl does not have setAttributedLabel; re-set via label
        // and apply font/color via NSCell attributed string workaround.
        if let cell = control.cell as? NSSegmentedCell {
          cell.setLabel(attrStr.string, forSegment: i)
        }
      }
    }
  }

  init(viewId: Int64, args: Any?, messenger: FlutterBinaryMessenger) {
    self.channel = FlutterMethodChannel(name: "\(ChannelConstants.viewIdCupertinoNativeSegmentedControl)_\(viewId)", binaryMessenger: messenger)
    self.control = NSSegmentedControl(labels: [], trackingMode: .selectOne, target: nil, action: nil)

    var labels: [String] = []
    var sfSymbols: [String] = []
    var selectedIndex: Int = -1
    var enabled: Bool = true
    var isDark: Bool = false

    if let dict = args as? [String: Any] {
      if let arr = dict["labels"] as? [String] { labels = arr }
      if let arr = dict["sfSymbols"] as? [String] { sfSymbols = arr }
      if let sizes = dict["sfSymbolSizes"] as? [NSNumber] { self.perSymbolSizes = sizes.map { CGFloat(truncating: $0) } }
      if let modes = dict["sfSymbolRenderingModes"] as? [String?] { self.perSymbolModes = modes }
      if let gradients = dict["sfSymbolGradientEnabled"] as? [NSNumber?] { self.perSymbolGradientEnabled = gradients }
      if let v = dict["selectedIndex"] as? NSNumber { selectedIndex = v.intValue }
      if let v = dict["enabled"] as? NSNumber { enabled = v.boolValue }
      if let v = dict["isDark"] as? NSNumber { isDark = v.boolValue }
      if let labelStyleDict = dict["labelStyle"] as? [String: Any] {
        self.pendingLabelStyle = labelStyleDict
      }
      if let activeLabelStyleDict = dict["activeLabelStyle"] as? [String: Any] {
        self.pendingActiveLabelStyle = activeLabelStyleDict
      }
      if let style = dict["style"] as? [String: Any] {
        if let s = style["iconSize"] as? NSNumber { self.defaultIconSize = CGFloat(truncating: s) }
        if let mode = style["iconRenderingMode"] as? String { self.defaultIconRenderingMode = mode }
        if let g = style["iconGradientEnabled"] as? NSNumber { self.defaultIconGradientEnabled = g.boolValue }
      }
    }

    super.init(frame: .zero)

    wantsLayer = true
    layer?.backgroundColor = NSColor.clear.cgColor
    appearance = NSAppearance(named: isDark ? .darkAqua : .aqua)

    self.labels = labels
    self.symbols = sfSymbols
    configureSegments()
    if selectedIndex >= 0 { control.selectedSegment = selectedIndex }
    control.isEnabled = enabled

    control.target = self
    control.action = #selector(onChanged(_:))

    // Apply label style from creation params (macOS: single-state only)
    if let style = pendingLabelStyle { applyLabelStyleToAllSegments(style) }

    addSubview(control)
    control.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      control.leadingAnchor.constraint(equalTo: leadingAnchor),
      control.trailingAnchor.constraint(equalTo: trailingAnchor),
      control.topAnchor.constraint(equalTo: topAnchor),
      control.bottomAnchor.constraint(equalTo: bottomAnchor)
    ])

    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { result(nil); return }
      switch call.method {
      case "getIntrinsicSize":
        let size = self.control.intrinsicContentSize
        result(["width": Double(size.width), "height": Double(size.height)])
      case "setSelectedIndex":
        if let args = call.arguments as? [String: Any], let idx = (args["index"] as? NSNumber)?.intValue {
          self.control.selectedSegment = idx
          result(nil)
        } else { result(FlutterError(code: "bad_args", message: "Missing index", details: nil)) }
      case "setEnabled":
        if let args = call.arguments as? [String: Any], let e = (args["enabled"] as? NSNumber)?.boolValue {
          self.control.isEnabled = e
          result(nil)
        } else { result(FlutterError(code: "bad_args", message: "Missing enabled", details: nil)) }
      case "setStyle":
        if let args = call.arguments as? [String: Any] {
          if let s = args["iconSize"] as? NSNumber { self.defaultIconSize = CGFloat(truncating: s) }
          self.configureSegments()
          result(nil)
        } else { result(FlutterError(code: "bad_args", message: "Missing style", details: nil)) }
      case "setBrightness":
        if let args = call.arguments as? [String: Any], let isDark = (args["isDark"] as? NSNumber)?.boolValue {
          self.appearance = NSAppearance(named: isDark ? .darkAqua : .aqua)
          result(nil)
        } else { result(FlutterError(code: "bad_args", message: "Missing isDark", details: nil)) }
      case "setLabelStyle":
        // macOS: no per-state label styling; applies font to all segments
        self.applyLabelStyleToAllSegments(call.arguments as? [String: Any])
        result(nil)
      case "setActiveLabelStyle":
        // macOS: NSSegmentedControl has no selected-state label API; no-op
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  required init?(coder: NSCoder) { return nil }

  private func configureSegments() {
    let count = max(labels.count, symbols.count)
    control.segmentCount = count
    for i in 0..<count {
      if i < symbols.count, #available(macOS 11.0, *), var image = NSImage(systemSymbolName: symbols[i], accessibilityDescription: nil) {
        if let size = (i < perSymbolSizes.count ? perSymbolSizes[i] : nil) ?? defaultIconSize {
          if #available(macOS 12.0, *) {
            let cfg = NSImage.SymbolConfiguration(pointSize: size, weight: .regular)
            image = image.withSymbolConfiguration(cfg) ?? image
          }
        }
        // Rendering mode selection (best-effort)
        let mode = (i < perSymbolModes.count ? perSymbolModes[i] : nil) ?? defaultIconRenderingMode
        if let mode = mode {
          switch mode {
          case "hierarchical":
            // Best-effort: requires a color; use no-op if none provided globally
            if #available(macOS 12.0, *) {
              // No per-icon color; rely on defaults
              // If needed, this can consult a global default icon color in future
            }
          case "palette":
            // macOS lacks easy per-icon palette with NSImage API; rely on contentTintColor
            break
          case "multicolor":
            if #available(macOS 12.0, *) {
              let cfg = NSImage.SymbolConfiguration.preferringMulticolor()
              image = image.withSymbolConfiguration(cfg) ?? image
            }
          default:
            break
          }
        }
        control.setImage(image, forSegment: i)
      } else if i < labels.count {
        control.setLabel(labels[i], forSegment: i)
      } else {
        control.setLabel("", forSegment: i)
      }
    }
  }

  @objc private func onChanged(_ sender: NSSegmentedControl) {
    channel.invokeMethod("valueChanged", arguments: ["index": sender.selectedSegment])
  }

}
