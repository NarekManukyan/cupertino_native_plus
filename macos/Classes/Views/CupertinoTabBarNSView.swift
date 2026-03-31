import FlutterMacOS
import Cocoa

class CupertinoTabBarNSView: NSView {
  private let channel: FlutterMethodChannel
  private let control: NSSegmentedControl
  private var currentLabels: [String] = []
  private var currentSymbols: [String] = []
  private var currentBadges: [String] = []
  private var currentCustomIconBytes: [Data?] = []
  private var currentActiveCustomIconBytes: [Data?] = []
  private var currentImageAssetPaths: [String] = []
  private var currentActiveImageAssetPaths: [String] = []
  private var currentImageAssetData: [Data?] = []
  private var currentActiveImageAssetData: [Data?] = []
  private var currentImageAssetFormats: [String] = []
  private var currentActiveImageAssetFormats: [String] = []
  private var iconScale: CGFloat = NSScreen.main?.backingScaleFactor ?? 2.0
  private var currentSizes: [NSNumber] = []
  private var currentTint: NSColor? = nil
  private var currentBackground: NSColor? = nil
  private var labelStyleDict: [String: Any]? = nil
  private var activeLabelStyleDict: [String: Any]? = nil

  // MARK: - Text style helpers

  private func parseTextStyle(_ dict: [String: Any]) -> NSFont? {
    let fontSize = (dict["fontSize"] as? NSNumber).map { CGFloat(truncating: $0) }
    let fontWeight = dict["fontWeight"] as? Int
    let fontFamily = dict["fontFamily"] as? String
    var font: NSFont? = nil
    if let size = fontSize {
      if let family = fontFamily, let customFont = NSFont(name: family, size: size) {
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
        font = NSFont.systemFont(ofSize: size, weight: weight)
      }
    }
    if (dict["italic"] as? Bool) == true, let f = font {
      let descriptor = f.fontDescriptor.withSymbolicTraits(.italic)
      font = NSFont(descriptor: descriptor, size: f.pointSize) ?? font
    }
    return font
  }

  /// Applies font from labelStyleDict to all segment labels.
  ///
  /// **macOS limitation:** NSSegmentedControl has no per-state label API.
  /// Uses `control.font` for uniform font; activeLabelStyle color is a no-op.
  private func applyLabelStyles() {
    let dict = labelStyleDict ?? activeLabelStyleDict
    guard let dict = dict else {
      control.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
      control.needsLayout = true
      control.needsDisplay = true
      return
    }
    let font = parseTextStyle(dict)
    if let font = font {
      control.font = font
      control.needsLayout = true
      control.needsDisplay = true
    }
  }

  init(viewId: Int64, args: Any?, messenger: FlutterBinaryMessenger) {
    self.channel = FlutterMethodChannel(name: "\(ChannelConstants.viewIdCupertinoNativeTabBar)_\(viewId)", binaryMessenger: messenger)
    self.control = NSSegmentedControl(labels: [], trackingMode: .selectOne, target: nil, action: nil)

    var labels: [String] = []
    var symbols: [String] = []
    var badges: [String] = []
    var customIconBytes: [Data?] = []
    var activeCustomIconBytes: [Data?] = []
    var imageAssetPaths: [String] = []
    var activeImageAssetPaths: [String] = []
    var imageAssetData: [Data?] = []
    var activeImageAssetData: [Data?] = []
    var imageAssetFormats: [String] = []
    var activeImageAssetFormats: [String] = []
    var iconScale: CGFloat = NSScreen.main?.backingScaleFactor ?? 2.0
    var sizes: [NSNumber] = []
    var selectedIndex: Int = 0
    var isDark: Bool = false
    var tint: NSColor? = nil
    var bg: NSColor? = nil

    if let dict = args as? [String: Any] {
      labels = (dict["labels"] as? [String]) ?? []
      symbols = (dict["sfSymbols"] as? [String]) ?? []
      badges = (dict["badges"] as? [String]) ?? []
      if let bytesArray = dict["customIconBytes"] as? [FlutterStandardTypedData?] {
        customIconBytes = bytesArray.map { $0?.data }
      }
      if let bytesArray = dict["activeCustomIconBytes"] as? [FlutterStandardTypedData?] {
        activeCustomIconBytes = bytesArray.map { $0?.data }
      }
      imageAssetPaths = (dict["imageAssetPaths"] as? [String]) ?? []
      activeImageAssetPaths = (dict["activeImageAssetPaths"] as? [String]) ?? []
      if let bytesArray = dict["imageAssetData"] as? [FlutterStandardTypedData?] {
        imageAssetData = bytesArray.map { $0?.data }
      }
      if let bytesArray = dict["activeImageAssetData"] as? [FlutterStandardTypedData?] {
        activeImageAssetData = bytesArray.map { $0?.data }
      }
      imageAssetFormats = (dict["imageAssetFormats"] as? [String]) ?? []
      activeImageAssetFormats = (dict["activeImageAssetFormats"] as? [String]) ?? []
      if let scale = dict["iconScale"] as? NSNumber {
        iconScale = CGFloat(truncating: scale)
      }
      sizes = (dict["sfSymbolSizes"] as? [NSNumber]) ?? []
      if let v = dict["selectedIndex"] as? NSNumber { selectedIndex = v.intValue }
      if let v = dict["isDark"] as? NSNumber { isDark = v.boolValue }
      if let style = dict["style"] as? [String: Any] {
        if let n = style["tint"] as? NSNumber { tint = ImageUtils.colorFromARGB(n.intValue) }
        if let n = style["backgroundColor"] as? NSNumber { bg = ImageUtils.colorFromARGB(n.intValue) }
      }
      if let ls = dict["labelStyle"] as? [String: Any] { self.labelStyleDict = ls }
      if let als = dict["activeLabelStyle"] as? [String: Any] { self.activeLabelStyleDict = als }
    }

    super.init(frame: .zero)

    wantsLayer = true
    layer?.backgroundColor = NSColor.clear.cgColor
    appearance = NSAppearance(named: isDark ? .darkAqua : .aqua)

    configureSegments(
      labels: labels,
      symbols: symbols,
      customIconBytes: customIconBytes,
      imageAssetPaths: imageAssetPaths,
      imageAssetData: imageAssetData,
      imageAssetFormats: imageAssetFormats,
      iconScale: iconScale,
      sizes: sizes
    )
    if selectedIndex >= 0 { control.selectedSegment = selectedIndex }
    self.currentLabels = labels
    self.currentSymbols = symbols
    self.currentBadges = badges
    self.currentCustomIconBytes = customIconBytes
    self.currentActiveCustomIconBytes = activeCustomIconBytes
    self.currentImageAssetPaths = imageAssetPaths
    self.currentActiveImageAssetPaths = activeImageAssetPaths
    self.currentImageAssetData = imageAssetData
    self.currentActiveImageAssetData = activeImageAssetData
    self.currentImageAssetFormats = imageAssetFormats
    self.currentActiveImageAssetFormats = activeImageAssetFormats
    self.iconScale = iconScale
    self.currentSizes = sizes
    self.currentTint = tint
    self.currentBackground = bg
    if let b = bg { wantsLayer = true; layer?.backgroundColor = b.cgColor }
    applySegmentTint()
    applyLabelStyles()

    control.target = self
    control.action = #selector(onChanged(_:))

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
          self.applySegmentTint()
          result(nil)
        } else { result(FlutterError(code: "bad_args", message: "Missing index", details: nil)) }
      case "setStyle":
        if let args = call.arguments as? [String: Any] {
          if let n = args["tint"] as? NSNumber { self.currentTint = ImageUtils.colorFromARGB(n.intValue) }
          if let n = args["backgroundColor"] as? NSNumber {
            let c = ImageUtils.colorFromARGB(n.intValue)
            self.currentBackground = c
            self.wantsLayer = true
            self.layer?.backgroundColor = c.cgColor
          }
          self.applySegmentTint()
          result(nil)
        } else { result(FlutterError(code: "bad_args", message: "Missing style", details: nil)) }
      case "setBrightness":
        if let args = call.arguments as? [String: Any], let isDark = (args["isDark"] as? NSNumber)?.boolValue {
          self.appearance = NSAppearance(named: isDark ? .darkAqua : .aqua)
          result(nil)
        } else { result(FlutterError(code: "bad_args", message: "Missing isDark", details: nil)) }
      case "setItems":
        if let args = call.arguments as? [String: Any] {
          let labels = (args["labels"] as? [String]) ?? []
          let symbols = (args["sfSymbols"] as? [String]) ?? []
          var customIconBytes: [Data?] = []
          var imageAssetPaths: [String] = []
          var imageAssetData: [Data?] = []
          var imageAssetFormats: [String] = []
          if let bytesArray = args["customIconBytes"] as? [FlutterStandardTypedData?] {
            customIconBytes = bytesArray.map { $0?.data }
          }
          imageAssetPaths = (args["imageAssetPaths"] as? [String]) ?? []
          if let bytesArray = args["imageAssetData"] as? [FlutterStandardTypedData?] {
            imageAssetData = bytesArray.map { $0?.data }
          }
          imageAssetFormats = (args["imageAssetFormats"] as? [String]) ?? []
          if let scale = args["iconScale"] as? NSNumber {
            self.iconScale = CGFloat(truncating: scale)
          }
          let sizes = (args["sfSymbolSizes"] as? [NSNumber]) ?? []
          self.currentLabels = labels
          self.currentSymbols = symbols
          self.currentCustomIconBytes = customIconBytes
          self.currentImageAssetPaths = imageAssetPaths
          self.currentImageAssetData = imageAssetData
          self.currentImageAssetFormats = imageAssetFormats
          self.currentSizes = sizes
          self.configureSegments(
            labels: labels,
            symbols: symbols,
            customIconBytes: customIconBytes,
            imageAssetPaths: imageAssetPaths,
            imageAssetData: imageAssetData,
            imageAssetFormats: imageAssetFormats,
            iconScale: self.iconScale,
            sizes: sizes
          )
          self.applySegmentTint()
          result(nil)
        } else { result(FlutterError(code: "bad_args", message: "Missing items", details: nil)) }
      case "setLabelStyle":
        self.labelStyleDict = call.arguments as? [String: Any]
        self.applyLabelStyles()
        result(nil)
      case "setActiveLabelStyle":
        self.activeLabelStyleDict = call.arguments as? [String: Any]
        self.applyLabelStyles()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  required init?(coder: NSCoder) { return nil }

  private func configureSegments(
    labels: [String],
    symbols: [String],
    customIconBytes: [Data?],
    imageAssetPaths: [String],
    imageAssetData: [Data?],
    imageAssetFormats: [String],
    iconScale: CGFloat,
    sizes: [NSNumber]
  ) {
    let count = max(labels.count, max(symbols.count, max(customIconBytes.count, max(imageAssetPaths.count, imageAssetData.count))))
    control.segmentCount = count
    let size25 = CGSize(width: 25, height: 25)
    for i in 0..<count {
      var image: NSImage?
      if i < imageAssetData.count, let data = imageAssetData[i] {
        let format = (i < imageAssetFormats.count && !imageAssetFormats[i].isEmpty) ? imageAssetFormats[i] : nil
        image = ImageUtils.createImageFromData(data, format: format, size: size25, scale: iconScale)
      } else if i < imageAssetPaths.count && !imageAssetPaths[i].isEmpty {
        image = ImageUtils.loadFlutterAsset(imageAssetPaths[i], size: size25, scale: iconScale)
      } else if i < customIconBytes.count, let data = customIconBytes[i] {
        image = NSImage(data: data)
      }
      if let img = image {
        if let rep = img.representations.first {
          rep.pixelsWide = Int(25.0 * iconScale)
          rep.pixelsHigh = Int(25.0 * iconScale)
        }
        img.size = NSSize(width: 25.0, height: 25.0)
        img.isTemplate = true
        control.setImage(img, forSegment: i)
      } else if i < symbols.count && !symbols[i].isEmpty,
                #available(macOS 11.0, *),
                var symImage = NSImage(systemSymbolName: symbols[i], accessibilityDescription: nil) {
        if i < sizes.count, #available(macOS 12.0, *) {
          let size = CGFloat(truncating: sizes[i])
          let cfg = NSImage.SymbolConfiguration(pointSize: size, weight: .regular)
          symImage = symImage.withSymbolConfiguration(cfg) ?? symImage
        }
        control.setImage(symImage, forSegment: i)
      } else if i < labels.count {
        control.setLabel(labels[i], forSegment: i)
      } else {
        control.setLabel("", forSegment: i)
      }
    }
  }

  private func applySegmentTint() {
    let count = control.segmentCount
    guard count > 0 else { return }
    let sel = control.selectedSegment
    for i in 0..<count {
      let hasImageAsset = (i < currentImageAssetData.count && currentImageAssetData[i] != nil)
        || (i < currentImageAssetPaths.count && !currentImageAssetPaths[i].isEmpty)
      let hasCustomIconBytes = i < currentCustomIconBytes.count && currentCustomIconBytes[i] != nil
      let hasCustomIcon = hasImageAsset || hasCustomIconBytes
      if !hasCustomIcon,
         let name = (i < currentSymbols.count ? currentSymbols[i] : nil), !name.isEmpty,
         var image = NSImage(systemSymbolName: name, accessibilityDescription: nil) {
        if i < currentSizes.count, #available(macOS 12.0, *) {
          let size = CGFloat(truncating: currentSizes[i])
          let cfg = NSImage.SymbolConfiguration(pointSize: size, weight: .regular)
          image = image.withSymbolConfiguration(cfg) ?? image
        }
        if i == sel, let tint = currentTint {
          if #available(macOS 12.0, *) {
            let cfg = NSImage.SymbolConfiguration(hierarchicalColor: tint)
            image = image.withSymbolConfiguration(cfg) ?? image
          } else {
            image = image.tinted(with: tint)
          }
        }
        control.setImage(image, forSegment: i)
      }
    }
  }

  @objc private func onChanged(_ sender: NSSegmentedControl) {
    channel.invokeMethod("valueChanged", arguments: ["index": sender.selectedSegment])
  }
}
