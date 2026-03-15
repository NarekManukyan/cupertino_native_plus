import AppKit
import FlutterMacOS

/// Shared utility for image loading, color conversion, and format detection on macOS.
/// Raster formats (PNG, JPG) are supported; SVG is not rendered natively on macOS.
final class ImageUtils {

  // MARK: - Color Conversion

  static func colorFromARGB(_ argb: Int) -> NSColor {
    let a = CGFloat((argb >> 24) & 0xFF) / 255.0
    let r = CGFloat((argb >> 16) & 0xFF) / 255.0
    let g = CGFloat((argb >> 8) & 0xFF) / 255.0
    let b = CGFloat(argb & 0xFF) / 255.0
    return NSColor(srgbRed: r, green: g, blue: b, alpha: a)
  }

  static func colorToARGB(_ color: NSColor) -> Int? {
    guard let rgbColor = color.usingColorSpace(.sRGB) else { return nil }
    var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
    rgbColor.getRed(&r, green: &g, blue: &b, alpha: &a)
    return (Int(a * 255) & 0xFF) << 24 | (Int(r * 255) & 0xFF) << 16 | (Int(g * 255) & 0xFF) << 8 | (Int(b * 255) & 0xFF)
  }

  // MARK: - Format Detection

  static func detectImageFormat(assetPath: String?, providedFormat: String? = nil, imageData: Data? = nil) -> String? {
    if let format = providedFormat?.lowercased() { return format }
    if let path = assetPath {
      let lower = path.lowercased()
      if lower.hasSuffix(".svg") { return "svg" }
      if lower.hasSuffix(".png") { return "png" }
      if lower.hasSuffix(".jpg") || lower.hasSuffix(".jpeg") { return "jpg" }
    }
    if let data = imageData, data.count >= 4 {
      let bytes = [UInt8](data.prefix(4))
      if bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47 { return "png" }
      if bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF { return "jpg" }
      if let s = String(data: data.prefix(1024), encoding: .utf8),
         (s.hasPrefix("<?xml") || s.trimmingCharacters(in: .whitespaces).hasPrefix("<svg")) { return "svg" }
    }
    return nil
  }

  // MARK: - Image Loading (raster only; SVG returns nil on macOS)

  /// Loads an image from Flutter asset with caching. Uses ImageManager.
  static func loadFlutterAsset(
    _ assetPath: String,
    size: CGSize? = nil,
    format: String? = nil,
    color: NSColor? = nil,
    scale: CGFloat = NSScreen.main?.backingScaleFactor ?? 2.0
  ) -> NSImage? {
    ImageManager.shared.image(assetPath: assetPath, size: size, color: color, format: format, scale: scale)
  }

  /// Used by ImageManager only.
  static func loadFlutterAssetUncached(
    _ assetPath: String,
    size: CGSize? = nil,
    format: String? = nil,
    color: NSColor? = nil,
    scale: CGFloat = NSScreen.main?.backingScaleFactor ?? 2.0
  ) -> NSImage? {
    let detectedFormat = format ?? detectImageFormat(assetPath: assetPath)
    if detectedFormat == "svg" { return nil }
    let flutterKey = FlutterDartProject.lookupKey(forAsset: assetPath)
    guard let path = Bundle.main.path(forResource: flutterKey, ofType: nil) else { return nil }
    guard var image = NSImage(contentsOfFile: path) else { return nil }
    if let col = color {
      image = image.tinted(with: col)
    }
    return image
  }

  /// Creates an image from raw data with caching. Uses ImageManager.
  static func createImageFromData(
    _ data: Data,
    format: String? = nil,
    size: CGSize? = nil,
    color: NSColor? = nil,
    scale: CGFloat = NSScreen.main?.backingScaleFactor ?? 2.0
  ) -> NSImage? {
    ImageManager.shared.image(data: data, size: size, color: color, format: format, scale: scale)
  }

  /// Used by ImageManager only.
  static func createImageFromDataUncached(
    _ data: Data,
    format: String? = nil,
    size: CGSize? = nil,
    color: NSColor? = nil,
    scale: CGFloat = NSScreen.main?.backingScaleFactor ?? 2.0
  ) -> NSImage? {
    let detectedFormat = format ?? detectImageFormat(assetPath: nil, imageData: data)
    if detectedFormat == "svg" { return nil }
    guard var image = NSImage(data: data) else { return nil }
    if let col = color {
      image = image.tinted(with: col)
    }
    return image
  }

  /// Tint an NSImage with a color (template-style).
  static func tint(image: NSImage, with color: NSColor) -> NSImage {
    image.tinted(with: color)
  }

  /// Convenience: load and optionally tint from asset path (ARGB color).
  static func loadAndTintImage(
    from assetPath: String,
    iconSize: CGFloat? = nil,
    iconColor: Int? = nil,
    providedFormat: String? = nil,
    scale: CGFloat = NSScreen.main?.backingScaleFactor ?? 2.0
  ) -> NSImage? {
    let size = iconSize.map { CGSize(width: $0, height: $0) }
    let color = iconColor.map { colorFromARGB($0) }
    return loadFlutterAsset(assetPath, size: size, format: detectImageFormat(assetPath: assetPath, providedFormat: providedFormat), color: color, scale: scale)
  }

  /// Convenience: create and optionally tint from data (ARGB color).
  static func createAndTintImage(
    from data: Data,
    iconSize: CGFloat? = nil,
    iconColor: Int? = nil,
    providedFormat: String? = nil,
    scale: CGFloat = NSScreen.main?.backingScaleFactor ?? 2.0
  ) -> NSImage? {
    let size = iconSize.map { CGSize(width: $0, height: $0) }
    let color = iconColor.map { colorFromARGB($0) }
    return createImageFromData(data, format: detectImageFormat(assetPath: nil, providedFormat: providedFormat, imageData: data), size: size, color: color, scale: scale)
  }
}

extension NSImage {
  /// Returns a copy of the image tinted with the given color.
  func tinted(with color: NSColor) -> NSImage {
    let img = NSImage(size: size)
    img.lockFocus()
    let rect = NSRect(origin: .zero, size: size)
    color.set()
    rect.fill()
    draw(in: rect, from: .zero, operation: .destinationIn, fraction: 1.0)
    img.unlockFocus()
    return img
  }
}
