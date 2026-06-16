import Foundation

/// Builds a self-contained HTML document for an NFO, embedding the bitmap font
/// as a base64 data URI so the Quick Look web renderer has no external
/// dependencies (it cannot reliably reach files inside the extension bundle).
enum NFORenderer {

    /// `fontBase64` is the WOFF font encoded as base64, or nil to fall back to a
    /// system monospaced font.
    static func html(for text: String, fontBase64: String?) -> String {
        let escaped = htmlEscape(text)

        let fontFace: String
        let familyPrefix: String
        if let b64 = fontBase64 {
            fontFace = """
            @font-face {
              font-family: 'NFOFont';
              src: url('data:font/woff;base64,\(b64)') format('woff');
            }
            """
            familyPrefix = "'NFOFont', "
        } else {
            fontFace = ""
            familyPrefix = ""
        }

        return """
        <!DOCTYPE html>
        <html><head><meta charset="utf-8">
        <style>
        \(fontFace)
        html, body { margin: 0; padding: 0; background: #000; }
        pre {
          font-family: \(familyPrefix)'Menlo', 'Courier New', monospace;
          font-size: 16px;
          line-height: 16px;
          color: #c8c8c8;
          white-space: pre;
          padding: 16px;
          -webkit-font-smoothing: none;
          font-smooth: never;
        }
        </style></head>
        <body><pre>\(escaped)</pre></body></html>
        """
    }

    static func htmlEscape(_ s: String) -> String {
        var out = ""
        out.reserveCapacity(s.count + 16)
        for ch in s {
            switch ch {
            case "&": out += "&amp;"
            case "<": out += "&lt;"
            case ">": out += "&gt;"
            default: out.append(ch)
            }
        }
        return out
    }
}
