#if os(iOS)
import UIKit
/// Platform image type on iOS.
typealias PlatformImage = UIImage
#elseif os(macOS)
import AppKit
/// Platform image type on macOS.
typealias PlatformImage = NSImage
#endif
import SwiftUI

// MARK: - CNImageSource

/// All possible image sources for a button icon.
enum CNImageSource {
  /// SF Symbol — rendered via `Image(systemName:)` in SwiftUI.
  case symbol(name: String)
  /// Image from the app's asset catalog (`UIImage(named:)` / `NSImage`).
  case xcasset(name: String)
  /// Flutter asset path with optional format hint.
  case asset(path: String, format: String?)
  /// Raw PNG bytes.
  case png(data: Data)
  /// Raw JPG bytes.
  case jpg(data: Data)
  /// Raw SVG bytes.
  case svg(data: Data)
  /// Generic raw bytes with an explicit format string.
  case rawData(bytes: Data, format: String)

  var formatString: String? {
    switch self {
    case .png: return "png"
    case .jpg: return "jpg"
    case .svg: return "svg"
    case .rawData(_, let f): return f
    default: return nil
    }
  }
}

// MARK: - CNImageAsset (Swift)

/// Swift image asset: source + optional per-asset color override.
///
/// Call `resolve(width:height:scale:)` to get the platform image.
/// For `.symbol`, resolve returns `(nil, symbolName)` so SwiftUI can render it.
struct CNImageAsset {
  let source: CNImageSource
  let color: PlatformImage?  // non-nil when a per-asset tint was specified

  // MARK: Resolve

  /// Returns `(platformImage, symbolName)`.
  /// Exactly one of the two values is non-nil (symbol → (nil, name), others → (image, nil)).
  func resolve(
    width: CGFloat,
    height: CGFloat,
    scale: CGFloat = _defaultScreenScale()
  ) -> (PlatformImage?, String?) {
    let size = CGSize(width: width, height: height)

    switch source {
    case .symbol(let name):
      return (nil, name)

    case .xcasset(let name):
      return (_loadNamed(name), nil)

    case .asset(let path, let format):
      return (ImageUtils.loadFlutterAsset(path, size: size, format: format, scale: scale), nil)

    case .png(let d), .jpg(let d):
      return (ImageUtils.createImageFromData(d, format: source.formatString, size: size, scale: scale), nil)

    case .svg(let d):
      return (ImageUtils.createImageFromData(d, format: "svg", size: size, scale: scale), nil)

    case .rawData(let bytes, let format):
      return (ImageUtils.createImageFromData(bytes, format: format, size: size, scale: scale), nil)
    }
  }

  // MARK: Parsing

  /// Parses a pre-processed Flutter channel dict → `CNImageAsset`.
  ///
  /// **Important**: `imageBytes` must be pre-converted to `Data` by the caller
  /// (callers that import Flutter can extract `.data` from `FlutterStandardTypedData`).
  ///
  /// Priority: xcasset > assetPath > imageBytes > iconName (SF Symbol).
  static func from(dict: [String: Any]) -> CNImageAsset? {
    let assetColor: PlatformImage? = nil  // color stored separately; callers set it

    if let name = dict["xcassetName"] as? String, !name.isEmpty {
      return CNImageAsset(source: .xcasset(name: name), color: assetColor)
    }
    if let path = dict["assetPath"] as? String, !path.isEmpty {
      let format = dict["imageFormat"] as? String
      return CNImageAsset(source: .asset(path: path, format: format), color: assetColor)
    }
    if let data = dict["imageBytes"] as? Data {
      let format = (dict["imageFormat"] as? String) ?? "png"
      switch format {
      case "svg": return CNImageAsset(source: .svg(data: data), color: assetColor)
      case "jpg", "jpeg": return CNImageAsset(source: .jpg(data: data), color: assetColor)
      default: return CNImageAsset(source: .png(data: data), color: assetColor)
      }
    }
    if let name = dict["iconName"] as? String, !name.isEmpty {
      return CNImageAsset(source: .symbol(name: name), color: assetColor)
    }
    return nil
  }
}

// MARK: - Platform helpers (private)

@inline(__always)
private func _defaultScreenScale() -> CGFloat {
#if os(iOS)
  return UIScreen.main.scale
#elseif os(macOS)
  return NSScreen.main?.backingScaleFactor ?? 2.0
#else
  return 2.0
#endif
}

@inline(__always)
private func _loadNamed(_ name: String) -> PlatformImage? {
#if os(iOS)
  return UIImage(named: name, in: .main, compatibleWith: nil)
#elseif os(macOS)
  return Bundle.main.image(forResource: name)
#else
  return nil
#endif
}

// MARK: - ContentMode + BoxFit

extension SwiftUI.ContentMode {
  /// Maps a Dart `BoxFit.name` string to a SwiftUI `ContentMode`.
  static func from(boxFit: String?) -> SwiftUI.ContentMode {
    switch boxFit {
    case "cover": return .fill
    default:      return .fit   // contain, fitWidth, fitHeight, none, scaleDown
    }
  }
}

// MARK: - IconConfig

@available(iOS 26.0, macOS 26.0, *)
struct IconConfig {
  let asset: CNImageAsset?
  let width: CGFloat
  let height: CGFloat
  let contentMode: SwiftUI.ContentMode

  var hasIcon: Bool { asset != nil }

  /// Parses a Flutter channel dict → `IconConfig`.
  ///
  /// Accepts both plain keys (`iconName`, `iconWidth`) and `button`-prefixed keys
  /// (`buttonIconName`, `buttonIconWidth`) for `CupertinoButtonPlatformView` compatibility.
  ///
  /// The `imageBytes` value must already be a `Data` (not `FlutterStandardTypedData`).
  static func from(dict: [String: Any]) -> IconConfig {
    let width = (dict["iconWidth"] as? CGFloat)
      ?? (dict["buttonIconWidth"] as? CGFloat)
      ?? (dict["iconSize"] as? CGFloat)
      ?? (dict["buttonIconSize"] as? CGFloat)
      ?? 20.0
    let height = (dict["iconHeight"] as? CGFloat)
      ?? (dict["buttonIconHeight"] as? CGFloat)
      ?? width
    let boxFit = (dict["boxFit"] as? String) ?? (dict["buttonBoxFit"] as? String)
    let contentMode = ContentMode.from(boxFit: boxFit)

    // Try plain-key dict, then translate button-prefixed keys.
    let asset = CNImageAsset.from(dict: dict)
      ?? CNImageAsset.from(dict: _buttonPrefixedToPlain(dict))

    return IconConfig(asset: asset, width: width, height: height, contentMode: contentMode)
  }
}

/// Translates `button`-prefixed keys to plain keys so `CNImageAsset.from(dict:)` can parse them.
private func _buttonPrefixedToPlain(_ dict: [String: Any]) -> [String: Any] {
  let keyMap: [String: String] = [
    "buttonIconName":    "iconName",
    "buttonXcassetName": "xcassetName",
    "buttonAssetPath":   "assetPath",
    "buttonImageData":   "imageBytes",
    "buttonImageFormat": "imageFormat",
  ]
  var out = [String: Any]()
  for (prefixed, plain) in keyMap {
    if let val = dict[prefixed] { out[plain] = val }
  }
  return out
}

// MARK: - CNButtonTheme (Swift)

/// Unified color and material theme for glass buttons.
///
/// `tint` takes priority over individual `labelColor`/`iconColor` fields.
@available(iOS 26.0, macOS 26.0, *)
struct CNButtonTheme {
  let tint: Color?
  let labelColor: Color?
  let iconColor: Color?
  let backgroundColor: Color?
  let glassMaterial: String   // "regular" | "clear" | "identity"
  let labelFont: Font?

  // MARK: Effective colors

  var effectiveLabelColor: Color? { tint ?? labelColor }
  var effectiveIconColor: Color? { tint ?? iconColor }
  var effectiveBackgroundColor: Color? { backgroundColor }

  // MARK: Parsing

  static func from(dict: [String: Any]) -> CNButtonTheme {
    CNButtonTheme(
      tint:            dict.argbColor(forKey: "tint"),
      labelColor:      dict.argbColor(forKey: "labelColor"),
      iconColor:       dict.argbColor(forKey: "themeIconColor"),
      backgroundColor: dict.argbColor(forKey: "backgroundColor"),
      glassMaterial:   (dict["glassMaterial"] as? String) ?? "regular",
      labelFont:       dict.swiftUIFont(forKey: "labelStyle")
    )
  }

  static var `default`: CNButtonTheme {
    CNButtonTheme(
      tint: nil, labelColor: nil, iconColor: nil,
      backgroundColor: nil, glassMaterial: "regular", labelFont: nil
    )
  }
}

// MARK: - ARGB → SwiftUI Color (no external dependency)

private extension Dictionary where Key == String, Value == Any {
  /// Decodes an ARGB integer from the dict and returns a SwiftUI `Color`.
  func argbColor(forKey key: String) -> Color? {
    guard let argb = self[key] as? Int else { return nil }
    let a = Double((argb >> 24) & 0xFF) / 255.0
    let r = Double((argb >> 16) & 0xFF) / 255.0
    let g = Double((argb >> 8)  & 0xFF) / 255.0
    let b = Double( argb        & 0xFF) / 255.0
    return Color(.sRGB, red: r, green: g, blue: b, opacity: a)
  }

  /// Decodes a labelStyle dict and returns a SwiftUI `Font`.
  func swiftUIFont(forKey key: String) -> Font? {
    guard let style = self[key] as? [String: Any] else { return nil }
    let size = (style["fontSize"] as? NSNumber).map { CGFloat(truncating: $0) }
    let weight = style["fontWeight"] as? Int
    let family = style["fontFamily"] as? String
    let swiftWeight: Font.Weight
    switch weight ?? 400 {
    case 100: swiftWeight = .ultraLight
    case 200: swiftWeight = .thin
    case 300: swiftWeight = .light
    case 400: swiftWeight = .regular
    case 500: swiftWeight = .medium
    case 600: swiftWeight = .semibold
    case 700: swiftWeight = .bold
    case 800: swiftWeight = .heavy
    case 900: swiftWeight = .black
    default:  swiftWeight = .regular
    }
    let isItalic = (style["italic"] as? Bool) == true
    var font: Font?
    if let family = family, let sz = size {
      font = .custom(family, size: sz)
    } else if let sz = size {
      font = .system(size: sz, weight: swiftWeight)
    }
    if isItalic, let f = font {
      return f.italic()
    }
    return font
  }
}
