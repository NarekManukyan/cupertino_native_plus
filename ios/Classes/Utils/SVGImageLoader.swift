import UIKit
import SVGKit
import Flutter

/// Renders SVG to UIImage (asset path or data). No caching — ImageManager caches all results.
final class SVGImageLoader {

    static let shared = SVGImageLoader()

    private let preloadQueue = DispatchQueue(label: "svg.preload", qos: .userInitiated)
    private var isInitialized = false

    private init() {
        preloadSVGKit()
    }

    /// Load SVG from Flutter asset path and render to UIImage. Caching is done by ImageManager.
    func loadSVG(from assetPath: String, size: CGSize = CGSize(width: 24, height: 24)) -> UIImage? {
        loadSVGFromBundle(assetPath: assetPath, size: size)
    }

    /// Load SVG from raw data and render to UIImage. Caching is done by ImageManager.
    func loadSVG(from data: Data, size: CGSize = CGSize(width: 24, height: 24)) -> UIImage? {
        loadSVGFromData(data: data, size: size)
    }

    /// Preload SVG assets (warms SVGKit and can be used to prime ImageManager cache via ImageUtils).
    func preloadAssets(_ assetPaths: [String]) {
        preloadQueue.async { [weak self] in
            for path in assetPaths {
                _ = self?.loadSVG(from: path)
            }
        }
    }

    func preloadAssetsFromPaths(_ assetPaths: [String]) {
        guard !assetPaths.isEmpty else { return }
        preloadAssets(assetPaths)
    }

    private func preloadSVGKit() {
        guard !isInitialized else { return }
        
        preloadQueue.async { [weak self] in
            // Create a dummy SVG to initialize SVGKit
            let dummySVG = """
            <svg width="1" height="1" viewBox="0 0 1 1" xmlns="http://www.w3.org/2000/svg">
                <rect width="1" height="1" fill="transparent"/>
            </svg>
            """
            
            if let data = dummySVG.data(using: .utf8) {
                _ = SVGKImage(data: data)
                self?.isInitialized = true
            }
        }
    }
    
    private func loadSVGFromBundle(assetPath: String, size: CGSize) -> UIImage? {
        let flutterKey = FlutterDartProject.lookupKey(forAsset: assetPath)
        
        guard let path = Bundle.main.path(forResource: flutterKey, ofType: nil) else {
            return nil
        }
        
        return loadSVGFromFile(path: path, size: size)
    }
    
    private func loadSVGFromData(data: Data, size: CGSize) -> UIImage? {
        guard let svgImage = SVGKImage(data: data) else {
            return nil
        }
        
        return renderSVGImage(svgImage, size: size)
    }
    
    private func loadSVGFromFile(path: String, size: CGSize) -> UIImage? {
        guard let svgImage = SVGKImage(contentsOfFile: path) else {
            return nil
        }
        
        return renderSVGImage(svgImage, size: size)
    }
    
    private func renderSVGImage(_ svgImage: SVGKImage, size: CGSize) -> UIImage? {
        // Ensure we're on the main thread for SVG rendering
        if Thread.isMainThread {
            return performSVGRendering(svgImage, size: size)
        } else {
            var result: UIImage?
            DispatchQueue.main.sync {
                result = performSVGRendering(svgImage, size: size)
            }
            return result
        }
    }
    
    private func performSVGRendering(_ svgImage: SVGKImage, size: CGSize) -> UIImage? {
        // Set the desired size
        svgImage.size = size
        
        // Force immediate rendering
        let uiImage = svgImage.uiImage
        
        // If still nil, try alternative approach
        if uiImage == nil {
            // Sometimes SVGKit needs the size to be set again
            svgImage.size = size
            return svgImage.uiImage
        }
        
        return uiImage
    }
}

// MARK: - Convenience Extensions

extension SVGImageLoader {
    
    /// Load SVG with default 24x24 size
    func loadSVG(from assetPath: String) -> UIImage? {
        return loadSVG(from: assetPath, size: CGSize(width: 24, height: 24))
    }
    
    /// Load SVG with default 24x24 size from data
    func loadSVG(from data: Data) -> UIImage? {
        return loadSVG(from: data, size: CGSize(width: 24, height: 24))
    }
}
