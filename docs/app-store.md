# Releasing Link Stripper to the Mac App Store

## One-time setup

1. **Pick your team in Xcode.** Open `LinkStripper.xcodeproj`, select the
   *LinkStripper* target › *Signing & Capabilities*, and choose your team. Keep
   "Automatically manage signing" on. Xcode creates the certificates, the App ID
   `io.github.wallace.stripper` and the provisioning profile for you. (Or put your Team ID
   in `DEVELOPMENT_TEAM` in `project.yml` and run `xcodegen generate`.)
2. **Create the app in App Store Connect.** <https://appstoreconnect.apple.com> › Apps ›
   **+** › New App:
   - Platform: macOS
   - Name: Link Stripper (must be unique on the store; if taken, try "Link Stripper –
     Clean URLs")
   - Primary language: English (U.S.)
   - Bundle ID: `io.github.wallace.stripper`
   - SKU: `linkstripper-mac`

## Each release

1. Bump `MARKETING_VERSION` (and always `CURRENT_PROJECT_VERSION`) in `project.yml`, then
   run `xcodegen generate`.
2. In Xcode choose **Product › Archive**, then **Distribute App › App Store Connect ›
   Upload**.
3. In App Store Connect, add the build to the version, fill in "What's New", and
   **Submit for Review**.

## Listing

| Field | Value |
| --- | --- |
| Name (30) | Link Stripper |
| Subtitle (30) | Remove tracking from links |
| Category | Utilities |
| Price | Free |
| Age rating | 4+ (answer "None" to everything) |
| Copyright | 2026 Jonathan R. Wallace |
| Support URL | https://github.com/wallace/stripper/issues |
| Marketing URL | https://github.com/wallace/stripper |
| Privacy Policy URL | https://github.com/wallace/stripper/blob/main/PRIVACY.md |
| App Privacy | Data Not Collected |

**Promotional text (170)**

> Copy a link, paste a clean one. Link Stripper quietly removes utm_, fbclid, gclid and
> other trackers from links you copy, right on your Mac.

**Keywords (100)**

```
utm,tracking,privacy,url,clean,clipboard,fbclid,gclid,share,menu bar,links,strip,remover
```

**Description**

> Link Stripper removes tracking parameters from links you copy, so the links you share
> don't tell anyone where they came from.
>
> Copy a link from anywhere and Link Stripper replaces it on your clipboard with a clean
> version. Paste as usual.
>
> https://example.com/article?id=7&utm_source=newsletter&fbclid=abc
> becomes
> https://example.com/article?id=7
>
> WHAT IT REMOVES
> • Campaign tags such as utm_source, utm_medium and utm_campaign
> • Ad click IDs from Google, Facebook, Microsoft, TikTok, X, LinkedIn and more
> • Email-marketing trackers from Mailchimp, HubSpot, Marketo and others
> • Share trackers on YouTube, Spotify, Instagram, Reddit, Amazon (every storefront),
>   eBay and AliExpress
>
> WHAT IT KEEPS
> Everything a link needs to work: search queries, video IDs, page numbers and anchors stay
> exactly as they were.
>
> PRIVATE BY DESIGN
> • Works entirely on your Mac. It makes no network connections.
> • Only touches the clipboard when it holds a single web link. On macOS 15.4 and later
>   it checks for a link without reading anything else you copy.
> • Ignores passwords and other content marked private by password managers.
> • No accounts, analytics or ads.
>
> IN YOUR MENU BAR
> • A banana that flashes when a link is cleaned
> • Optional notifications showing what was removed
> • Copy Last Original Link, if you ever need the original back
> • Launch at login

**Review notes**

> Link Stripper is a menu bar app (no Dock icon). Look for the banana icon in the menu bar.
>
> To test: copy this link in any app, then paste it anywhere.
> https://example.com/?id=1&utm_source=review&fbclid=test
> The pasted result is https://example.com/?id=1 and the banana briefly turns yellow.
>
> If macOS asks whether Link Stripper may paste from another app, choose Allow. The app
> checks with the system whether the clipboard holds a web link before reading it, and
> only reads and rewrites single http/https links. It has no network access.

## Screenshots

The Mac App Store needs 1 to 10 screenshots at a 16:10 size: 1280×800, 1440×900,
2560×1600 or 2880×1800. Useful shots:

1. The menu open from the banana, over a browser window.
2. A "Link cleaned" notification banner.
3. Before/after of a pasted link (for example in Notes or Messages).

Take them with ⇧⌘5. If your display isn't 16:10, crop or resize to one of the sizes
above.

## Planned

- **1.1: tip jar.** Add two or three consumable In-App Purchase tips under a "Support Link
  Stripper" menu item. This needs the Paid Apps agreement, tax and banking info in App
  Store Connect first.
