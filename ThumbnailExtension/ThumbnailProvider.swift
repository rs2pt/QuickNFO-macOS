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
        // Trim blank leading/trailing lines so the art centers on its content.
        while let first = lines.first, first.trimmingCharacters(in: .whitespaces).isEmpty {
            lines.removeFirst()
        }
        while let last = lines.last, last.trimmingCharacters(in: .whitespaces).isEmpty {
            lines.removeLast()
        }
        guard !lines.isEmpty else { return }
        if lines.count > maxLines { lines = Array(lines.prefix(maxLines)) }
        let maxCols = max(lines.map { $0.count }.max() ?? 1, 1)

        let inset: CGFloat = 4
        let availW = size.width - inset * 2
        let availH = size.height - inset * 2

        // Measure the font's advance at a reference size to derive the advance
        // per point of font size, then pick the largest font size that fits both
        // the widest column and all the rows.
        let refSize: CGFloat = 32
        guard let refFont = FontLoader.thumbnailFont(size: refSize) else { return }
        let refAdvance = monospaceAdvance(refFont)
        guard refAdvance > 0 else { return }
        let advanceRatio = refAdvance / refSize

        var fontSize = availW / (CGFloat(maxCols) * advanceRatio)
        fontSize = min(fontSize, availH / CGFloat(lines.count))
        fontSize = max(fontSize, 1)

        guard let font = FontLoader.thumbnailFont(size: fontSize) else { return }
        let advance = advanceRatio * fontSize
        let blockW = CGFloat(maxCols) * advance
        let blockH = CGFloat(lines.count) * fontSize

        // Center the whole block; every line shares originX so the ASCII art
        // alignment is preserved (left-aligned within a centered block).
        let originX = (size.width - blockW) / 2
        let topY = (size.height + blockH) / 2   // top edge of the block (CG coords)
        let ascent = CTFontGetAscent(font)

        let textColor = CGColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1)
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: textColor]

        ctx.textMatrix = .identity
        for (i, lineStr) in lines.enumerated() where !lineStr.isEmpty {
            let line = CTLineCreateWithAttributedString(
                NSAttributedString(string: lineStr, attributes: attrs))
            ctx.textPosition = CGPoint(x: originX, y: topY - ascent - CGFloat(i) * fontSize)
            CTLineDraw(line, ctx)
        }
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
