import UIKit

/// Single manager for all Flutter-provided images: asset paths, raw data, SVG, PNG, JPG.
/// One cache (NSCache), one API: check cache → load on miss → store with cost → return.
/// Use via ImageManager.shared.image(assetPath:...) or image(data:...).
/// All widgets should use ImageUtils.loadFlutterAsset / createImageFromData which delegate here.
final class ImageManager {

    static let shared = ImageManager()

    private let cache = NSCache<NSString, UIImage>()
    private let lock = NSLock()

    private(set) var hitCount: Int = 0
    private(set) var missCount: Int = 0

    private init() {
        setupCache()
        setupMemoryWarningObserver()
    }

    // MARK: - Single API: load and cache all image types

    /// Loads an image from a Flutter asset path (any format: SVG, PNG, JPG). Cached.
    func image(
        assetPath: String,
        size: CGSize? = nil,
        color: UIColor? = nil,
        format: String? = nil,
        scale: CGFloat = UIScreen.main.scale
    ) -> UIImage? {
        let colorARGB = color.flatMap { ImageUtils.colorToARGB($0) }
        let key = cacheKey(for: assetPath, size: size, color: colorARGB)
        if let cached = cachedImage(for: key) {
            return cached
        }
        guard let image = ImageUtils.loadFlutterAssetUncached(
            assetPath,
            size: size,
            format: format,
            color: color,
            scale: scale
        ) else {
            return nil
        }
        cacheImage(image, for: key)
        return image
    }

    /// Loads an image from raw data (any format: SVG, PNG, JPG). Cached.
    func image(
        data: Data,
        size: CGSize? = nil,
        color: UIColor? = nil,
        format: String? = nil,
        scale: CGFloat = UIScreen.main.scale
    ) -> UIImage? {
        let colorARGB = color.flatMap { ImageUtils.colorToARGB($0) }
        let key = cacheKey(for: data, size: size, color: colorARGB)
        if let cached = cachedImage(for: key) {
            return cached
        }
        guard let image = ImageUtils.createImageFromDataUncached(
            data,
            format: format,
            size: size,
            color: color,
            scale: scale
        ) else {
            return nil
        }
        cacheImage(image, for: key)
        return image
    }

    // MARK: - Cache key / get / set (used internally and by image())

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

    func cachedImage(for key: String) -> UIImage? {
        lock.lock()
        defer { lock.unlock() }
        if let image = cache.object(forKey: key as NSString) {
            hitCount += 1
            return image
        }
        missCount += 1
        return nil
    }

    func cacheImage(_ image: UIImage, for key: String, cost: Int? = nil) {
        lock.lock()
        defer { lock.unlock() }
        let imageCost = cost ?? estimateImageCost(image)
        cache.setObject(image, forKey: key as NSString, cost: imageCost)
    }

    func removeImage(for key: String) {
        lock.lock()
        defer { lock.unlock() }
        cache.removeObject(forKey: key as NSString)
    }

    func clearCache() {
        lock.lock()
        defer { lock.unlock() }
        cache.removeAllObjects()
        hitCount = 0
        missCount = 0
    }

    var hitRate: Double {
        let total = hitCount + missCount
        return total > 0 ? Double(hitCount) / Double(total) * 100 : 0
    }

    private func setupCache() {
        cache.countLimit = ImageManagerConfig.countLimit
        cache.totalCostLimit = ImageManagerConfig.totalCostLimit
        cache.name = ImageManagerConfig.cacheName
    }

    private func setupMemoryWarningObserver() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.clearCache()
        }
    }

    private func estimateImageCost(_ image: UIImage) -> Int {
        let bytesPerPixel = 4
        let width = Int(image.size.width * image.scale)
        let height = Int(image.size.height * image.scale)
        return width * height * bytesPerPixel
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
