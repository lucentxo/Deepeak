import SwiftUI
import AppKit

/// Helper that caches pre-rendered tinted NSImages to avoid re-rasterizing every frame
struct DeepSeekLogoLoader {
    private static var cachedBaseImage: NSImage? = {
        let possiblePaths: [String?] = [
            Bundle.main.path(forResource: "deepseek_logo", ofType: "png"),
            Bundle.main.bundleURL.appendingPathComponent("Contents/Resources/deepseek_logo.png").path,
            "/Users/lucent/Documents/Projects/DeepSeekStatus/Resources/deepseek_logo.png"
        ]
        
        for path in possiblePaths.compactMap({ $0 }) {
            if FileManager.default.fileExists(atPath: path),
               let img = NSImage(contentsOfFile: path) {
                return img
            }
        }
        return nil
    }()
    
    // Cache specific rendered sizes (e.g. 22x22 for menu bar, 28x28 for popover)
    private static var imageCache: [String: NSImage] = [:]
    
    /// Generates a tinted NSImage of the official DeepSeek logo with caching
    static func tintedImage(isOffPeak: Bool, targetSize: CGSize) -> NSImage {
        let cacheKey = "\(isOffPeak ? "offpeak" : "peak")_\(Int(targetSize.width))x\(Int(targetSize.height))"
        if let cached = imageCache[cacheKey] {
            return cached
        }
        
        guard let base = cachedBaseImage else {
            return NSImage(size: targetSize)
        }
        
        // DeepSeek brand electric blue vs solid dark slate/black
        let tintColor: NSColor = isOffPeak
            ? NSColor(red: 0.18, green: 0.42, blue: 1.0, alpha: 1.0)
            : NSColor(red: 0.15, green: 0.15, blue: 0.17, alpha: 1.0)
        
        let outputImage = NSImage(size: targetSize)
        outputImage.lockFocus()
        
        let rect = NSRect(origin: .zero, size: targetSize)
        base.draw(in: rect, from: .zero, operation: .copy, fraction: 1.0)
        
        // Tint the non-transparent pixels
        tintColor.set()
        rect.fill(using: .sourceAtop)
        
        outputImage.unlockFocus()
        outputImage.isTemplate = false
        
        imageCache[cacheKey] = outputImage
        return outputImage
    }
}

/// SwiftUI View rendering the official DeepSeek Whale logo
struct DeepSeekWhaleLogo: View {
    var isOffPeak: Bool
    var size: CGFloat = 22
    
    var body: some View {
        Image(nsImage: DeepSeekLogoLoader.tintedImage(isOffPeak: isOffPeak, targetSize: CGSize(width: size, height: size)))
            .resizable()
            .interpolation(.high)
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
    }
}

extension DeepSeekWhaleLogo {
    static func generateImage(isOffPeak: Bool, size: CGFloat = 22) -> NSImage {
        return DeepSeekLogoLoader.tintedImage(isOffPeak: isOffPeak, targetSize: CGSize(width: size, height: size))
    }
}
