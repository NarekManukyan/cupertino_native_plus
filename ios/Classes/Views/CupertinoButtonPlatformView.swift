import Flutter
import SwiftUI
import UIKit

// MARK: - ViewModel

@available(iOS 26.0, *)
final class CupertinoButtonViewModel: ObservableObject {
  @Published var title: String?
  @Published var iconConfig: IconConfig?
  @Published var theme: CNButtonTheme
  @Published var style: String
  @Published var isEnabled: Bool
  @Published var glassEffectUnionId: String?
  @Published var glassEffectId: String?
  @Published var glassEffectInteractive: Bool
  @Published var config: GlassButtonConfig
  @Published var imagePlacement: String
  @Published var contentAlignment: String

  init(
    title: String?,
    iconConfig: IconConfig?,
    theme: CNButtonTheme,
    style: String,
    isEnabled: Bool,
    glassEffectUnionId: String?,
    glassEffectId: String?,
    glassEffectInteractive: Bool,
    config: GlassButtonConfig,
    imagePlacement: String,
    contentAlignment: String = "center"
  ) {
    self.title = title
    self.iconConfig = iconConfig
    self.theme = theme
    self.style = style
    self.isEnabled = isEnabled
    self.glassEffectUnionId = glassEffectUnionId
    self.glassEffectId = glassEffectId
    self.glassEffectInteractive = glassEffectInteractive
    self.config = config
    self.imagePlacement = imagePlacement
    self.contentAlignment = contentAlignment
  }
}

// MARK: - Platform View

class CupertinoButtonPlatformView: NSObject, FlutterPlatformView {
  private let channel: FlutterMethodChannel
  private let container: UIView
  private var button: UIButton?
  private var hostingController: UIHostingController<AnyView>?
  private var isEnabled: Bool = true
  private var currentButtonStyle: String = "automatic"
  private var usesSwiftUI: Bool = false
  private var makeRound: Bool = false
  private var currentTint: UIColor?

  // Holds CupertinoButtonViewModel when iOS 26+; typed as AnyObject to avoid @available restriction.
  private var _buttonViewModel: AnyObject?

  init(frame: CGRect, viewId: Int64, args: Any?, messenger: FlutterBinaryMessenger) {
    self.channel = FlutterMethodChannel(
      name: "\(ChannelConstants.viewIdCupertinoNativeButton)_\(viewId)", binaryMessenger: messenger)
    self.container = UIView(frame: frame)
    self.button = UIButton(type: .system)

    var title: String? = nil
    var iconName: String? = nil
    var customIconBytes: Data? = nil
    var assetPath: String? = nil
    var imageData: Data? = nil
    var imageFormat: String? = nil
    var xcassetName: String? = nil
    var iconSize: CGFloat? = nil
    var iconColor: UIColor? = nil
    var makeRound: Bool = false
    var isDark: Bool = false
    var tint: UIColor? = nil
    var buttonStyle: String = "automatic"
    var enabled: Bool = true
    var iconMode: String? = nil
    var iconPalette: [NSNumber] = []
    var iconScale: CGFloat = UIScreen.main.scale
    var imagePlacement: String = "leading"
    var contentAlignment: String = "center"
    var imagePadding: CGFloat? = nil
    var paddingTop: CGFloat? = nil
    var paddingBottom: CGFloat? = nil
    var paddingLeft: CGFloat? = nil
    var paddingRight: CGFloat? = nil
    var paddingHorizontal: CGFloat? = nil
    var paddingVertical: CGFloat? = nil
    var borderRadius: CGFloat? = nil
    var minHeight: CGFloat? = nil
    var glassEffectUnionId: String? = nil
    var glassEffectId: String? = nil
    var glassEffectInteractive: Bool = false
    var swiftUIWidth: CGFloat? = nil
    var swiftUIExpandWidth: Bool = false

    // Build icon/theme args dicts for SwiftUI path (iOS 26+).
    var iconArgs: [String: Any] = [:]
    var themeArgs: [String: Any] = [:]

    if let dict = args as? [String: Any] {
      if let t = dict["buttonTitle"] as? String { title = t }
      if let data = dict["buttonCustomIconBytes"] as? FlutterStandardTypedData {
        customIconBytes = data.data
      }
      if let name = dict["buttonXcassetName"] as? String { xcassetName = name }
      if let ap = dict["buttonAssetPath"] as? String { assetPath = ap }
      if let data = dict["buttonImageData"] as? FlutterStandardTypedData {
        imageData = data.data
      }
      if let f = dict["buttonImageFormat"] as? String { imageFormat = f }
      if let s = dict["buttonIconName"] as? String { iconName = s }
      if let s = dict["buttonIconSize"] as? NSNumber { iconSize = CGFloat(truncating: s) }
      if let c = dict["buttonIconColor"] as? NSNumber {
        iconColor = ImageUtils.colorFromARGB(c.intValue)
      }
      if let r = dict["round"] as? NSNumber {
        makeRound = r.boolValue
        self.makeRound = makeRound
      }
      if let v = dict["isDark"] as? NSNumber { isDark = v.boolValue }
      if let style = dict["style"] as? [String: Any], let n = style["tint"] as? NSNumber {
        tint = ImageUtils.colorFromARGB(n.intValue)
      }
      if let bs = dict["buttonStyle"] as? String { buttonStyle = bs }
      if let e = dict["enabled"] as? NSNumber { enabled = e.boolValue }
      if let m = dict["buttonIconRenderingMode"] as? String { iconMode = m }
      if let pal = dict["buttonIconPaletteColors"] as? [NSNumber] { iconPalette = pal }
      if let ip = dict["imagePlacement"] as? String { imagePlacement = ip }
      if let ca = dict["contentAlignment"] as? String { contentAlignment = ca }
      if let ip = dict["imagePadding"] as? NSNumber { imagePadding = CGFloat(truncating: ip) }
      if let pt = dict["paddingTop"] as? NSNumber { paddingTop = CGFloat(truncating: pt) }
      if let pb = dict["paddingBottom"] as? NSNumber { paddingBottom = CGFloat(truncating: pb) }
      if let pl = dict["paddingLeft"] as? NSNumber { paddingLeft = CGFloat(truncating: pl) }
      if let pr = dict["paddingRight"] as? NSNumber { paddingRight = CGFloat(truncating: pr) }
      if let ph = dict["paddingHorizontal"] as? NSNumber {
        paddingHorizontal = CGFloat(truncating: ph)
      }
      if let pv = dict["paddingVertical"] as? NSNumber { paddingVertical = CGFloat(truncating: pv) }
      if let br = dict["borderRadius"] as? NSNumber { borderRadius = CGFloat(truncating: br) }
      if let mh = dict["minHeight"] as? NSNumber { minHeight = CGFloat(truncating: mh) }
      if let bw = dict["buttonWidth"] as? NSNumber { swiftUIWidth = CGFloat(truncating: bw) }
      if let ew = dict["buttonExpandWidth"] as? NSNumber { swiftUIExpandWidth = ew.boolValue }
      if let gueId = dict["glassEffectUnionId"] as? String { glassEffectUnionId = gueId }
      if let geId = dict["glassEffectId"] as? String { glassEffectId = geId }
      if let geInteractive = dict["glassEffectInteractive"] as? NSNumber {
        glassEffectInteractive = geInteractive.boolValue
      }

      // Build icon args dict: pre-convert FlutterStandardTypedData → Data.
      iconArgs = dict
      for key in ["buttonImageData", "buttonCustomIconBytes"] {
        if let td = iconArgs[key] as? FlutterStandardTypedData { iconArgs[key] = td.data }
      }

      // Build flat theme dict from nested style + top-level glassMaterial + CNButtonTheme colors.
      if let style = dict["style"] as? [String: Any], let n = style["tint"] as? NSNumber {
        themeArgs["tint"] = n.intValue
      }
      if let gm = dict["glassMaterial"] as? String { themeArgs["glassMaterial"] = gm }
      for key in ["labelColor", "themeIconColor", "backgroundColor"] {
        if let n = dict[key] as? NSNumber { themeArgs[key] = n.intValue }
      }
      if let ls = dict["labelStyle"] as? [String: Any] { themeArgs["labelStyle"] = ls }
    }

    super.init()
    self.currentTint = tint

    container.backgroundColor = .clear
    container.clipsToBounds = false
    container.insetsLayoutMarginsFromSafeArea = false
    if #available(iOS 13.0, *) { container.overrideUserInterfaceStyle = isDark ? .dark : .light }

    // Observe frame/bounds so glassEffect re-computes its window position after
    // Flutter moves the container from {0,0} to the real layout position.
    container.addObserver(self, forKeyPath: "frame", options: [.new, .old], context: nil)
    container.addObserver(self, forKeyPath: "bounds", options: [.new, .old], context: nil)

    // Create final image first (needed for both SwiftUI and UIKit paths)
    var finalImage: UIImage? = nil
    // Priority: xcasset > imageAsset > customIconBytes > SF Symbol

    // Handle xcasset (highest priority). Always load from the app's main bundle.
    if let name = xcassetName, !name.isEmpty {
      finalImage = UIImage(named: name, in: Bundle.main, compatibleWith: nil)
    }

    // Handle imageAsset (next priority)
    if finalImage == nil, let path = assetPath, !path.isEmpty {
      let detectedFormat = ImageUtils.detectImageFormat(
        assetPath: path, providedFormat: imageFormat)
      let iconColorARGB: Int? = iconColor != nil ? ImageUtils.colorToARGB(iconColor!) : nil

      // Use utility function to load and optionally tint image
      if let argb = iconColorARGB, #available(iOS 13.0, *) {
        finalImage = ImageUtils.loadAndTintImage(
          from: path,
          iconSize: iconSize,
          iconColor: argb,
          providedFormat: imageFormat,
          scale: iconScale
        )
      } else {
        let size: CGSize? = iconSize != nil ? CGSize(width: iconSize!, height: iconSize!) : nil
        finalImage = ImageUtils.loadFlutterAsset(
          path, size: size, format: detectedFormat, scale: iconScale)
      }

      // If no color but size is specified, scale the image
      if finalImage != nil, iconColor == nil, let iconSize = iconSize {
        let targetSize = CGSize(width: iconSize, height: iconSize)
        if finalImage!.size != targetSize {
          finalImage = ImageUtils.scaleImage(finalImage!, to: targetSize, scale: iconScale)
        }
      }
    } else if finalImage == nil, let data = imageData {
      let format = imageFormat
      let iconColorARGB: Int? = iconColor != nil ? ImageUtils.colorToARGB(iconColor!) : nil

      // Use utility function to create and optionally tint image
      if let argb = iconColorARGB, #available(iOS 13.0, *) {
        finalImage = ImageUtils.createAndTintImage(
          from: data,
          iconSize: iconSize,
          iconColor: argb,
          providedFormat: format,
          scale: iconScale
        )
      } else {
        let size: CGSize? = iconSize != nil ? CGSize(width: iconSize!, height: iconSize!) : nil
        finalImage = ImageUtils.createImageFromData(
          data, format: format, size: size, scale: iconScale)
      }
    }

    // Handle custom icon bytes (medium priority)
    if finalImage == nil, let data = customIconBytes,
      var image = UIImage(data: data, scale: iconScale)
    {
      // Apply template rendering mode for tinting
      image = image.withRenderingMode(.alwaysTemplate)
      finalImage = image
    }

    // Handle SF Symbol (lowest priority)
    if finalImage == nil, let name = iconName, var image = UIImage(systemName: name) {
      if let sz = iconSize {
        image =
          image.applyingSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: sz)) ?? image
      }
      if let mode = iconMode {
        switch mode {
        case "hierarchical":
          if #available(iOS 15.0, *), let col = iconColor {
            let cfg = UIImage.SymbolConfiguration(hierarchicalColor: col)
            image = image.applyingSymbolConfiguration(cfg) ?? image
          }
        case "palette":
          if #available(iOS 15.0, *), !iconPalette.isEmpty {
            let cols = iconPalette.map { ImageUtils.colorFromARGB($0.intValue) }
            let cfg = UIImage.SymbolConfiguration(paletteColors: cols)
            image = image.applyingSymbolConfiguration(cfg) ?? image
          }
        case "multicolor":
          if #available(iOS 15.0, *) {
            let cfg = UIImage.SymbolConfiguration.preferringMulticolor()
            image = image.applyingSymbolConfiguration(cfg) ?? image
          }
        case "monochrome":
          if let col = iconColor, #available(iOS 13.0, *) {
            image = image.withTintColor(col, renderingMode: .alwaysOriginal)
          }
        default:
          break
        }
      } else if let col = iconColor, #available(iOS 13.0, *) {
        image = image.withTintColor(col, renderingMode: .alwaysOriginal)
      }
      finalImage = image
    }

    // Check if we should use SwiftUI for full glass effect support
    if #available(iOS 26.0, *) {
      usesSwiftUI = true
      setupSwiftUIButton(
        title: title,
        iconArgs: iconArgs,
        themeArgs: themeArgs,
        style: buttonStyle,
        enabled: enabled,
        glassEffectUnionId: glassEffectUnionId,
        glassEffectId: glassEffectId,
        glassEffectInteractive: glassEffectInteractive,
        borderRadius: borderRadius,
        paddingTop: paddingTop,
        paddingBottom: paddingBottom,
        paddingLeft: paddingLeft,
        paddingRight: paddingRight,
        paddingHorizontal: paddingHorizontal,
        paddingVertical: paddingVertical,
        minHeight: minHeight ?? 44.0,
        spacing: imagePadding ?? 8.0,
        imagePlacement: imagePlacement,
        contentAlignment: contentAlignment,
        width: swiftUIWidth,
        expandWidth: swiftUIExpandWidth
      )
    } else {
      // Use UIKit button for standard implementation
      let uiButton = UIButton(type: .system)
      self.button = uiButton

      uiButton.translatesAutoresizingMaskIntoConstraints = false
      if let t = tint {
        uiButton.tintColor = t
      } else if buttonStyle != "glass" {
        if #available(iOS 13.0, *) { uiButton.tintColor = .label }
      }

      container.addSubview(uiButton)
      NSLayoutConstraint.activate([
        uiButton.leadingAnchor.constraint(equalTo: container.leadingAnchor),
        uiButton.trailingAnchor.constraint(equalTo: container.trailingAnchor),
        uiButton.topAnchor.constraint(equalTo: container.topAnchor),
        uiButton.bottomAnchor.constraint(equalTo: container.bottomAnchor),
      ])

      applyButtonStyle(buttonStyle: buttonStyle, round: makeRound)
      currentButtonStyle = buttonStyle
      uiButton.isEnabled = enabled
      isEnabled = enabled

      // Calculate horizontal padding from individual padding values
      let calculatedHorizontalPadding: CGFloat? = {
        if let ph = paddingHorizontal {
          return ph
        } else if let pl = paddingLeft, let pr = paddingRight, pl == pr {
          return pl
        } else if let pl = paddingLeft {
          return pl
        } else if let pr = paddingRight {
          return pr
        }
        return nil
      }()

      setButtonContent(
        title: title,
        image: finalImage,
        iconOnly: (title == nil),
        imagePlacement: imagePlacement,
        imagePadding: imagePadding,
        horizontalPadding: calculatedHorizontalPadding
      )

      // Default system highlight/pressed behavior
      uiButton.addTarget(self, action: #selector(onPressed(_:)), for: .touchUpInside)
      uiButton.adjustsImageWhenHighlighted = true

      // Force layout update for proper first-time rendering
      DispatchQueue.main.async { [weak self, weak uiButton] in
        guard let self = self, let uiButton = uiButton else { return }
        self.container.setNeedsLayout()
        self.container.layoutIfNeeded()
        uiButton.setNeedsLayout()
        uiButton.layoutIfNeeded()
        // Force another update cycle for proper rendering
        DispatchQueue.main.async { [weak uiButton] in
          guard let uiButton = uiButton else { return }
          uiButton.setNeedsDisplay()
          uiButton.setNeedsLayout()
          uiButton.layoutIfNeeded()
        }
      }
    }

    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(nil)
        return
      }
      switch call.method {
      case "getIntrinsicSize":
        DispatchQueue.main.async { [weak self] in
          guard let self = self else { return }
          if usesSwiftUI {
            if #available(iOS 16.0, *), let hc = self.hostingController {
              // When expandWidth is true the SwiftUI button fills the entire
              // proposed width, causing sizeThatFits to return the proposed
              // width and the validity check below to fail (falling back to
              // 80 px).  Temporarily disable expand so we measure the button's
              // natural content size instead.  Both assignments happen on the
              // same run-loop turn so SwiftUI coalesces them into a no-op render.
              if #available(iOS 26.0, *), let vm = self.buttonViewModel, vm.config.expandWidth {
                let original = vm.config
                vm.config = GlassButtonConfig(
                  borderRadius: original.borderRadius,
                  padding: original.padding,
                  minHeight: original.minHeight,
                  spacing: original.spacing,
                  width: original.width,
                  expandWidth: false
                )
                hc.view.setNeedsLayout()
                hc.view.layoutIfNeeded()
                let proposed = CGSize(
                  width: UIScreen.main.bounds.width * 2, height: UIScreen.main.bounds.height)
                let sz = hc.sizeThatFits(in: proposed)
                vm.config = original
                let validWidth = sz.width > 0 && sz.width < proposed.width * 0.9
                let w = validWidth ? Double(ceil(sz.width)) : 80.0
                let h = sz.height > 0 ? Double(ceil(sz.height)) : 44.0
                result(["width": w, "height": h])
                return
              }
              hc.view.setNeedsLayout()
              hc.view.layoutIfNeeded()
              let proposed = CGSize(
                width: UIScreen.main.bounds.width * 2, height: UIScreen.main.bounds.height)
              let sz = hc.sizeThatFits(in: proposed)
              let validWidth = sz.width > 0 && sz.width < proposed.width * 0.9
              let w = validWidth ? Double(ceil(sz.width)) : 80.0
              let h = sz.height > 0 ? Double(ceil(sz.height)) : 44.0
              result(["width": w, "height": h])
            } else {
              result(["width": 80.0, "height": 44.0])
            }
          } else if let button = self.button {
            self.view().layoutIfNeeded()
            let size = button.intrinsicContentSize
            result(["width": Double(size.width), "height": Double(size.height)])
          } else {
            result(["width": 80.0, "height": 32.0])
          }
        }
      case "setStyle":
        if let args = call.arguments as? [String: Any] {
          if let n = args["tint"] as? NSNumber {
            self.currentTint = ImageUtils.colorFromARGB(n.intValue)
          }
          if usesSwiftUI {
            if #available(iOS 26.0, *), let vm = self.buttonViewModel {
              if let bs = args["buttonStyle"] as? String { vm.style = bs }
              // Merge incoming color overrides into the existing theme, preserving
              // fields (e.g. glassMaterial) that are not included in this call.
              let existing = vm.theme
              func argbToColor(_ n: NSNumber) -> Color {
                let v = n.intValue
                let a = Double((v >> 24) & 0xFF) / 255.0
                let r = Double((v >> 16) & 0xFF) / 255.0
                let g = Double((v >> 8)  & 0xFF) / 255.0
                let b = Double( v        & 0xFF) / 255.0
                return Color(.sRGB, red: r, green: g, blue: b, opacity: a)
              }
              vm.theme = CNButtonTheme(
                tint:            (args["tint"]            as? NSNumber).map(argbToColor) ?? existing.tint,
                labelColor:      (args["labelColor"]      as? NSNumber).map(argbToColor) ?? existing.labelColor,
                iconColor:       (args["themeIconColor"]  as? NSNumber).map(argbToColor) ?? existing.iconColor,
                backgroundColor: (args["backgroundColor"] as? NSNumber).map(argbToColor) ?? existing.backgroundColor,
                glassMaterial:   existing.glassMaterial,
                labelFont:       existing.labelFont
              )
            }
          } else if self.button != nil {
            if args["tint"] != nil {
              // Update button.tintColor so applyButtonStyle reads the new value
              if let t = self.currentTint { self.button?.tintColor = t }
              self.applyButtonStyle(buttonStyle: self.currentButtonStyle, round: self.makeRound)
            }
            if let bs = args["buttonStyle"] as? String {
              self.currentButtonStyle = bs
              self.applyButtonStyle(buttonStyle: bs, round: self.makeRound)
            }
          }
          result(nil)
        } else {
          result(FlutterError(code: "bad_args", message: "Missing style", details: nil))
        }
      case "setEnabled":
        if let args = call.arguments as? [String: Any], let e = args["enabled"] as? NSNumber {
          self.isEnabled = e.boolValue
          if usesSwiftUI {
            if #available(iOS 26.0, *) {
              self.buttonViewModel?.isEnabled = e.boolValue
            }
          } else if let button = self.button {
            button.isEnabled = self.isEnabled
          }
          result(nil)
        } else {
          result(FlutterError(code: "bad_args", message: "Missing enabled", details: nil))
        }
      case "setPressed":
        if let args = call.arguments as? [String: Any], let p = args["pressed"] as? NSNumber {
          if !usesSwiftUI, let button = self.button {
            button.isHighlighted = p.boolValue
          }
          // For SwiftUI buttons, pressed state is handled by the view itself
          result(nil)
        } else {
          result(FlutterError(code: "bad_args", message: "Missing pressed", details: nil))
        }
      case "setButtonTitle":
        if let args = call.arguments as? [String: Any], let t = args["title"] as? String {
          if usesSwiftUI {
            if #available(iOS 26.0, *) {
              self.buttonViewModel?.title = t
            }
          } else {
            self.setButtonContent(
              title: t, image: nil, iconOnly: false, imagePlacement: nil, imagePadding: nil,
              horizontalPadding: nil)
          }
          result(nil)
        } else {
          result(FlutterError(code: "bad_args", message: "Missing title", details: nil))
        }
      case "setButtonIcon":
        if let args = call.arguments as? [String: Any] {
          var image: UIImage? = nil
          let size = CGSize(
            width: args["buttonIconSize"] as? CGFloat ?? 20,
            height: args["buttonIconSize"] as? CGFloat ?? 20)

          // Priority: xcasset > imageAsset > customIconBytes > SF Symbol
          // Handle xcasset first
          if let xcassetName = args["buttonXcassetName"] as? String, !xcassetName.isEmpty {
            image = UIImage(named: xcassetName, in: Bundle.main, compatibleWith: nil)
          } else if let assetPath = args["buttonAssetPath"] as? String, !assetPath.isEmpty {
            let format = args["buttonImageFormat"] as? String
            let iconColorARGB = (args["buttonIconColor"] as? NSNumber)?.intValue

            // Use utility function to load and optionally tint image
            if let argb = iconColorARGB, #available(iOS 13.0, *) {
              image = ImageUtils.loadAndTintImage(
                from: assetPath,
                iconSize: size.width,
                iconColor: argb,
                providedFormat: format,
                scale: UIScreen.main.scale
              )
            } else {
              image = ImageUtils.loadFlutterAsset(
                assetPath, size: size, format: format, scale: UIScreen.main.scale)
            }

            // If no color but size is specified, scale the image
            if image != nil, iconColorARGB == nil, image!.size != size {
              image = ImageUtils.scaleImage(image!, to: size, scale: UIScreen.main.scale)
            }
          } else if let imageData = args["buttonImageData"] as? FlutterStandardTypedData {
            let format = args["buttonImageFormat"] as? String
            let iconColorARGB = (args["buttonIconColor"] as? NSNumber)?.intValue

            // Use utility function to create and optionally tint image
            if let argb = iconColorARGB, #available(iOS 13.0, *) {
              image = ImageUtils.createAndTintImage(
                from: imageData.data,
                iconSize: size.width,
                iconColor: argb,
                providedFormat: format,
                scale: UIScreen.main.scale
              )
            } else {
              image = ImageUtils.createImageFromData(
                imageData.data, format: format, size: size, scale: UIScreen.main.scale)
            }
          } else if let customIconBytes = args["buttonCustomIconBytes"] as? FlutterStandardTypedData
          {
            image = UIImage(data: customIconBytes.data, scale: UIScreen.main.scale)?
              .withRenderingMode(.alwaysTemplate)
          } else if let name = args["buttonIconName"] as? String {
            image = UIImage(systemName: name)
          }

          // Apply size and styling if image was found
          if let img = image {
            if let s = args["buttonIconSize"] as? NSNumber {
              image =
                img.applyingSymbolConfiguration(
                  UIImage.SymbolConfiguration(pointSize: CGFloat(truncating: s))) ?? img
            }
            if let mode = args["buttonIconRenderingMode"] as? String, let img0 = image {
              var img = img0
              switch mode {
              case "hierarchical":
                if #available(iOS 15.0, *), let c = args["buttonIconColor"] as? NSNumber {
                  let cfg = UIImage.SymbolConfiguration(
                    hierarchicalColor: ImageUtils.colorFromARGB(c.intValue))
                  image = img.applyingSymbolConfiguration(cfg) ?? img
                }
              case "palette":
                if #available(iOS 15.0, *), let pal = args["buttonIconPaletteColors"] as? [NSNumber]
                {
                  let cols = pal.map { ImageUtils.colorFromARGB($0.intValue) }
                  let cfg = UIImage.SymbolConfiguration(paletteColors: cols)
                  image = img.applyingSymbolConfiguration(cfg) ?? img
                }
              case "multicolor":
                if #available(iOS 15.0, *) {
                  let cfg = UIImage.SymbolConfiguration.preferringMulticolor()
                  image = img.applyingSymbolConfiguration(cfg) ?? img
                }
              case "monochrome":
                if let c = args["buttonIconColor"] as? NSNumber, #available(iOS 13.0, *) {
                  image = img.withTintColor(
                    ImageUtils.colorFromARGB(c.intValue), renderingMode: .alwaysOriginal)
                }
              default:
                break
              }
            } else if let c = args["buttonIconColor"] as? NSNumber, let img = image,
              #available(iOS 13.0, *)
            {
              image = img.withTintColor(
                ImageUtils.colorFromARGB(c.intValue), renderingMode: .alwaysOriginal)
            }
          }

          if usesSwiftUI {
            if #available(iOS 26.0, *), let vm = self.buttonViewModel {
              var iconArgs = args
              for key in ["buttonImageData", "buttonCustomIconBytes"] {
                if let td = iconArgs[key] as? FlutterStandardTypedData { iconArgs[key] = td.data }
              }
              let iconConfig = IconConfig.from(dict: iconArgs)
              vm.iconConfig = iconConfig.hasIcon ? iconConfig : nil
            }
          } else {
            self.setButtonContent(
              title: nil, image: image, iconOnly: true, imagePlacement: nil, imagePadding: nil,
              horizontalPadding: nil)
          }
          result(nil)
        } else {
          result(FlutterError(code: "bad_args", message: "Missing icon args", details: nil))
        }
      case "setBrightness":
        if let args = call.arguments as? [String: Any],
          let isDark = (args["isDark"] as? NSNumber)?.boolValue
        {
          if #available(iOS 13.0, *) {
            self.container.overrideUserInterfaceStyle = isDark ? .dark : .light
          }
          result(nil)
        } else {
          result(FlutterError(code: "bad_args", message: "Missing isDark", details: nil))
        }
      case "setImagePlacement":
        if let args = call.arguments as? [String: Any], let placement = args["placement"] as? String
        {
          if usesSwiftUI {
            if #available(iOS 26.0, *) {
              self.buttonViewModel?.imagePlacement = placement
            }
          } else if let button = self.button, #available(iOS 15.0, *) {
            var cfg = button.configuration ?? .plain()
            switch placement {
            case "leading": cfg.imagePlacement = .leading
            case "trailing": cfg.imagePlacement = .trailing
            case "top": cfg.imagePlacement = .top
            case "bottom": cfg.imagePlacement = .bottom
            default: cfg.imagePlacement = .leading
            }
            button.configuration = cfg
          }
          result(nil)
        } else {
          result(FlutterError(code: "bad_args", message: "Missing placement", details: nil))
        }
      case "setImagePadding":
        if let args = call.arguments as? [String: Any],
          let padding = (args["padding"] as? NSNumber).map({ CGFloat(truncating: $0) })
        {
          if usesSwiftUI {
            if #available(iOS 26.0, *), let vm = self.buttonViewModel {
              let old = vm.config
              vm.config = GlassButtonConfig(
                borderRadius: old.borderRadius,
                padding: old.padding,
                minHeight: old.minHeight,
                spacing: padding,
                width: old.width,
                expandWidth: old.expandWidth
              )
            }
          } else if let button = self.button, #available(iOS 15.0, *) {
            var cfg = button.configuration ?? .plain()
            cfg.imagePadding = padding
            button.configuration = cfg
          }
          result(nil)
        } else {
          // Clear padding if args is nil
          if usesSwiftUI {
            if #available(iOS 26.0, *), let vm = self.buttonViewModel {
              let old = vm.config
              vm.config = GlassButtonConfig(
                borderRadius: old.borderRadius,
                padding: old.padding,
                minHeight: old.minHeight,
                spacing: 8.0,
                width: old.width,
                expandWidth: old.expandWidth
              )
            }
          } else if let button = self.button, #available(iOS 15.0, *) {
            var cfg = button.configuration ?? .plain()
            cfg.imagePadding = 0
            button.configuration = cfg
          }
          result(nil)
        }
      case "setTextStyle":
        if usesSwiftUI {
          if #available(iOS 26.0, *), let vm = buttonViewModel {
            let labelFont: Font? = {
              guard let d = call.arguments as? [String: Any] else { return nil }
              let size = (d["fontSize"] as? NSNumber).map { CGFloat(truncating: $0) }
              let weightInt = d["fontWeight"] as? Int
              let family = d["fontFamily"] as? String
              let w: Font.Weight
              switch weightInt ?? 400 {
              case 100: w = .ultraLight; case 200: w = .thin; case 300: w = .light
              case 400: w = .regular; case 500: w = .medium; case 600: w = .semibold
              case 700: w = .bold; case 800: w = .heavy; case 900: w = .black
              default: w = .regular
              }
              let isItalic = (d["italic"] as? Bool) == true
              var f: Font?
              if let family, let sz = size { f = .custom(family, size: sz) }
              else if let sz = size { f = .system(size: sz, weight: w) }
              if isItalic, let existing = f { return existing.italic() }
              return f
            }()
            vm.theme = CNButtonTheme(
              tint: vm.theme.tint, labelColor: vm.theme.labelColor,
              iconColor: vm.theme.iconColor, backgroundColor: vm.theme.backgroundColor,
              glassMaterial: vm.theme.glassMaterial, labelFont: labelFont
            )
          }
          result(nil)
        } else if let args = call.arguments as? [String: Any] {
          let color = (args["color"] as? NSNumber).map { ImageUtils.colorFromARGB($0.intValue) }
          let fontSize = (args["fontSize"] as? NSNumber).map { CGFloat(truncating: $0) }
          let fontWeight = args["fontWeight"] as? Int
          let fontFamily = args["fontFamily"] as? String
          var font: UIFont? = nil
          if let fontSize = fontSize {
            if let fontFamily = fontFamily, let customFont = UIFont(name: fontFamily, size: fontSize) {
              font = customFont
            } else {
              let weight: UIFont.Weight
              switch fontWeight ?? 400 {
              case 100: weight = .ultraLight; case 200: weight = .thin; case 300: weight = .light
              case 400: weight = .regular; case 500: weight = .medium; case 600: weight = .semibold
              case 700: weight = .bold; case 800: weight = .heavy; case 900: weight = .black
              default: weight = .regular
              }
              font = UIFont.systemFont(ofSize: fontSize, weight: weight)
            }
          }
          if (args["italic"] as? Bool) == true, let f = font {
            if let descriptor = f.fontDescriptor.withSymbolicTraits(.traitItalic) {
              font = UIFont(descriptor: descriptor, size: f.pointSize)
            }
          }
          if let button = self.button {
            if #available(iOS 15.0, *) {
              var cfg = button.configuration ?? .plain()
              if let title = button.title(for: .normal), !title.isEmpty {
                var attrStr = AttributedString(title)
                if let font = font { attrStr.uiKit.font = font }
                if let color = color { attrStr.uiKit.foregroundColor = color }
                cfg.attributedTitle = attrStr
                button.configuration = cfg
              }
            } else {
              if let title = button.title(for: .normal), !title.isEmpty {
                let attrString = NSMutableAttributedString(string: title)
                if let font = font { attrString.addAttribute(.font, value: font, range: NSRange(location: 0, length: title.count)) }
                if let color = color { attrString.addAttribute(.foregroundColor, value: color, range: NSRange(location: 0, length: title.count)) }
                button.setAttributedTitle(attrString, for: .normal)
              }
            }
          }
          result(nil)
        } else {
          if let button = self.button {
            if #available(iOS 15.0, *) {
              var cfg = button.configuration ?? .plain()
              cfg.attributedTitle = nil
              button.configuration = cfg
            } else {
              button.setAttributedTitle(nil, for: .normal)
            }
          }
          result(nil)
        }
      case "setHorizontalPadding":
        if let args = call.arguments as? [String: Any],
          let padding = (args["padding"] as? NSNumber).map({ CGFloat(truncating: $0) })
        {
          if !usesSwiftUI, let button = self.button {
            if #available(iOS 15.0, *) {
              var cfg = button.configuration ?? .plain()
              var insets = cfg.contentInsets
              insets.leading = padding
              insets.trailing = padding
              cfg.contentInsets = insets
              button.configuration = cfg
            } else {
              button.contentEdgeInsets = UIEdgeInsets(
                top: 0, left: padding, bottom: 0, right: padding)
            }
          }
          result(nil)
        } else {
          // Clear padding if args is nil
          if !usesSwiftUI, let button = self.button {
            if #available(iOS 15.0, *) {
              var cfg = button.configuration ?? .plain()
              var insets = cfg.contentInsets
              insets.leading = 0
              insets.trailing = 0
              cfg.contentInsets = insets
              button.configuration = cfg
            } else {
              button.contentEdgeInsets = .zero
            }
          }
          result(nil)
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  func view() -> UIView { container }

  // MARK: - Frame observation

  override func observeValue(
    forKeyPath keyPath: String?,
    of object: Any?,
    change: [NSKeyValueChangeKey: Any]?,
    context: UnsafeMutableRawPointer?
  ) {
    guard keyPath == "frame" || keyPath == "bounds",
      let view = object as? UIView, view === container
    else {
      super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
      return
    }
    DispatchQueue.main.async { [weak self] in
      guard let self = self, let hc = self.hostingController else { return }
      self.container.setNeedsLayout()
      self.container.layoutIfNeeded()
      hc.view.setNeedsLayout()
      hc.view.layoutIfNeeded()
    }
  }

  deinit {
    container.removeObserver(self, forKeyPath: "frame")
    container.removeObserver(self, forKeyPath: "bounds")
  }

  // MARK: - SwiftUI setup

  /// Creates the ViewModel and the hosting controller once. The rootView is never replaced after
  /// this point — all state changes flow through @Published properties on the ViewModel.
  @available(iOS 26.0, *)
  private func setupSwiftUIButton(
    title: String?,
    iconArgs: [String: Any],
    themeArgs: [String: Any],
    style: String,
    enabled: Bool,
    glassEffectUnionId: String?,
    glassEffectId: String?,
    glassEffectInteractive: Bool,
    borderRadius: CGFloat?,
    paddingTop: CGFloat?,
    paddingBottom: CGFloat?,
    paddingLeft: CGFloat?,
    paddingRight: CGFloat?,
    paddingHorizontal: CGFloat?,
    paddingVertical: CGFloat?,
    minHeight: CGFloat,
    spacing: CGFloat,
    imagePlacement: String,
    contentAlignment: String,
    width: CGFloat?,
    expandWidth: Bool
  ) {
    let config = GlassButtonConfig(
      borderRadius: borderRadius,
      top: paddingTop,
      bottom: paddingBottom,
      left: paddingLeft,
      right: paddingRight,
      horizontal: paddingHorizontal,
      vertical: paddingVertical,
      minHeight: minHeight,
      spacing: spacing,
      width: width,
      expandWidth: expandWidth,
      contentAlignment: contentAlignment
    )
    let iconConfig = IconConfig.from(dict: iconArgs)
    let theme = CNButtonTheme.from(dict: themeArgs)

    let viewModel = CupertinoButtonViewModel(
      title: title,
      iconConfig: iconConfig.hasIcon ? iconConfig : nil,
      theme: theme,
      style: style,
      isEnabled: enabled,
      glassEffectUnionId: glassEffectUnionId,
      glassEffectId: glassEffectId,
      glassEffectInteractive: glassEffectInteractive,
      config: config,
      imagePlacement: imagePlacement,
      contentAlignment: contentAlignment
    )
    self._buttonViewModel = viewModel

    struct ButtonWrapperView: View {
      @Namespace private var namespace
      @ObservedObject var viewModel: CupertinoButtonViewModel
      let onPressed: () -> Void

      var body: some View {
        GlassButtonSwiftUI(
          title: viewModel.title,
          iconConfig: viewModel.iconConfig,
          theme: viewModel.theme,
          style: viewModel.style,
          isEnabled: viewModel.isEnabled,
          onPressed: onPressed,
          glassEffectUnionId: viewModel.glassEffectUnionId,
          glassEffectId: viewModel.glassEffectId,
          glassEffectInteractive: viewModel.glassEffectInteractive,
          namespace: namespace,
          config: viewModel.config,
          imagePlacement: viewModel.imagePlacement,
          contentAlignment: viewModel.contentAlignment
        )
      }
    }

    let wrapperView = ButtonWrapperView(
      viewModel: viewModel,
      onPressed: { [weak self] in self?.onPressed(nil) }
    )
    let hostingController = UIHostingController(rootView: AnyView(wrapperView))
    hostingController.view.backgroundColor = .clear
    hostingController.view.insetsLayoutMarginsFromSafeArea = false
    hostingController.additionalSafeAreaInsets = .zero
    self.hostingController = hostingController

    hostingController.view.translatesAutoresizingMaskIntoConstraints = false
    container.addSubview(hostingController.view)
    NSLayoutConstraint.activate([
      hostingController.view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
      hostingController.view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
      hostingController.view.topAnchor.constraint(equalTo: container.topAnchor),
      hostingController.view.bottomAnchor.constraint(equalTo: container.bottomAnchor),
    ])

  }

  // MARK: - ViewModel accessor

  /// Typed accessor for the ViewModel; only valid on iOS 26+.
  @available(iOS 26.0, *)
  private var buttonViewModel: CupertinoButtonViewModel? {
    _buttonViewModel as? CupertinoButtonViewModel
  }

  // MARK: - Button actions / helpers

  @objc private func onPressed(_ sender: UIButton?) {
    guard isEnabled else { return }
    channel.invokeMethod("pressed", arguments: nil)
  }

  private func applyButtonStyle(buttonStyle: String, round: Bool) {
    guard let button = self.button, !usesSwiftUI else { return }

    if #available(iOS 15.0, *) {
      // Preserve current content while swapping configurations
      let currentTitle = button.configuration?.title
      let currentImage = button.configuration?.image
      let currentSymbolCfg = button.configuration?.preferredSymbolConfigurationForImage
      var config: UIButton.Configuration
      switch buttonStyle {
      case "plain": config = .plain()
      case "gray": config = .gray()
      case "tinted": config = .tinted()
      case "bordered": config = .bordered()
      case "borderedProminent": config = .borderedProminent()
      case "filled": config = .filled()
      case "glass":
        if #available(iOS 26.0, *) {
          config = .glass()
        } else {
          config = .tinted()
        }
      case "prominentGlass":
        if #available(iOS 26.0, *) {
          config = .prominentGlass()
        } else {
          config = .tinted()
        }
      default:
        config = .plain()
      }
      config.cornerStyle = round ? .capsule : .dynamic
      let effectiveTint: UIColor? = {
        switch buttonStyle {
        case "filled", "borderedProminent", "prominentGlass":
          return button.tintColor
        case "tinted", "bordered", "gray", "plain", "glass":
          return button.tintColor
        default:
          return nil
        }
      }()
      if let tint = effectiveTint {
        switch buttonStyle {
        case "filled", "borderedProminent", "prominentGlass":
          config.baseBackgroundColor = tint
        case "tinted", "bordered", "gray", "plain", "glass":
          config.baseForegroundColor = tint
          button.tintColor = tint
        default:
          break
        }
      } else if buttonStyle == "glass" {
        button.tintColor = nil
      }
      // Restore content after style swap
      config.title = currentTitle
      config.image = currentImage
      config.preferredSymbolConfigurationForImage = currentSymbolCfg
      button.configuration = config
    } else {
      button.layer.cornerRadius = round ? 999 : 8
      button.clipsToBounds = true
      // Default background to preserve pressed/highlight behavior; custom glass handled above for iOS15+
      button.backgroundColor = .clear
      button.layer.borderWidth = 0
    }
  }

  private func setButtonContent(
    title: String?,
    image: UIImage?,
    iconOnly: Bool,
    imagePlacement: String? = nil,
    imagePadding: CGFloat? = nil,
    horizontalPadding: CGFloat? = nil
  ) {
    guard let button = self.button, !usesSwiftUI else { return }

    if #available(iOS 15.0, *) {
      var cfg = button.configuration ?? .plain()
      if let title = title {
        cfg.title = title
      }

      // Configure single-line text with ellipsis truncation
      cfg.titleLineBreakMode = .byTruncatingTail

      if let image = image {
        cfg.image = image
      }

      // Apply imagePlacement
      if let placement = imagePlacement {
        switch placement {
        case "leading":
          cfg.imagePlacement = .leading
        case "trailing":
          cfg.imagePlacement = .trailing
        case "top":
          cfg.imagePlacement = .top
        case "bottom":
          cfg.imagePlacement = .bottom
        default:
          cfg.imagePlacement = .leading
        }
      }

      // Apply imagePadding
      if let padding = imagePadding {
        cfg.imagePadding = padding
      }

      // Apply horizontalPadding
      if let padding = horizontalPadding {
        var insets = cfg.contentInsets
        insets.leading = padding
        insets.trailing = padding
        cfg.contentInsets = insets
      }

      button.configuration = cfg
    } else {
      button.setTitle(title, for: .normal)

      // Configure titleLabel to prevent text wrapping (default: single line)
      button.titleLabel?.lineBreakMode = .byTruncatingTail
      button.titleLabel?.numberOfLines = 1

      button.setImage(image, for: .normal)
      if iconOnly {
        button.contentEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
      } else if let padding = horizontalPadding {
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: padding, bottom: 0, right: padding)
      }
    }
  }

  private static func createImageFromData(_ data: Data, format: String?, scale: CGFloat) -> UIImage?
  {
    return ImageUtils.createImageFromData(data, format: format, scale: scale)
  }
}
