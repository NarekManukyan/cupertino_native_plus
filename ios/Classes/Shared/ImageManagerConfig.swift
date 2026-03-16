import Foundation

/// Shared cache configuration for ImageManager. Used by both iOS and macOS.
enum ImageManagerConfig {
  static let cacheName = "com.cupertino_native_better.ImageManager"
  static let countLimit = 100
  static let totalCostLimit = 50 * 1024 * 1024
}
