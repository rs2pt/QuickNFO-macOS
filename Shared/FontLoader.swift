import Foundation
import CoreGraphics
import CoreText

/// Shared access to the embedded PxPlus IBM VGA font.
enum FontLoader {

    /// WOFF font as base64, for embedding in the preview HTML. Nil if missing.
    static func webFontBase64() -> String? {
        guard let url = Bundle.main.url(forResource: "WebPlus_IBM_VGA_9x16", withExtension: "woff"),
              let data = try? Data(contentsOf: url) else {
            return nil
        }
        return data.base64EncodedString()
    }

    /// CTFont built straight from the bundled TTF (no global registration needed),
    /// used by the thumbnail renderer. Nil if the font can't be loaded.
    static func thumbnailFont(size: CGFloat) -> CTFont? {
        guard let url = Bundle.main.url(forResource: "PxPlus_IBM_VGA_9x16", withExtension: "ttf"),
              let data = try? Data(contentsOf: url),
              let provider = CGDataProvider(data: data as CFData),
              let cgFont = CGFont(provider) else {
            return nil
        }
        return CTFontCreateWithGraphicsFont(cgFont, size, nil, nil)
    }
}
