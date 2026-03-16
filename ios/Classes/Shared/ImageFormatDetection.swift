import Foundation

/// Shared image format detection from path extension and magic bytes.
/// Used by both iOS and macOS ImageUtils; no UIKit/AppKit dependency.
enum ImageFormatDetection {
  /// Detects format from path, explicit format string, or data magic bytes.
  /// Returns "svg", "png", "jpg", or nil.
  static func detect(
    assetPath: String?,
    providedFormat: String? = nil,
    imageData: Data? = nil
  ) -> String? {
    if let format = providedFormat?.lowercased() { return format }
    if let path = assetPath {
      let lower = path.lowercased()
      if lower.hasSuffix(".svg") { return "svg" }
      if lower.hasSuffix(".png") { return "png" }
      if lower.hasSuffix(".jpg") || lower.hasSuffix(".jpeg") { return "jpg" }
    }
    if let data = imageData, data.count >= 4 {
      let bytes = [UInt8](data.prefix(4))
      if bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47 {
        return "png"
      }
      if bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF { return "jpg" }
      if let s = String(data: data.prefix(1024), encoding: .utf8),
         s.hasPrefix("<?xml") || s.trimmingCharacters(in: .whitespaces).hasPrefix("<svg") {
        return "svg"
      }
    }
    return nil
  }
}
