import Cocoa
import Quartz
import UniformTypeIdentifiers

/// Data-based Quick Look preview: reads the NFO, decodes it, and hands HTML
/// (with the bitmap font embedded) back to Quick Look to render.
class PreviewProvider: QLPreviewProvider, QLPreviewingController {

    func providePreview(for request: QLFilePreviewRequest) async throws -> QLPreviewReply {
        let url = request.fileURL
        let didScope = url.startAccessingSecurityScopedResource()
        defer { if didScope { url.stopAccessingSecurityScopedResource() } }

        let data = (try? Data(contentsOf: url)) ?? Data()
        let text = NFODecoder.decode(data)
        let html = NFORenderer.html(for: text, fontBase64: FontLoader.webFontBase64())
        let htmlData = Data(html.utf8)

        let reply = QLPreviewReply(dataOfContentType: .html,
                                   contentSize: CGSize(width: 900, height: 1000)) { _ in
            htmlData
        }
        reply.stringEncoding = .utf8
        return reply
    }
}
