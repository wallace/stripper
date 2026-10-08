# Stripper

A macOS menu-bar utility that watches the clipboard and removes tracking query
parameters (`utm_*`, `fbclid`, `gclid`, YouTube `si`, Amazon `pd_rd_*`, and others)
from links you copy, replacing the clipboard contents with the clean link.

```
https://example.com/post?id=7&utm_source=twitter&fbclid=abc  →  https://example.com/post?id=7
```

- Only acts when the **entire** clipboard is a single valid `http`/`https` URL, meaning a
  plain GET link. Prose containing a link and `mailto:`, `file:`, `javascript:` and other
  schemes are left alone.
- Never makes network requests.
- Skips clipboard content that password managers mark as concealed or transient.
- Includes site-specific rules for YouTube, Spotify, X/Twitter, all Amazon storefronts,
  LinkedIn, Facebook, TikTok, Reddit, Google, Bing, eBay, and AliExpress.

## Requirements

- macOS 14 (Sonoma) or later
- Swift 6 toolchain, from either Xcode or the Command Line Tools:

  ```bash
  xcode-select --install
  ```

## Install

```bash
git clone https://github.com/wallace/stripper.git
cd stripper
./build-app.sh
cp -R build/Stripper.app /Applications/
```

`build-app.sh` compiles a release build and packages it as an ad-hoc-signed
`build/Stripper.app`.

## Run

```bash
open /Applications/Stripper.app
```

Stripper runs in the menu bar (banana icon) with no Dock icon. The banana flashes in
colour each time a link is cleaned. The menu has these items:

| Item | What it does |
| --- | --- |
| Clean Copied Links | Turn cleaning on or off |
| Show Notifications | Show a banner each time a link is cleaned (off by default; macOS asks for permission the first time) |
| Launch at Login | Start Stripper automatically when you log in |
| Copy Last Original Link | Put the last original, uncleaned link back on the clipboard (useful if a cleaned link breaks) |
| Quit Stripper | Quit the app |

To try it, copy a tracking link and paste it anywhere:

```bash
printf 'https://example.com/?id=1&utm_source=test' | pbcopy; sleep 1; pbpaste
```

### Uninstall

Quit Stripper from its menu, turn off Launch at Login first if you enabled it, then delete
`/Applications/Stripper.app`.

## Development

Tracking rules live in [`Sources/StripperCore/TrackingRules.swift`](Sources/StripperCore/TrackingRules.swift);
validation and cleaning are in [`URLCleaner.swift`](Sources/StripperCore/URLCleaner.swift).

The app icon and menu bar glyph are drawn by [`Resources/banana.py`](Resources/banana.py);
`Resources/make-icon.sh` regenerates `AppIcon.icns` and `MenuBarIcon.png`
(needs `brew install librsvg`). The generated files are committed.

Run the tests with Xcode selected (`xcode-select -s /Applications/Xcode.app`):

```bash
swift test
```

With only the Command Line Tools, point the compiler at the Swift Testing macro plugin:

```bash
swift test -Xswiftc -plugin-path -Xswiftc /Library/Developer/CommandLineTools/usr/lib/swift/host/plugins/testing
```
