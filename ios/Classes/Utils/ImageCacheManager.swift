import UIKit

/// Unified image cache manager for all image types (PNG, JPG, raw bytes)
/// SVG caching is handled separately by SVGImageLoader
final class ImageCacheManager {

    // MARK: - Singleton
    static let shared = ImageCacheManager()

    // MARK: - Properties
    private let cache = NSCache<NSString, UIImage>()
    private let lock = NSLock()

    // MARK: - Cache Statistics
    private(set) var hitCount: Int = 0
    private(set) var missCount: Int = 0

    // MARK: - Initialization
    private init() {
        setupCache()
        setupMemoryWarningObserver()
    }

    // MARK: - Public API

    /// Generates a cache key for image data
    /// - Parameters:
    ///   - data: Image data bytes
    ///   - size: Optional size for the image
    ///   - color: Optional ARGB color for tinting
    /// - Returns: Unique cache key string
    func cacheKey(for data: Data, size: CGSize? = nil, color: Int? = nil) -> String {
        let hash = data.hashValue
        let sizeStr = size.map { "\(Int($0.width))x\(Int($0.height))" } ?? "original"
        let colorStr = color.map { String(format: "%08X", $0) } ?? "none"
        return "data_\(hash)_\(sizeStr)_\(colorStr)"
    }

    /// Generates a cache key for asset path
    /// - Parameters:
    ///   - assetPath: Flutter asset path
    ///   - size: Optional size for the image
    ///   - color: Optional ARGB color for tinting
    /// - Returns: Unique cache key string
    func cacheKey(for assetPath: String, size: CGSize? = nil, color: Int? = nil) -> String {
        let sizeStr = size.map { "\(Int($0.width))x\(Int($0.height))" } ?? "original"
        let colorStr = color.map { String(format: "%08X", $0) } ?? "none"
        return "asset_\(assetPath)_\(sizeStr)_\(colorStr)"
    }

    /// Retrieves a cached image
    /// - Parameter key: Cache key
    /// - Returns: Cached UIImage or nil if not found
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

    /// Stores an image in the cache
    /// - Parameters:
    ///   - image: UIImage to cache
    ///   - key: Cache key
    ///   - cost: Optional memory cost (defaults to estimated image size)
    func cacheImage(_ image: UIImage, for key: String, cost: Int? = nil) {
        lock.lock()
        defer { lock.unlock() }

        // Calculate cost based on image dimensions and scale
        let imageCost = cost ?? estimateImageCost(image)
        cache.setObject(image, forKey: key as NSString, cost: imageCost)
    }

    /// Removes a specific image from cache
    /// - Parameter key: Cache key
    func removeImage(for key: String) {
        lock.lock()
        defer { lock.unlock() }
        cache.removeObject(forKey: key as NSString)
    }

    /// Clears all cached images
    func clearCache() {
        lock.lock()
        defer { lock.unlock() }
        cache.removeAllObjects()
        hitCount = 0
        missCount = 0
    }

    /// Returns cache hit rate as a percentage
    var hitRate: Double {
        let total = hitCount + missCount
        return total > 0 ? Double(hitCount) / Double(total) * 100 : 0
    }

    // MARK: - Convenience Methods

    /// Loads an image from cache or creates it using the provided closure
    /// - Parameters:
    ///   - key: Cache key
    ///   - creator: Closure that creates the image if not cached
    /// - Returns: UIImage (from cache or newly created)
    func image(for key: String, creator: () -> UIImage?) -> UIImage? {
        // Check cache first
        if let cached = cachedImage(for: key) {
            return cached
        }

        // Create the image
        guard let image = creator() else {
            return nil
        }

        // Cache and return
        cacheImage(image, for: key)
        return image
    }

    // MARK: - Private Methods

    private func setupCache() {
        // Set cache limits
        cache.countLimit = 100  // Maximum 100 images
        cache.totalCostLimit = 50 * 1024 * 1024  // 50MB
        cache.name = "com.cupertino_native_better.ImageCache"
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
        // Estimate memory usage: width * height * bytes per pixel * scale^2
        let bytesPerPixel = 4  // RGBA
        let width = Int(image.size.width * image.scale)
        let height = Int(image.size.height * image.scale)
        return width * height * bytesPerPixel
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - ImageUtils Integration Extension

extension ImageCacheManager {

    /// Loads an image from Flutter asset with caching
    /// - Parameters:
    ///   - assetPath: Flutter asset path
    ///   - size: Optional size for the image
    ///   - color: Optional ARGB color for tinting
    ///   - format: Optional format string
    ///   - scale: Image scale
    /// - Returns: UIImage or nil if failed
    func loadCachedFlutterAsset(
        _ assetPath: String,
        size: CGSize? = nil,
        color: Int? = nil,
        format: String? = nil,
        scale: CGFloat = UIScreen.main.scale
    ) -> UIImage? {
        // Generate cache key
        let key = cacheKey(for: assetPath, size: size, color: color)

        // Try cache first
        if let cached = cachedImage(for: key) {
            return cached
        }

        // Load from ImageUtils
        let uiColor: UIColor? = color.map { ImageUtils.colorFromARGB($0) }
        guard let image = ImageUtils.loadFlutterAsset(
            assetPath,
            size: size,
            format: format,
            color: uiColor,
            scale: scale
        ) else {
            return nil
        }

        // Cache and return
        cacheImage(image, for: key)
        return image
    }

    /// Creates an image from data with caching
    /// - Parameters:
    ///   - data: Image data bytes
    ///   - size: Optional size for the image
    ///   - color: Optional ARGB color for tinting
    ///   - format: Optional format string
    ///   - scale: Image scale
    /// - Returns: UIImage or nil if failed
    func loadCachedImageFromData(
        _ data: Data,
        size: CGSize? = nil,
        color: Int? = nil,
        format: String? = nil,
        scale: CGFloat = UIScreen.main.scale
    ) -> UIImage? {
        // Generate cache key
        let key = cacheKey(for: data, size: size, color: color)

        // Try cache first
        if let cached = cachedImage(for: key) {
            return cached
        }

        // Load from ImageUtils
        let uiColor: UIColor? = color.map { ImageUtils.colorFromARGB($0) }
        guard let image = ImageUtils.createImageFromData(
            data,
            format: format,
            size: size,
            color: uiColor,
            scale: scale
        ) else {
            return nil
        }

        // Cache and return
        cacheImage(image, for: key)
        return image
    }
}
