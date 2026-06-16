# QuickNFO (modern)

Quick Look **preview** and **thumbnail** for `.nfo` files on modern macOS
(tested on macOS 26 / Apple Silicon).

The original [planbnet/QuickNFO](https://github.com/planbnet/QuickNFO) is a
legacy `.qlgenerator` plugin. That plugin architecture was removed from recent
macOS — user `~/Library/QuickLook` generators are no longer loaded and their
custom UTIs are no longer registered. This project reimplements the same idea
as a modern **App Extension** bundle, which macOS still supports.

## What it does

- **Preview** (spacebar in Finder): decodes the NFO (UTF-8, falling back to
  CP437 / DOS Latin US) and renders it as HTML with an embedded IBM VGA bitmap
  font, so the box-drawing / block ASCII art looks right.
- **Thumbnail** (Finder icon): draws the first lines of the art with the same
  font straight into the thumbnail context (no WebKit, robust in the background
  thumbnail agent).

## Architecture

| Target | Type | Role |
|--------|------|------|
| `QuickNFO` | macOS app | Host app; exports the `com.rs2pt.nfo` UTI (extension `nfo`, conforms to `public.plain-text`) and embeds the two extensions. |
| `PreviewExtension` | `com.apple.quicklook.preview` | Data-based `QLPreviewProvider` returning HTML. |
| `ThumbnailExtension` | `com.apple.quicklook.thumbnail` | `QLThumbnailProvider` drawing with CoreText. |

Shared code (`Shared/`): `NFODecoder` (encoding), `NFORenderer` (HTML),
`FontLoader` (embedded font access).

## Build

Requires Xcode and [XcodeGen](https://github.com/yonghuang/XcodeGen)
(`brew install xcodegen`).

```sh
xcodegen generate
xcodebuild -project QuickNFO.xcodeproj -scheme QuickNFO -configuration Release \
  -derivedDataPath build CODE_SIGN_IDENTITY="-" build
```

The signed `QuickNFO.app` lands in `build/Build/Products/Release/`.

## Install

```sh
cp -R build/Build/Products/Release/QuickNFO.app /Applications/
open /Applications/QuickNFO.app   # launch once so macOS registers the extensions
```

Then select a `.nfo` in Finder and press space, or look at its icon. If a
preview/thumbnail doesn't appear immediately, run `qlmanage -r` and
`qlmanage -r cache`.

To verify registration: `pluginkit -mv | grep rs2pt`.

## Credits

Inspired by the original [planbnet/QuickNFO](https://github.com/planbnet/QuickNFO)
(a legacy `.qlgenerator` plugin). This is an independent rewrite in Swift as a
modern App Extension; no original source code was reused.

## License

This project's code is licensed under the **MIT License** — see [`LICENSE`](LICENSE).

The embedded **PxPlus / WebPlus IBM VGA 9x16** font is from the *Ultimate
Oldschool PC Font Pack* by VileR (<https://int10h.org/oldschool-pc-fonts/>),
licensed **CC BY-SA 4.0** separately from the code. See
`Resources/LICENSE-FONT.txt`.
