# Omega — Flutter Package Reference

All recommended packages for the Omega messenger. Versions are pinned to stable releases as of June 2026. Use `^` range in pubspec.yaml to allow patch updates.

---

## Core Engine

| Package | Version | Purpose |
|---|---|---|
| (no pub package) | — | `deltachat-rpc-server` binary spawned as subprocess; communicate via stdin/stdout JSON-RPC in background Dart isolate |
| `flutter_rust_bridge` | `^2.x` | Optional: direct FFI path to deltachat-core if subprocess is replaced later |

Notes:
- Spawn `deltachat-rpc-server` from Flutter assets or bundled binary
- All RPC communication is JSON over stdin/stdout in a `compute`-isolated Dart Isolate
- Event stream is a continuous stdout reader; requests/responses matched by `id` field

---

## State Management

| Package | Version | Purpose |
|---|---|---|
| `flutter_riverpod` | `^2.6.1` | Primary state management |
| `riverpod_annotation` | `^2.3.5` | Code-gen annotations for providers |
| `riverpod_generator` | `^2.4.3` | (dev) Generate provider boilerplate |
| `build_runner` | `^2.4.13` | (dev) Code generation runner |

Provider architecture:
- `AccountsProvider` — list of all accounts, selected account
- `ChatListProvider(accountId)` — live chat list for an account
- `MessageListProvider(accountId, chatId)` — paginated message list
- `ChatProvider(accountId, chatId)` — single chat metadata
- `ContactProvider(accountId, contactId)` — single contact
- `SettingsProvider(accountId)` — user preferences + config
- `EventStreamProvider(accountId)` — raw DeltaChat events stream

---

## Navigation

| Package | Version | Purpose |
|---|---|---|
| `go_router` | `^14.6.3` | Declarative routing with `StatefulShellRoute` |

Route structure:
- `StatefulShellRoute` — 3 persistent tabs: `/chats`, `/qr`, `/settings`
- `/chats/:accountId/:chatId` — chat view
- `/contacts/:accountId/:contactId` — contact profile
- `/media/:accountId/:chatId` — media gallery
- Deep links: `openpgp4fpr:`, `dcaccount:`, `dclogin:`, `socks5:`, `ss:`, `mailto:`, `https://i.delta.chat/...`

---

## Chat UI

| Package | Version | Purpose |
|---|---|---|
| `flutter_linkify` | `^6.0.0` | Auto-linkify URLs, emails in text messages |
| `emoji_picker_flutter` | `^3.1.3` | Emoji picker for composition and reactions |
| `flutter_slidable` | `^3.1.1` | Swipe-to-archive in chat list |
| `badges` | `^3.1.2` | Unread count badges on chat rows |
| `timeago` | `^3.7.0` | Relative timestamps ("2 min ago") |
| `audio_waveforms` | `^1.0.5` | Voice message waveform during record + playback |
| `photo_view` | `^0.15.0` | Fullscreen image zoom/pan viewer |

---

## Media & Files

| Package | Version | Purpose |
|---|---|---|
| `file_picker` | `^8.3.7` | Pick files (all types) for sending |
| `image_picker` | `^1.1.2` | Pick image/video from camera or gallery |
| `image_cropper` | `^5.0.1` | Crop avatar images |
| `cached_network_image` | `^3.4.1` | Efficient image loading + caching |
| `flutter_svg` | `^2.0.17` | Render QR SVG strings from core (primary QR display) |
| `video_player` | `^2.9.3` | Inline video playback in chat |
| `media_kit` | `^1.x` | Alternative to video_player with better desktop support |
| `media_kit_video` | `^1.x` | Video widget for media_kit |
| `media_kit_libs_*` | `^1.x` | Platform libraries for media_kit |
| `record` | `^5.2.2` | Voice recording (OGG/Opus Android, M4A iOS, OGG desktop) |
| `just_audio` | `^0.9.43` | Audio playback (voice + audio files) |
| `audio_session` | `^0.1.21` | Audio focus + lock-screen controls for just_audio |
| `open_file` | `^3.5.10` | Open files with OS default application |
| `gal` | `^2.3.0` | Save images/videos to device gallery (cross-platform) |
| `desktop_drop` | `^0.4.4` | Drag-and-drop file receive on desktop |
| `share_plus` | `^10.1.4` | Share files + text to other apps |

---

## QR Codes

| Package | Version | Purpose |
|---|---|---|
| `mobile_scanner` | `^6.x` | Camera-based QR code scanning (all platforms) |
| `flutter_svg` | `^2.0.17` | Display QR: render SVG string from `getChatSecurejoinQrCodeSvg` RPC |
| `qr_flutter` | `^4.1.0` | Fallback QR generation if core SVG not available |

Notes:
- Primary approach: core generates SVG string → `flutter_svg` renders it
- `mobile_scanner` replaces: jsqr (desktop), ZXing (Android), AVFoundation (iOS)

---

## Notifications & Background

| Package | Version | Purpose |
|---|---|---|
| `firebase_core` | `^3.13.0` | Firebase initialization |
| `firebase_messaging` | `^15.2.5` | FCM push notifications (Android + iOS) |
| `flutter_local_notifications` | `^18.0.1` | Display local notifications, foreground notifications |
| `flutter_app_badger` | `^1.5.0` | App icon badge (unread count) |
| `workmanager` | `^0.5.2` | Android background polling (FOSS build without FCM) |
| `flutter_callkit_incoming` | `^2.x` | CallKit (iOS) + ConnectionService (Android) for call UI |

Notes:
- FCM token obtained via `firebase_messaging` → passed to core as `device_token` config
- FOSS flavor: skip `firebase_messaging` + `firebase_core`; use `workmanager` for polling
- iOS NSE is a separate native Swift Xcode target — NOT a Flutter package

---

## Security & Storage

| Package | Version | Purpose |
|---|---|---|
| `flutter_secure_storage` | `^9.2.4` | DB passphrase storage; keychain/keystore per platform |
| `local_auth` | `^2.3.0` | Biometric screen lock (fingerprint/face) |
| `flutter_windowmanager` | `^0.3.0` | Android `FLAG_SECURE` (no screenshots) |
| `permission_handler` | `^11.4.0` | Request camera/mic/storage/notifications permissions |

Notes:
- iOS `flutter_secure_storage`: set `IOSOptions.groupId = 'group.chat.omega.messenger'` so passphrase survives app reinstall
- `flutter_secure_storage` also used for iOS/Android keychain persistence of tokens

---

## WebXDC & WebView

| Package | Version | Purpose |
|---|---|---|
| `flutter_inappwebview` | `^6.x` | Sandboxed WebXDC WebView + HTML email + connectivity HTML |

WebXDC implementation notes:
- Custom URL scheme handler: `webxdc://` → serve `.xdc` zip file contents
- No internet access allowed inside WebXDC WebView
- JavaScript channel injection: `window.webxdc` API (sendUpdate, setUpdateListener, sendRealtimeData)
- Also used for: HTML email rendering, `getConnectivityHtml` details screen

---

## WebRTC Calls

| Package | Version | Purpose |
|---|---|---|
| `flutter_webrtc` | `^0.x` | WebRTC peer connection (audio + video calls) |
| `flutter_callkit_incoming` | `^2.x` | Native call UI (CallKit iOS, ConnectionService Android) |

Notes:
- Replaces: Electron WebRTC (desktop), webrtc-android (Android), WebRTC-lib pod (iOS)
- VoIP push: PushKit (iOS) triggers `flutter_callkit_incoming`

---

## Location

| Package | Version | Purpose |
|---|---|---|
| `geolocator` | `^13.x` | GPS location streaming for location sharing |

Notes:
- Replaces: GmsLocationSource (Android), CLLocationManager (iOS)
- Used with WebXDC map app for location sharing

---

## Desktop-Specific

| Package | Version | Purpose |
|---|---|---|
| `tray_manager` | `^0.2.3` | System tray icon + menu |
| `launch_at_startup` | `^0.3.1` | Register app for autostart on login |
| `window_manager` | `^0.4.3` | Window positioning, size, minimize-to-tray |
| `desktop_drop` | `^0.4.4` | Drag-and-drop files onto chat input |

Notes:
- System tray: minimize-to-tray, unread count in tray icon, quick-open from tray menu
- WebXDC in separate window: `window_manager` opens a new Flutter window

---

## Sharing & URL Handling

| Package | Version | Purpose |
|---|---|---|
| `receive_sharing_intent` | `^2.x` | Receive files/text from other apps (Android share target + iOS share extension) |
| `share_plus` | `^10.1.4` | Share files and text to other apps |
| `url_launcher` | `^6.3.1` | Open URLs in browser / mailto: / tel: links |

---

## Localization

| Package | Version | Purpose |
|---|---|---|
| `flutter_localizations` | (SDK) | Built-in localization delegates |
| `intl` | `^0.20.2` | ICU message formatting, date/number formatting |

Pipeline:
- Source strings: DeltaChat Transifex project
- Format: `.arb` files per locale
- Generation: `flutter gen-l10n` → `AppLocalizations` class
- Minimum launch: EN, DE, ES, FR, PT, RU, ZH (7 languages)
- Target: 40+ languages (full Transifex export)

---

## Serialization & Code Generation

| Package | Version | Purpose |
|---|---|---|
| `freezed_annotation` | `^2.4.4` | Immutable data model annotations |
| `freezed` | `^2.5.7` | (dev) Generate immutable model code |
| `json_annotation` | `^4.9.0` | JSON serialization annotations |
| `json_serializable` | `^6.8.0` | (dev) Generate fromJson/toJson |
| `build_runner` | `^2.4.13` | (dev) Run all code generators |

Applied to:
- All RPC response types (Account, Chat, Message, Contact, etc.)
- All provider state models
- All JSON-RPC request/response envelope types

---

## Connectivity

| Package | Version | Purpose |
|---|---|---|
| `connectivity_plus` | `^6.x` | Network change detection → `maybeNetwork` call |

Notes:
- Replaces: ReachabilitySwift (iOS), ConnectivityManager (Android)
- On network change: call `maybeNetwork(accountId)` for all active accounts

---

## Testing & Dev

| Package | Version | Purpose |
|---|---|---|
| `flutter_test` | (SDK) | Unit + widget tests |
| `integration_test` | (SDK) | Integration / end-to-end tests |
| `mockito` | `^5.4.4` | (dev) Mock objects for unit tests |
| `build_runner` | `^2.4.13` | (dev) Code generation (freezed, json_serializable, riverpod_generator) |
| `riverpod_generator` | `^2.4.3` | (dev) Riverpod provider generation |
| `custom_lint` | `^0.7.0` | (dev) Custom lint rules |
| `riverpod_lint` | `^2.3.13` | (dev) Riverpod-specific lint rules |

---

## Full pubspec.yaml dependencies block (reference)

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # State management
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.3.5

  # Navigation
  go_router: ^14.6.3

  # Chat UI
  flutter_linkify: ^6.0.0
  emoji_picker_flutter: ^3.1.3
  flutter_slidable: ^3.1.1
  badges: ^3.1.2
  timeago: ^3.7.0
  audio_waveforms: ^1.0.5
  photo_view: ^0.15.0

  # Media & files
  file_picker: ^8.3.7
  image_picker: ^1.1.2
  image_cropper: ^5.0.1
  cached_network_image: ^3.4.1
  flutter_svg: ^2.0.17
  video_player: ^2.9.3
  record: ^5.2.2
  just_audio: ^0.9.43
  audio_session: ^0.1.21
  open_file: ^3.5.10
  gal: ^2.3.0
  desktop_drop: ^0.4.4
  share_plus: ^10.1.4

  # QR
  mobile_scanner: ^6.0.0
  qr_flutter: ^4.1.0

  # Notifications & background
  firebase_core: ^3.13.0
  firebase_messaging: ^15.2.5
  flutter_local_notifications: ^18.0.1
  flutter_app_badger: ^1.5.0
  workmanager: ^0.5.2
  flutter_callkit_incoming: ^2.0.0

  # Security & storage
  flutter_secure_storage: ^9.2.4
  local_auth: ^2.3.0
  flutter_windowmanager: ^0.3.0
  permission_handler: ^11.4.0

  # WebXDC & WebView
  flutter_inappwebview: ^6.0.0

  # WebRTC
  flutter_webrtc: ^0.10.0

  # Location
  geolocator: ^13.0.0

  # Desktop
  tray_manager: ^0.2.3
  launch_at_startup: ^0.3.1
  window_manager: ^0.4.3

  # Sharing
  receive_sharing_intent: ^2.0.0
  url_launcher: ^6.3.1

  # Localization
  intl: ^0.20.2

  # Serialization
  freezed_annotation: ^2.4.4
  json_annotation: ^4.9.0

  # Connectivity
  connectivity_plus: ^6.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  build_runner: ^2.4.13
  freezed: ^2.5.7
  json_serializable: ^6.8.0
  riverpod_generator: ^2.4.3
  riverpod_lint: ^2.3.13
  custom_lint: ^0.7.0
  mockito: ^5.4.4
```

---

## Package Count Summary

| Category | Count |
|---|---|
| State management | 4 |
| Navigation | 1 |
| Chat UI | 7 |
| Media & files | 12 |
| QR | 3 |
| Notifications & background | 6 |
| Security & storage | 4 |
| WebXDC/WebView | 1 |
| WebRTC | 2 |
| Location | 1 |
| Desktop-specific | 4 |
| Sharing | 3 |
| Localization | 2 |
| Serialization | 4 |
| Connectivity | 1 |
| Dev/test | 7 |
| **Total** | **62** |
