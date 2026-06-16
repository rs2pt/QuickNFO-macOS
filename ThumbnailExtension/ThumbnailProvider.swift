import QuickLookThumbnailing
import CoreText
import CoreGraphics
import AppKit

/// Renders the first lines of the NFO into the thumbnail context using the
/// bitmap font, sized so the widest line fits. The goal is to convey the shape
/// of the ASCII art, not full legibility at small sizes.
class ThumbnailProvider: QLThumbnailProvider {

    private static let maxLines = 60

    override func provideThumbnail(for request: QLFileThumbnailRequest,
                                   _ handler: @escaping (QLThumbnailReply?, Error?) -> Void) {
        let url = request.fileURL
        let didScope = url.startAccessingSecurityScopedResource()
        let data = (try? Data(contentsOf: url)) ?? Data()
        if didScope { url.stopAccessingSecurityScopedResource() }

        let text = NFODecoder.decode(data)
        let size = request.maximumSize

        let reply = QLThumbnailReply(contextSize: size) { (ctx: CGContext) -> Bool in
            Self.draw(text: text, in: ctx, size: size)
            return true
        }
        handler(reply, nil)
    }

    private static func draw(text: String, in ctx: CGContext, size: CGSize) {
        // Black background, like a terminal.
        ctx.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
        ctx.fill(CGRect(origin: .zero, size: size))

        var lines = text.replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .components(separatedBy: "\n")
        if lines.count > maxLines { lines = Array(lines.prefix(maxLines)) }
        let maxCols = max(lines.map { $0.count }.max() ?? 1, 1)

        let inset: CGFloat = 4
        let availW = size.width - inset * 2
        let availH = size.height - inset * 2

        // Measure the font's advance at a reference size to derive an exact
        // font size that fits `maxCols` columns into the available width, then
        // cap it so `lines.count` rows also fit the height.
        let refSize: CGFloat = 32
        guard let refFont = FontLoader.thumbnailFont(size: refSize) else { return }
        let advance = monospaceAdvance(refFont)
        guard advance > 0 else { return }

        var fontSize = (availW / CGFloat(maxCols)) * refSize / advance
        let lineHeightRatio: CGFloat = 1.0 // bitmap font: line box == em
        let maxByHeight = availH / (CGFloat(lines.count) * lineHeightRatio)
        fontSize = min(fontSize, maxByHeight)
        fontSize = max(fontSize, 1)

        guard let font = FontLoader.thumbnailFont(size: fontSize) else { return }

        let attr = NSMutableAttributedString()
        let textColor = CGColor(red: 0.78, green: 0.78, blue: 0.78, alpha: 1)
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byClipping
        paragraph.maximumLineHeight = fontSize
        paragraph.minimumLineHeight = fontSize

        let joined = lines.joined(separator: "\n")
        attr.append(NSAttributedString(string: joined, attributes: [
            .font: font,
            .foregroundColor: textColor,
            .paragraphStyle: paragraph,
        ]))

        let framesetter = CTFramesetterCreateWithAttributedString(attr)
        let textRect = CGRect(x: inset, y: inset, width: availW, height: availH)
        let path = CGPath(rect: textRect, transform: nil)
        let frame = CTFramesetterCreateFrame(framesetter, CFRange(location: 0, length: 0), path, nil)
        CTFrameDraw(frame, ctx)
    }

    /// Horizontal advance of a representative glyph at the font's size.
    private static func monospaceAdvance(_ font: CTFont) -> CGFloat {
        var glyph = CTFontGetGlyphWithName(font, "M" as CFString)
        if glyph == 0 {
            // Fall back to the space glyph if "M" isn't named.
            let chars: [UniChar] = Array("0".utf16)
            var glyphs = [CGGlyph](repeating: 0, count: chars.count)
            CTFontGetGlyphsForCharacters(font, chars, &glyphs, chars.count)
            glyph = glyphs[0]
        }
        var advance = CGSize.zero
        CTFontGetAdvancesForGlyphs(font, .horizontal, [glyph], &advance, 1)
        return advance.width
    }
}
