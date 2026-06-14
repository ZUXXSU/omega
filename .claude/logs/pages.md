# Web/Pages Analysis Log

## Status: Analysis Complete

**Platform:** web/pages (Jekyll static site — delta.chat)
**Analysis Date:** 2026-06-14
**Source Repo:** /Volumes/KRYPTIX/test2/sources/deltachat-pages (shallow commit 7f576a4)

---

## Content Structure

### Tech Stack

| Layer | Technology |
|---|---|
| Static site generator | Jekyll |
| Content format | Markdown with Liquid templating |
| Frontend | HTML / CSS / JS |
| Offline resilience | LibResilient service worker (alt-fetch, cache, delay plugins) |
| Internationalization | Transifex (20+ languages, YAML string files per locale) |
| Syndication | RSS / Atom feed (https://delta.chat/feed.xml) |
| Comments | Mastodon / Fediverse API (chaos.social) |
| Comment sanitization | DOMPurify |
| Hosting | GitHub Pages + Hetzner |
| Sitemap | jekyll-sitemap plugin |
| PWA | service-worker.js |

### Data Models

**Blog post front matter fields:**
- `title` — post title
- `author` — author name
- `date` — publication date
- `image` — featured image path
- `excerpt` — short summary shown in card grid
- `com_id` — Mastodon thread ID for comment loading
- `is_post` — flag to differentiate posts from pages
- `lang` — locale code

**Page front matter fields:**
- `title`
- `lang`
- `render_toc` — enables table-of-contents include
- `header` — optional hero header
- `downloads` — flag enabling download box includes
- `is_post`
- `image`
- `com_id`
- `author`

**Language YAML keys (per locale in _data/lang/{locale}.yaml):**
- Menu labels: `home`, `download`, `blog`, `contribute`, `help`, `forum`
- Meta: `description`, `keywords`
- Download strings
- Help offline hint
- `references`, `donate`, `imprint`, `privacy`, `rss_news_title`

**Download box fields:**
- Platform name
- Store badges with alt text
- Minimum OS version requirement
- Direct download URLs
- Source code link
- Expandable "no automatic updates" details section

**FAQ structure:**
- h2 — category heading
- h3 — question (with optional anchor ID for deep linking)
- Markdown body (may include inline images)

**Site config (_config.yml):**
- Permalink pattern
- Jekyll defaults
- kramdown `auto_ids`
- Sass compression
- `jekyll-sitemap` plugin
- `.well-known` include
- Excluded paths: `tools/`, `venv/`

---

## All Pages

### Primary Navigation (top bar)

| Label | Path | Notes |
|---|---|---|
| Home | `/en/` | Landing page |
| Download | `/en/download` | Platform download boxes |
| Blog | `/en/blog` | Post index |
| Contribute | `/en/contribute` | Community channels |
| FAQ / Help | `/en/help` | 60+ Q&A across 9 sections |
| Forum | `support.delta.chat` | External link (Discourse) |

### Footer-Only Pages

| Label | Path |
|---|---|
| References | `/en/references` |
| Donate | `/en/donate` |
| Imprint | `/en/imprint` |
| Privacy Policy (website) | `/en/gdpr-website` |
| Privacy Policy (app) | `/en/gdpr` |
| Community Standards | `/en/community-standards` |
| Server Guide | `/en/serverguide` |
| Verify Downloads | `/en/verify-downloads` |
| Chatmail | `/en/chatmail` (redirect to chatmail.at/relays) |

### Special / Event Pages

- 404 error page
- CCC Congress pages: 35c3 through 39c3

### Page-by-Page Breakdown

**Landing Page (`en/index.md`)**
- Hero section with 5 bullet points:
  1. Reliable instant messaging
  2. Chatmail relay signup
  3. In-chat web apps (webxdc)
  4. Audited E2EE
  5. FOSS on internet standards
- Platform screenshot gallery: Android x2, Desktop, iOS
- CTA "Download" button (`.cta-button` class)
- Feature bullets with icons

**Download Page (`en/download.md`)**
- Per-platform download boxes (from `_includes/download-boxes.html`, current version 2.52.0):
  - **Android:** Google Play Store, F-Droid, Huawei AppGallery, Obtainium, direct APK
  - **iOS / iPad:** App Store
  - **macOS:** Mac App Store, Homebrew
  - **Windows:** Microsoft Store, winget, portable EXE
  - **GNU/Linux:** Flathub, Flatpak, Arch pacman, Nix, Snap, FreeBSD
  - **Ubuntu Touch:** Open Store
- Each box includes minimum OS version, store badge images (WebP/PNG with `<picture>` fallback), expandable "no automatic updates" detail section
- Changelog links per platform
- Apple Smart App Banner meta tag
- Verify Downloads cross-link

**Blog (`en/blog.md` + `_includes/blog.html`)**
- 12 most recent posts displayed as full cards with: featured image, title, author, date, excerpt, "Read on..." link
- Older posts shown as compact list (title + date only)
- RSS/Atom feed subscription links
- Comments section per post: Mastodon/Fediverse API (lazy-loaded via "Show Comments" button)
  - Fetches from `chaos.social/api/v1/statuses/{com_id}/context`
  - DOMPurify sanitizes HTML before render
  - Fediverse creator meta tag: `@delta@chaos.social`

**FAQ / Help (`en/help.md`, ~1200 lines)**
- 9 section categories with h2 headings
- 60+ Q&A items with h3 headings (anchor IDs for deep linking)
- Table of contents (TOC) include at top
- Offline hint banner
- Sections:
  1. General (What is Delta Chat, finding contacts, profiles, pinning/archiving, saved messages)
  2. Groups
  3. Channels
  4. Calls
  5. In-chat Apps (webxdc)
  6. Instant Delivery / Push Notifications
  7. Multi-client / Multi-device
  8. Advanced / Experimental
  9. Encryption & Security
  10. Miscellaneous

**Contribute Page (`en/contribute.md`)**
- Community channels
- Fediverse links
- Support forum link
- GitHub repo links
- Translation links (Transifex)
- CTA "Donate" button (`.cta-button` class)

**Donate Page (`en/donate.md`)**
- Payment options:
  - Liberapay (recurring)
  - Open Collective (organizational transparency)
  - Bitcoin
  - IBAN wire transfer + EPC QR code image (inline)
- All options link externally except QR code shown inline

**References Page (`en/references.md`)**
- Press and media mentions
- Scrollable list with source links and quotes

**Community Standards (`en/community-standards.md`)**
- Code of Conduct

**Server Guide (`en/serverguide.md`)**
- Mailcow + mailadm self-hosting setup
- Docker configuration
- DNS setup (DKIM, TLS)
- TOC include enabled

**Privacy Policy — App (`en/gdpr.md`)**
- Full GDPR compliance table mapping requirements to Delta Chat implementation:
  - Confidentiality
  - Data minimization
  - Data avoidance
  - Legal basis
  - Data to/from third parties
  - DPIA
  - Documentation

**Privacy Policy — Website (`en/gdpr-website.md`)**
- Data controller: merlinux GmbH
- Log file processing info
- Hetzner hosting DPA reference
- Discourse forum data processing details

**Imprint / Legal Notice (`en/imprint.md`)**
- merlinux GmbH
- Amtsgericht Freiburg HRB709589
- VAT DE814082730
- Data protection officer: Prof. Dr. Fabian Schmieder

**Verify Downloads (`en/verify-downloads.md`)**
- APK SHA256 fingerprint verification instructions
- GPG-signed desktop checksums verification
- Platform-specific command blocks (copyable text)

**Chatmail (`en/chatmail`)**
- Redirect page forwarding to chatmail.at/relays

---

## Onboarding Flow

Source: `_posts/2024-05-31-instant-onboarding.md`

### Step-by-Step Flow (3 screens)

**Screen 1 — Name Entry**
- User enters display name only
- No email address required at this stage

**Screen 2 — Agreement**
- Single "Agree and continue" tap
- No lengthy form

**Screen 3 — Auto Profile Creation**
- System automatically creates a chatmail profile at the default relay server
- Profile is instantly usable

### Alternative Paths from Screen 2

- "Use other server" — allows selecting a different chatmail relay
- "Manual login" — traditional email + password entry for existing email accounts

### Key Onboarding Touchpoints to Replicate

- Instant profile creation (no pre-existing email required)
- QR code contact exchange (scan-to-add)
- Invite link sharing (share URL to add contact)
- Group chat invite flow
- In-app first-run tips for webxdc and channels

---

## Flutter Web Implementation Notes

### Architecture Decisions

**Navigation**
- Mobile: Bottom navigation bar (BottomNavigationBar or NavigationBar)
- Desktop/tablet: Side navigation rail (NavigationRail)
- Tabs: Home, Download, Blog, FAQ, Contribute
- Forum: External link via `url_launcher` (no in-app nav item, treat as external)

**Platform Detection for Download Page**
- Use `dart:io` `Platform` class to detect current OS
- Show the relevant platform's download box prominently
- Fall back to showing all platforms in a scrollable list
- Store badge deep links via `url_launcher` / `flutter_launch_url`

**FAQ Page**
- Implement as `ExpansionTile` list
- Section headers (9 categories) as non-expandable dividers or `ListTile` headers
- 60+ individual Q&A items as `ExpansionTile` widgets
- Content available offline — bundle FAQ content as app assets (no network fetch required)
- Match original design intent: offline-first FAQ

**Blog Page**
- Paginated card list: featured image, title, date, author, excerpt
- 12 featured posts as full cards (`Card` widget with image + text)
- Older posts as compact `ListTile` list
- Mastodon comments: use `webview_flutter` to show comment thread, or external browser link to Mastodon thread (JS-dependent feature, not natively portable)

**Landing / Home Page**
- Replicate 5 hero bullet points exactly:
  1. Reliable instant messaging
  2. Chatmail relay signup
  3. In-chat web apps (webxdc)
  4. Audited E2EE
  5. FOSS on internet standards
- Screenshot gallery: `PageView` or `CarouselView` for Android, iOS, Desktop screenshots
- CTA "Download" button: `ElevatedButton` with prominent styling

**Contribute Page**
- Community channel links via `url_launcher`
- CTA "Donate" button: `ElevatedButton` with prominent styling

**Donate Page**
- List of payment options linking externally (Liberapay, OpenCollective, Bitcoin)
- IBAN wire transfer info as selectable text
- EPC QR code: show inline as `Image` widget

**Verify Downloads Page**
- Platform-specific command blocks
- Use `SelectableText` for all commands to allow clipboard copy
- `CopyButton` affordance next to each code block

**References Page**
- Scrollable `ListView` of press quotes with source URLs
- `url_launcher` for source links

**Chatmail Page**
- Either inline `WebView` (webview_flutter) to chatmail.at/relays
- Or external browser launch via `url_launcher`

### Feature-by-Feature Flutter Mapping

| Web Feature | Flutter Equivalent |
|---|---|
| LibResilient service worker | Native asset bundling + `cached_network_image` + `hive` / `objectbox` for offline |
| Mastodon blog comments | `webview_flutter` or external browser link |
| Language switcher (20+ locales) | `flutter_localizations` + ARB files mapped from Transifex strings |
| Transifex i18n strings | ARB file generation from Transifex export |
| Download platform badges | `url_launcher` deep links per store |
| RSS feed | External link or in-app `webview_flutter` RSS reader |
| ATProto DID / Fediverse meta | Not applicable to Flutter app |
| Google Site Verification | Not applicable |
| Flathub verification | Not applicable |
| security.txt | Not applicable |
| PWA via service-worker.js | Not applicable to mobile/desktop Flutter |
| DOMPurify comment sanitization | Not required if using webview_flutter for comments |
| EPC QR code (donate) | `Image.asset` or generate via `qr_flutter` |
| Expandable download "no auto-update" details | `ExpansionTile` |
| TOC for long pages (FAQ, serverguide) | Anchor scroll index with `Scrollable.ensureVisible` or `scrollable_positioned_list` |

### webxdc In-Chat Apps

- HTML/CSS/JS zip files run in a sandboxed webview
- Flutter implementation: `webview_flutter` with restricted navigation policy
- Serve webxdc content via local HTTP server or Flutter asset serving
- Realtime P2P channel (Iroh protocol): advanced, defer or use iroh Rust bindings via FFI

### Push Notifications

- iOS: Apple Push Notification Service (APN) — standard via `firebase_messaging` or native APN
- Android: Google Firebase Cloud Messaging (FCM) — standard via `firebase_messaging`; also supports microG

### Multi-Device Transfer

- Local Wi-Fi QR scan pattern
- Flutter packages: `wifi_iot` + `qr_code_scanner` + local HTTP server

### Audio/Video Calls

- WebRTC (calls-webapp)
- Flutter package: `flutter_webrtc`

### Security UI (V2 — August 2025+)

- Drop all lock icons and green checkmarks from E2EE messages
- Omega UI must follow the simplified V2 model
- No visual indicators distinguishing encrypted vs plaintext — encryption is assumed baseline
- Source: `_posts/2025-08-04-encryption-v2.md`

### Browser Edition Constraint (2025 note)

- Core Rust library (`deltachat-core-rust`) is not yet WASM-compilable
- Requires a server component for web deployment
- Flutter web has the same constraint — use deltachat-core-rust via FFI on mobile/desktop
- Do not target Flutter web as a primary delivery platform for core messaging functionality

### Onboarding Wizard (Flutter)

Implement as 2-3 screen `PageView` or named route flow:

1. **Screen 1:** `TextField` for display name entry
2. **Screen 2:** Agreement prompt with "Agree and continue" `ElevatedButton` + secondary options ("Use other server", "Manual login")
3. **Screen 3:** Loading indicator while chatmail profile is auto-created, then transition to main app shell

Key UX: instant, zero-friction — no email pre-required.

---

## Key Files to Reference

| File | Purpose |
|---|---|
| `en/index.md` | Landing page content and hero bullets |
| `en/help.md` | Full FAQ — ~1200 lines, 9 sections, 60+ Q&A |
| `en/download.md` | Download page with changelog links |
| `en/blog.md` | Blog index |
| `en/contribute.md` | Community channels |
| `en/donate.md` | Donation options |
| `en/references.md` | Press mentions |
| `en/community-standards.md` | Code of Conduct |
| `en/serverguide.md` | Mailcow self-hosting guide |
| `en/gdpr.md` | App GDPR privacy policy |
| `en/gdpr-website.md` | Website GDPR privacy policy |
| `en/imprint.md` | Legal notice |
| `en/verify-downloads.md` | APK and desktop integrity verification |
| `_layouts/default.html` | Nav, header, footer, TOC, comments structure |
| `_includes/download-boxes.html` | All platform download widgets (version 2.52.0) |
| `_includes/blog.html` | 12-post featured + older list layout |
| `_includes/comments.html` | Mastodon API comment loader |
| `_data/lang/en.yaml` | All UI string keys for English locale |
| `_config.yml` | Jekyll config, permalink, defaults |
| `service-worker.js` | LibResilient offline caching |
| `_posts/2024-05-31-instant-onboarding.md` | Onboarding UX design rationale |
| `_posts/2025-05-22-browser-edition.md` | Browser/web edition technical details |
| `_posts/2025-08-04-encryption-v2.md` | V2 security upgrade, UI simplification |
| `_posts/2026-03-31-zero.md` | Zero metadata, native calls, latest features |

**Repo location:** `/Volumes/KRYPTIX/test2/sources/deltachat-pages`
(shallow clone — commit 7f576a4 — working tree may not be fully checked out)

---

## Next Steps

### Immediate

1. **Check out full working tree** of `deltachat-pages` repo to access all source files (current state is shallow clone only)
2. **Extract en.yaml string keys** from `_data/lang/en.yaml` and map to ARB file structure for `flutter_localizations`
3. **Export all 20+ locale YAML files** from Transifex and convert to ARB format (`intl_translation` or `slang` package)

### Content Migration

4. **Parse `en/help.md`** (~1200 lines) into structured data model (JSON/Dart objects) for the FAQ `ExpansionTile` tree — 9 sections, 60+ items
5. **Extract blog post metadata** (title, author, date, image, excerpt, com_id) from `_posts/` into a Dart-accessible JSON feed or static asset
6. **Port download box data** from `_includes/download-boxes.html` into a Dart config file with per-platform store URLs and badge assets — keep version number (2.52.0) as a single constant

### UI Components to Build

7. **Landing page hero** — 5 bullet points + screenshot `CarouselView` + CTA `ElevatedButton`
8. **Download page** — platform detection + store badge grid + `ExpansionTile` for "no auto-update" details
9. **FAQ page** — `ExpansionTile` list with 9 section headers and 60+ items, offline-first asset bundle
10. **Blog card grid** — `Card` widgets with image, title, date, author, excerpt; paginated; compact list for older posts
11. **Donate page** — payment options list + inline QR code `Image` widget
12. **Verify Downloads page** — `SelectableText` code blocks with copy affordance
13. **Onboarding wizard** — 2-3 screen `PageView` flow (name entry, agreement, auto-profile creation)

### Integrations

14. **Push notifications** — integrate `firebase_messaging` for FCM (Android) and APN (iOS)
15. **Mastodon comments** — decide: `webview_flutter` embed or external browser link; external is simpler and avoids JS runtime complexity
16. **webxdc sandboxed webview** — implement local asset server + `webview_flutter` with restricted navigation for in-chat apps
17. **Multi-device transfer** — `qr_code_scanner` + local HTTP server for Wi-Fi QR transfer flow
18. **Audio/video calls** — `flutter_webrtc` integration for WebRTC calls-webapp

### Security / Compliance

19. **Implement V2 encryption UI** — remove all lock icons and green checkmarks; encryption is assumed baseline (per `_posts/2025-08-04-encryption-v2.md`)
20. **GDPR documentation** — include in-app privacy policy screen mapping to `en/gdpr.md` content
21. **Verified download integrity** — if distributing APK directly, replicate SHA256 fingerprint verification instructions from `en/verify-downloads.md`

### Deferred / Out of Scope for V1

- Flutter web deployment (blocked by deltachat-core-rust WASM constraint)
- Iroh/P2P realtime channel (webxdc realtime API — requires Rust FFI bindings)
- LibResilient direct equivalent (not needed; Flutter asset bundling covers offline use)
- ATProto DID, Fediverse meta tags, Google Site Verification (web-only concerns)
- CCC Congress event pages (historical, not needed in app)
- Jekyll sitemap / RSS feed generation (web-only)
