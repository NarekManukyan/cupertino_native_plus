import AppKit

/// Single manager for all Flutter-provided images on macOS (asset paths, raw data, PNG, JPG).
/// One cache (NSCache), one API: check cache → load on miss → store with cost → return.
final class ImageManager {

    static let shared = ImageManager()

    private let cache = NSCache<NSString, NSImage>()
    private let lock = NSLock()

    private init() {
        setupCache()
    }

    // MARK: - Single API

    func image(
        assetPath: String,
        size: CGSize? = nil,
        color: NSColor? = nil,
        format: String? = nil,
        scale: CGFloat = NSScreen.main?.backingScaleFactor ?? 2.0
    ) -> NSImage? {
        let colorARGB = color.flatMap { ImageUtils.colorToARGB($0) }
        let key = cacheKey(for: assetPath, size: size, color: colorARGB)
        if let cached = cachedImage(for: key) { return cached }
        guard let image = ImageUtils.loadFlutterAssetUncached(assetPath, size: size, format: format, color: color, scale: scale) else { return nil }
        cacheImage(image, for: key)
        return image
    }

    func image(
        data: Data,
        size: CGSize? = nil,
        color: NSColor? = nil,
        format: String? = nil,
        scale: CGFloat = NSScreen.main?.backingScaleFactor ?? 2.0
    ) -> NSImage? {
        let colorARGB = color.flatMap { ImageUtils.colorToARGB($0) }
        let key = cacheKey(for: data, size: size, color: colorARGB)
        if let cached = cachedImage(for: key) { return cached }
        guard let image = ImageUtils.createImageFromDataUncached(data, format: format, size: size, color: color, scale: scale) else { return nil }
        cacheImage(image, for: key)
        return image
    }

    func cacheKey(for data: Data, size: CGSize? = nil, color: Int? = nil) -> String {
        let hash = data.hashValue
        let sizeStr = size.map { "\(Int($0.width))x\(Int($0.height))" } ?? "original"
        let colorStr = color.map { String(format: "%08X", $0) } ?? "none"
        return "data_\(hash)_\(sizeStr)_\(colorStr)"
    }

    func cacheKey(for assetPath: String, size: CGSize? = nil, color: Int? = nil) -> String {
        let sizeStr = size.map { "\(Int($0.width))x\(Int($0.height))" } ?? "original"
        let colorStr = color.map { String(format: "%08X", $0) } ?? "none"
        return "asset_\(assetPath)_\(sizeStr)_\(colorStr)"
    }

    func cachedImage(for key: String) -> NSImage? {
        lock.lock()
        defer { lock.unlock() }
        return cache.object(forKey: key as NSString)
    }

    func cacheImage(_ image: NSImage, for key: String, cost: Int? = nil) {
        lock.lock()
        defer { lock.unlock() }
        let imageCost = cost ?? estimateImageCost(image)
        cache.setObject(image, forKey: key as NSString, cost: imageCost)
    }

    func clearCache() {
        lock.lock()
        defer { lock.unlock() }
        cache.removeAllObjects()
    }

    private func setupCache() {
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024
        cache.name = "com.cupertino_native_better.ImageManager"
    }

    private func estimateImageCost(_ image: NSImage) -> Int {
        if let rep = image.representations.first, rep.pixelsWide > 0, rep.pixelsHigh > 0 {
            return rep.pixelsWide * rep.pixelsHigh * 4
        }
        return Int(image.size.width * image.size.height) * 4
    }
}
