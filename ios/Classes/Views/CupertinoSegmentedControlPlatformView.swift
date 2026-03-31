import Flutter
import UIKit

class CupertinoSegmentedControlPlatformView: NSObject, FlutterPlatformView {
  private let channel: FlutterMethodChannel
  private let container: UIView
  private let control: UISegmentedControl
  private var labels: [String] = []
  private var symbols: [String] = []
  private var perSymbolSizes: [CGFloat?] = []
  private var perSymbolColors: [UIColor?] = []
  private var perSymbolPalettes: [[UIColor]] = []
  private var perSymbolModes: [String?] = []
  private var perSymbolGradientEnabled: [NSNumber?] = []
  private var defaultIconSize: CGFloat? = nil
  private var defaultIconColor: UIColor? = nil
  private var defaultIconPalette: [UIColor] = []
  private var defaultIconRenderingMode: String? = nil
  private var defaultIconGradientEnabled: Bool = false
  private var pendingLabelStyle: [String: Any]? = nil
  private var pendingActiveLabelStyle: [String: Any]? = nil

  // MARK: - Text style helpers

  private func parseTextStyle(_ dict: [String: Any]) -> UIFont? {
    let fontSize = (dict["fontSize"] as? NSNumber).map { CGFloat(truncating: $0) }
    let fontWeight = dict["fontWeight"] as? Int
    let fontFamily = dict["fontFamily"] as? String
    var font: UIFont? = nil
    if let fontSize = fontSize {
      if let fontFamily = fontFamily, let customFont = UIFont(name: fontFamily, size: fontSize) {
        font = customFont
      } else {
        let weight: UIFont.Weight
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
        font = UIFont.systemFont(ofSize: fontSize, weight: weight)
      }
    }
    if (dict["italic"] as? Bool) == true, let f = font {
      if let descriptor = f.fontDescriptor.withSymbolicTraits(.traitItalic) {
        font = UIFont(descriptor: descriptor, size: f.pointSize)
      }
    }
    return font
  }

  private func applyLabelStyle(_ dict: [String: Any]?, forState state: UIControl.State) {
    guard let dict = dict else {
      control.setTitleTextAttributes(nil, for: state)
      return
    }
    let font = parseTextStyle(dict)
    var attrs: [NSAttributedString.Key: Any] = [:]
    if let font = font { attrs[.font] = font }
    control.setTitleTextAttributes(attrs, for: state)
  }

  init(frame: CGRect, viewId: Int64, args: Any?, messenger: FlutterBinaryMessenger) {
    self.channel = FlutterMethodChannel(name: "\(ChannelConstants.viewIdCupertinoNativeSegmentedControl)_\(viewId)", binaryMessenger: messenger)
    self.container = UIView(frame: frame)
    self.control = UISegmentedControl(items: [])

    var labels: [String] = []
    var sfSymbols: [String] = []
    var selectedIndex: Int = UISegmentedControl.noSegment
    var enabled: Bool = true
    var isDark: Bool = false
    var tint: UIColor? = nil

    if let dict = args as? [String: Any] {
      if let arr = dict["labels"] as? [String] { labels = arr }
      if let arr = dict["sfSymbols"] as? [String] { sfSymbols = arr }
      if let sizes = dict["sfSymbolSizes"] as? [NSNumber] {
        self.perSymbolSizes = sizes.map { CGFloat(truncating: $0) }
      }
      if let colors = dict["sfSymbolColors"] as? [NSNumber] {
        self.perSymbolColors = colors.map { ImageUtils.colorFromARGB($0.intValue) }
      }
      if let palettes = dict["sfSymbolPaletteColors"] as? [[NSNumber]] {
        self.perSymbolPalettes = palettes.map { $0.map { ImageUtils.colorFromARGB($0.intValue) } }
      }
      if let modes = dict["sfSymbolRenderingModes"] as? [String?] {
        self.perSymbolModes = modes
      }
      if let gradients = dict["sfSymbolGradientEnabled"] as? [NSNumber?] {
        self.perSymbolGradientEnabled = gradients
      }
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
        if let n = style["tint"] as? NSNumber { tint = ImageUtils.colorFromARGB(n.intValue) }
        if let n = style["iconColor"] as? NSNumber { self.defaultIconColor = ImageUtils.colorFromARGB(n.intValue) }
        if let s = style["iconSize"] as? NSNumber { self.defaultIconSize = CGFloat(truncating: s) }
        if let arr = style["iconPaletteColors"] as? [NSNumber] { self.defaultIconPalette = arr.map { ImageUtils.colorFromARGB($0.intValue) } }
        if let mode = style["iconRenderingMode"] as? String { self.defaultIconRenderingMode = mode }
        if let g = style["iconGradientEnabled"] as? NSNumber { self.defaultIconGradientEnabled = g.boolValue }
      }
    }

    super.init()

    container.backgroundColor = .clear
    if #available(iOS 13.0, *) {
      container.overrideUserInterfaceStyle = isDark ? .dark : .light
    }

    self.labels = labels
    self.symbols = sfSymbols
    rebuildSegments()
    control.selectedSegmentIndex = selectedIndex
    control.isEnabled = enabled
    if #available(iOS 13.0, *), let c = tint { control.selectedSegmentTintColor = c }

    control.translatesAutoresizingMaskIntoConstraints = false
    container.addSubview(control)
    NSLayoutConstraint.activate([
      control.leadingAnchor.constraint(equalTo: container.leadingAnchor),
      control.trailingAnchor.constraint(equalTo: container.trailingAnchor),
      control.topAnchor.constraint(equalTo: container.topAnchor),
      control.bottomAnchor.constraint(equalTo: container.bottomAnchor)
    ])

    control.addTarget(self, action: #selector(onChanged(_:)), for: .valueChanged)

    // Apply label styles from creation params
    if let labelStyle = pendingLabelStyle { applyLabelStyle(labelStyle, forState: .normal) }
    if let activeLabelStyle = pendingActiveLabelStyle { applyLabelStyle(activeLabelStyle, forState: .selected) }

    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { result(nil); return }
      switch call.method {
      case "getIntrinsicSize":
        // Defer result until after layout so Flutter gets size only when native has finished layout.
        DispatchQueue.main.async { [weak self] in
          guard let self = self else { return }
          self.view().layoutIfNeeded()
          let size = self.control.intrinsicContentSize
          result(["width": Double(size.width), "height": Double(size.height)])
        }
      case "setSelectedIndex":
        if let args = call.arguments as? [String: Any], let idx = (args["index"] as? NSNumber)?.intValue {
          UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut) {
            self.control.selectedSegmentIndex = idx
          }
          result(nil)
        } else { result(FlutterError(code: "bad_args", message: "Missing index", details: nil)) }
      case "setEnabled":
        if let args = call.arguments as? [String: Any], let e = (args["enabled"] as? NSNumber)?.boolValue {
          UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut) {
            self.control.isEnabled = e
            self.control.alpha = e ? 1.0 : 0.5
          }
          result(nil)
        } else { result(FlutterError(code: "bad_args", message: "Missing enabled", details: nil)) }
      case "setStyle":
        if let args = call.arguments as? [String: Any] {
          UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut) {
            if #available(iOS 13.0, *), let n = args["tint"] as? NSNumber {
              self.control.selectedSegmentTintColor = ImageUtils.colorFromARGB(n.intValue)
            }
          }
          if let n = args["iconColor"] as? NSNumber { self.defaultIconColor = ImageUtils.colorFromARGB(n.intValue) }
          if let s = args["iconSize"] as? NSNumber { self.defaultIconSize = CGFloat(truncating: s) }
          self.rebuildSegments()
          result(nil)
        } else { result(FlutterError(code: "bad_args", message: "Missing style", details: nil)) }
      case "setBrightness":
        if let args = call.arguments as? [String: Any], let isDark = (args["isDark"] as? NSNumber)?.boolValue {
          if #available(iOS 13.0, *) {
            self.container.overrideUserInterfaceStyle = isDark ? .dark : .light
          }
          result(nil)
        } else { result(FlutterError(code: "bad_args", message: "Missing isDark", details: nil)) }
      case "setLabelStyle":
        self.applyLabelStyle(call.arguments as? [String: Any], forState: .normal)
        result(nil)
      case "setActiveLabelStyle":
        self.applyLabelStyle(call.arguments as? [String: Any], forState: .selected)
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  func view() -> UIView { container }

  @objc private func onChanged(_ sender: UISegmentedControl) {
    channel.invokeMethod("valueChanged", arguments: ["index": sender.selectedSegmentIndex])
  }

  // Use shared utility functions

  private func rebuildSegments() {
    control.removeAllSegments()
    let count = max(labels.count, symbols.count)
    for idx in 0..<count {
      if idx < symbols.count, var image = UIImage(systemName: symbols[idx]) {
        if let size = (idx < perSymbolSizes.count ? perSymbolSizes[idx] : nil) ?? defaultIconSize {
          let cfg = UIImage.SymbolConfiguration(pointSize: size)
          if let newImg = image.applyingSymbolConfiguration(cfg) { image = newImg }
        }
        // Rendering mode selection
        let mode = (idx < perSymbolModes.count ? perSymbolModes[idx] : nil) ?? defaultIconRenderingMode
        if let mode = mode {
          switch mode {
          case "hierarchical":
            if #available(iOS 15.0, *), let color = (idx < perSymbolColors.count ? perSymbolColors[idx] : nil) ?? defaultIconColor {
              let cfg = UIImage.SymbolConfiguration(hierarchicalColor: color)
              if let newImg = image.applyingSymbolConfiguration(cfg) { image = newImg }
            }
          case "palette":
            if #available(iOS 15.0, *), !((idx < perSymbolPalettes.count) ? perSymbolPalettes[idx].isEmpty : defaultIconPalette.isEmpty) {
              let colors = (idx < perSymbolPalettes.count && !perSymbolPalettes[idx].isEmpty) ? perSymbolPalettes[idx] : defaultIconPalette
              let cfg = UIImage.SymbolConfiguration(paletteColors: colors)
              if let newImg = image.applyingSymbolConfiguration(cfg) { image = newImg }
            }
          case "multicolor":
            if #available(iOS 15.0, *) {
              let cfg = UIImage.SymbolConfiguration.preferringMulticolor()
              if let newImg = image.applyingSymbolConfiguration(cfg) { image = newImg }
            }
          default:
            break
          }
        } else if let color = (idx < perSymbolColors.count ? perSymbolColors[idx] : nil) ?? defaultIconColor {
          if #available(iOS 13.0, *) {
            image = image.withTintColor(color, renderingMode: .alwaysOriginal)
          }
        }
        // Gradient toggle (built-in in SF Symbols 7). If available, prefer gradient.
        let gradientEnabled = (idx < perSymbolGradientEnabled.count ? perSymbolGradientEnabled[idx]?.boolValue : nil) ?? defaultIconGradientEnabled
        if gradientEnabled {
          // Note: Using future API for built-in gradients when available. Currently no-op on older SDKs.
          // if #available(iOS 18.0, *), let cfg = UIImage.SymbolConfiguration.preferringGradient() { image = image.applyingSymbolConfiguration(cfg) ?? image }
        }
        control.insertSegment(with: image, at: idx, animated: false)
      } else if idx < labels.count {
        control.insertSegment(withTitle: labels[idx], at: idx, animated: false)
      } else {
        control.insertSegment(withTitle: "", at: idx, animated: false)
      }
    }
  }
}
