import Foundation

/// Decodes raw NFO bytes into text.
///
/// Modern NFOs are sometimes UTF-8, but the classic scene NFOs are encoded in
/// IBM PC code page 437 (DOS Latin US), which is what gives them their
/// box-drawing / block-character ASCII art. We try strict UTF-8 first and fall
/// back to CP437.
enum NFODecoder {

    static func decode(_ data: Data) -> String {
        if let utf8 = decodeUTF8(data) {
            return utf8
        }
        return decodeCP437(data)
    }

    private static func decodeUTF8(_ data: Data) -> String? {
        var bytes = data
        // Strip a UTF-8 BOM if present.
        if bytes.count >= 3, bytes[bytes.startIndex] == 0xEF,
           bytes[bytes.startIndex + 1] == 0xBB,
           bytes[bytes.startIndex + 2] == 0xBF {
            bytes = bytes.subdata(in: (bytes.startIndex + 3)..<bytes.endIndex)
        }
        // String(data:encoding:.utf8) returns nil on invalid byte sequences,
        // so this rejects CP437 content that isn't coincidentally valid UTF-8.
        return String(data: bytes, encoding: .utf8)
    }

    private static func decodeCP437(_ data: Data) -> String {
        let cfEnc = CFStringEncoding(CFStringEncodings.dosLatinUS.rawValue)
        let nsEnc = CFStringConvertEncodingToNSStringEncoding(cfEnc)
        if let s = String(data: data, encoding: String.Encoding(rawValue: nsEnc)) {
            return s
        }
        // CP437 maps all 256 byte values, so the above should never fail.
        // Latin-1 is a 1:1 byte fallback just in case.
        return String(data: data, encoding: .isoLatin1) ?? ""
    }
}
