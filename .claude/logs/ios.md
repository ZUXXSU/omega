# iOS Platform Analysis Log

## Status: Analysis Complete

**Platform:** iOS
**Analysis Date:** 2026-06-14
**Source Repository:** deltachat-ios

---

## Tech Stack (Source)

| Layer | Technology |
|-------|-----------|
| Language | Swift 5.x |
| UI Framework | UIKit (UIKit everywhere; SwiftUI only in Widget and InstantOnboardingView) |
| Dependency Manager | CocoaPods |
| Core Messaging Engine | deltachat-core-rust via C FFI / OpaquePointer (dc_context_t, dc_accounts_t) |
| Newer Core APIs | JSON-RPC bridge: dc_jsonrpc_blocking_call (dc_jsonrpc_t owned by DcAccounts) |
| Web/Mini-App Runtime | WebKit / WKWebView (sandboxed Webxdc runner) |
| WebRTC Library | WebRTC-lib 140.0.0 (CocoaPod: stasel/WebRTC) |
| VoIP Calls (UI) | CallKit (CXProvider / CXCallController / CXCallObserver) |
| VoIP Push | PushKit (PKPushRegistry, PKPushPayload) |
| Notifications | UserNotifications + UNNotificationServiceExtension (NSE) |
| Maps | CoreLocation + MapKit |
| Image Loading | SDWebImage + SDWebImageWebPCoder + SDWebImageSVGKitPlugin |
| Emoji Picker | MCEmojiPicker (CocoaPod) |
| Audio Waveform UI | SCSiriWaveformView (CocoaPod) |
| Network Reachability | ReachabilitySwift (CocoaPod) |
| Code Quality | SwiftLint + SwiftFormat |
| Home-Screen Widget | WidgetKit (iOS 17+, DcWidget target) |
| Secret Storage | Keychain Services (per-account DB encryption secrets) |
| Cross-Process Data | App Groups: group.chat.delta.ios (UserDefaults + shared container) |
| Inter-Process Signalling | DarwinNotificationCenter (main app <-> NSE coordination to prevent concurrent I/O) |
| Siri Integration | Intents framework / INStartAudioCallIntent |
| Audio Recording/Playback | AVFoundation |
| File Preview | QuickLook (QLPreviewController) |
| Reactive Bindings | Combine (used in ChatViewController) |

---

## All Screens / ViewControllers

### Tab Bar Root
- **TabBarController** - 3 tabs: QR Code | Chats | Settings

### QR Tab
- **QrPageController** - paged view controller (show own QR / scan QR)

### Chats Tab
- **ChatListViewController** - main chat list; search bar, edit/archive/delete actions, unread badge, pull-to-refresh
- **ChatViewController** - full message thread; inverted UITableView, input bar, draft area, in-thread search, context menus, Combine bindings
- **NewChatViewController** - contact picker to start a new chat
- **NewGroupController** - create new group chat (name, avatar, member selection)
- **NewContactController** - create a new contact
- **EditContactController** - edit existing contact name/avatar
- **ProfileViewController** - contact or group info: shared media, encryption info, block/unblock, verified status
- **GalleryViewController** - photo/video grid for a single chat with time section headers
- **AllMediaViewController** - aggregated gallery + files + webxdc apps across all chats
- **MapViewController** - shared location map (CoreLocation + MapKit), streaming location pins
- **EphemeralMessagesViewController** - configure per-chat self-destruct timer
- **MessageInfoViewController** - delivery status breakdown per recipient
- **FullMessageViewController** - full-text display for long messages
- **SendContactViewController** - pick a contact to send as vCard
- **BackupTransferViewController** - QR-code-based peer-to-peer backup / restore / multi-device add

### Settings Tab
- **SettingsViewController** - root settings list
- **SelfProfileViewController** - edit own display name, avatar, status
- **ChatsAndMediaViewController** - media quality, download-on-demand, wallpaper, ephemeral auto-delete global toggle
- **NotificationsViewController** - notification on/off, mute settings
- **WallpaperViewController** - chat background picker
- **AdvancedViewController** - transports, proxy, log, blocked contacts, autodel, media quality
- **HelpViewController** - WKWebView loading deltachat.org/help
- **ConnectivityViewController** - real-time I/O state, notification debug log
- **ProfileSwitchViewController** - switch between multiple DcContext accounts
- **TransportListViewController** - list of IMAP/SMTP transport accounts
- **EditTransportViewController** - add/edit transport: server, port, security, folder, force E2EE, cert check
- **SecuritySettingsViewController** - TLS/STARTTLS setting per transport
- **CertificateCheckViewController** - strict vs accept-all cert policy per transport
- **ProxySettingsViewController** - list proxies, add/enable/disable, share via QR
- **ShareProxyViewController** - display proxy as QR code
- **LogViewController** - in-app debug log viewer
- **DownloadOnDemandViewController** - threshold setting for large attachment auto-download
- **AutodelOptionsViewController** - global auto-delete timer options
- **MediaQualityViewController** - low / medium / high image quality selector
- **BlockedContactsViewController** - list of blocked contacts with unblock action

### Onboarding Flow
- **WelcomeViewController** - landing: Sign Up / Log In / Restore Backup
- **InstantOnboardingViewController** - SwiftUI-based chatmail account creation without manual IMAP/SMTP config
- **EditTransportViewController** (reused) - manual IMAP/SMTP login

### Modal / Presented Screens
- **WebxdcViewController** - sandboxed WKWebView for Webxdc mini-apps; custom URL scheme handler; JS bridge (window.webxdc)
- **ReactionsOverviewViewController** - bottom sheet listing who reacted with each emoji
- **QrPageController** (also accessible from chat for secure join)
- **PreviewController** (QuickLook QLPreviewController subclass) - full-screen file/image preview with share/save
- **ContextMenuController** - custom long-press context menu for messages (react, reply, forward, copy, info, save, edit, delete, select)
- **PartialScreenPresentationController** - bottom-sheet style UIPresentationController

### Extensions (Not ViewControllers but screens)
- **ShareViewController** (DcShare target) - share extension: receive files/text from other apps, pick a chat, send
- **NotificationService** (DcNotificationService target) - UNNotificationServiceExtension; background IMAP fetch, deliver per-message local notifications
- **DcAppClip** target - App Clip for i.delta.chat invite links before main app install
- **DcWidget** target - WidgetKit home-screen widget (recent webxdc apps + chat shortcuts)

### Call UI
- **CallViewController** - WebRTC call UI (audio/video), mute, speaker, camera toggle, end call
- **CallWindow** - separate UIWindow floating above tab bar during active call
- **PiPVideoView / PiPFrameProcessor** - picture-in-picture video overlay

---

## All Features

### Messaging Core
- Email-based encrypted chat: IMAP/SMTP transport, end-to-end encrypted via Autocrypt / OpenPGP
- Multi-account support: multiple DcContext instances managed by DcAccounts singleton, switchable at runtime
- Text messages with link, email, and phone number detection
- Image, video, GIF, sticker, and file attachments
- Voice messages with waveform visualisation (SCSiriWaveformView) and audio player
- Contact cards (vCard send/receive)
- WebXDC mini-apps embedded in chat
- Message replies (quote/reply preview)
- Message forwarding to any chat
- Message editing (remote edit request sent to recipients)
- Message deletion with remote delete request
- Ephemeral (self-destructing) messages: configurable timers from seconds to years, per-chat
- Reactions (emoji) on messages with per-contact breakdown
- Download-on-demand for large attachments (configurable threshold)
- Full-message view for truncated long messages

### Chat Types
- One-on-one chats
- Group chats: create, edit name/avatar, add/remove members, change description, leave, delete
- Verified groups: end-to-end encrypted, QR-based member join, cryptographically authenticated membership
- Broadcast lists (outgoing channel mode and incoming channel mode)
- Mailing list integration (read-only chats from mailing lists)
- Saved messages (self-talk chat)
- Device messages (system info chat)

### Chat List
- Full chat list with archived chats section
- Search across all chats
- Pull-to-refresh
- Unread badge counters per chat and on tab bar
- Swipe actions: archive, delete, mute, pin
- Multi-select edit mode: delete, archive multiple chats

### Contacts
- Create, edit, block/unblock, delete contacts
- Import/export contacts as vCard
- Edit contact display name (stored locally, overrides server name)
- Address book access (Contacts framework) for adding contacts

### Security and Encryption
- Autocrypt / OpenPGP end-to-end encryption
- Verified groups with QR-based secure join
- Key fingerprint display in profile
- Force E2EE toggle per transport account
- Certificate check policy per transport (strict / accept-all for self-signed certs)
- Keychain-encrypted SQLite database per account

### QR Code Features
- Display own QR code (openpgp4fpr: scheme) for contact setup
- Scan QR code: contact join, group join, account setup, proxy share, backup transfer
- Share proxy settings as QR code

### Backup and Multi-Device
- QR-code-based peer-to-peer backup transfer (DcBackupProvider)
- Restore from backup via QR scan
- Add second device via QR flow
- BCC-self toggle for message archive on server

### Account and Transport
- Instant onboarding: create chatmail account without manual IMAP/SMTP config
- Multiple transport accounts: IMAP/SMTP with full advanced config (server, port, security, folder, oauth2)
- Switch between accounts (ProfileSwitchViewController)
- Per-transport security settings (TLS/STARTTLS/None)
- Per-transport certificate check policy
- Connectivity status screen with real-time I/O state

### Proxy
- SOCKS5/HTTP proxy support
- Proxy list management: add, enable/disable, delete
- Share proxy configuration as QR code

### Location
- Real-time location streaming to chat: share live location with configurable duration
- MapKit map view showing all participants' shared locations with timestamps

### Notifications
- Per-message local notifications from NSE (no main app wake required)
- APNS integration (device token via dc_accounts_set_push_device_token)
- VoIP push for incoming calls (PushKit)
- Mute individual chats
- Global notification toggle
- Notification badge count management
- DarwinNotificationCenter to prevent concurrent I/O between main app and NSE
- com.apple.developer.usernotifications.filtering entitlement for silent background fetch

### Calls (WebRTC)
- Audio and video calls via WebRTC (WebRTC-lib pod)
- Native call UI via CallKit (CXProvider)
- Incoming call via VoIP push (PushKit), reported to CallKit
- Picture-in-picture video during calls
- Mute, speaker, camera toggle controls
- Siri integration: INStartAudioCallIntent
- Call history in CallKit recents

### WebXDC Mini-Apps
- Sandboxed WKWebView runner
- Custom URL scheme: webxdc://
- Content rules blocking all external URLs (strict sandboxing)
- JavaScript bridge: window.webxdc API (sendUpdate, setUpdateListener, selfAddr, selfName)
- Realtime data bus via JSON-RPC (send_webxdc_realtime_advertisement, send_webxdc_realtime_data, leave_webxdc_realtime)
- WebXDC store browser
- Recent apps picker
- App icon and name display in chat cell and grid

### Media and Files
- Gallery view: grid of all images/videos in a chat with time section headers
- All Media screen: aggregated gallery + files + webxdc across all chats
- File browser (Documents/File Sharing integration)
- QuickLook file preview
- Photo/video picking via PHPickerViewController
- SDWebImage async loading with WebP (SDWebImageWebPCoder) and SVG (SDWebImageSVGKitPlugin) support
- Media quality selector (low / medium / high) for sent images
- Audio recording and playback (AVFoundation)

### UI and Accessibility
- Dark mode support (system-wide)
- Dynamic font size support (UIFontMetrics)
- Chat background / wallpaper customisation (tiled or solid)
- Inverted UITableView for bottom-pinned chat scroll
- State restoration: remembers last active tab and chat ID across launches
- In-app debug log viewer
- Help web view (loads deltachat.org help pages)

### Onboarding and Sharing
- Welcome screen with Sign Up / Log In / Restore paths
- Instant chatmail account creation (SwiftUI form)
- Share extension (DcShare): receive files/text from other apps and forward to chat
- App Clip (DcAppClip): handle i.delta.chat invite links before main app is installed
- Invite friends via iOS share sheet
- Universal links (i.delta.chat domain)
- Custom URL schemes: openpgp4fpr:, dcaccount:, dclogin:, chat.delta.deeplink:, mailto:

### Home-Screen Widget
- WidgetKit widget (DcWidget, iOS 17+)
- Shows recent WebXDC apps and chat shortcuts
- Reads shared UserDefaults from App Group (group.chat.delta.ios)

### Miscellaneous
- Donation request via device message
- Background fetch (UIBackgroundModes fetch) coordinated with NSE
- In-app notification management

---

## Data Models

| Model | Wraps | Key Properties |
|-------|-------|----------------|
| DcAccounts | dc_accounts_t (C ptr) | Singleton; all accounts; owns JSON-RPC bridge (dc_jsonrpc_t) |
| DcContext | dc_context_t (C ptr) | Per-account; all chat/message/contact operations |
| DcMsg | dc_msg_t (C ptr) | id, chatId, fromContactId, text, viewType, file, duration, width, height, isForwarded, isEdited, isInfo, timestamp, state, quotedMessage, overrideSenderName, savedMessageId, originalMessageId |
| DcChat | dc_chat_t (C ptr) | id, name, type (single/group/mailinglist/broadcast), isArchived, isEncrypted, isMuted, isUnpromoted, isSelfTalk, isOutBroadcast, isInBroadcast, canSend, profileImage |
| DcContact | dc_contact_t (C ptr) | displayName, editedName, authName, email, status, isVerified, isKeyContact, isBot, isBlocked, lastSeen, wasSeenRecently, profileImage, color |
| DcChatlist | dc_chatlist_t (C ptr) | count, getChatId(), getSummary() |
| DcLot | dc_lot_t (C ptr) | Summary/snippet for chat list previews |
| DcReaction / DcReactions | - | emoji, count, isFromSelf, reactionsByContact |
| DcVcardContact | - | addr, displayName, key (PGP base64), profileImage (base64), color, timestamp |
| DcEnteredLoginParam | - | addr, password, imapServer/Port/Security/User/Folder, smtpServer/Port/Security/User/Password, oauth2, certificateChecks |
| DcTransportListEntry | - | isUnpublished, param (DcEnteredLoginParam) |
| DcEvent / DcEventEmitter | - | Event bus; key events listed below |
| DcBackupProvider | - | QR-code-based backup stream for multi-device transfer |
| DcProvider | - | Email provider metadata: name, overview URL, status |
| DcCall | - | contextId, chatId, uuid, direction (incoming/outgoing), hasVideoInitially, messageId, placeCallInfo, callAcceptedHere |
| DraftModel | - | Per-chat draft: text, file, quoteId, viewType |
| GalleryItem | - | messageId, type |
| WidgetEntry / Shortcut / AppShortcut / ChatShortcut | - | WidgetKit timeline entry models |
| ContactCellViewModel | - | View-layer wrapper over DcContact/DcContext for contact cell |
| ChatListViewModel | - | Observable wrapper for DcChatlist driving ChatListViewController |
| ProfileViewModel | - | View-layer wrapper for profile display |

### Key DcEvent Types
- DC_EVENT_INCOMING_MSG
- DC_EVENT_INCOMING_REACTION
- DC_EVENT_INCOMING_WEBXDC_NOTIFY
- DC_EVENT_INCOMING_CALL
- DC_EVENT_CALL_ENDED
- DC_EVENT_INCOMING_CALL_ACCEPTED
- DC_EVENT_MSGS_NOTICED
- DC_EVENT_ACCOUNTS_BACKGROUND_FETCH_DONE
- DC_EVENT_CONNECTIVITY_CHANGED
- DC_EVENT_MSGS_CHANGED

---

## Flutter Implementation Notes

### Core FFI / JSON-RPC
- deltachat-core-rust has an official Flutter/Dart binding via its JSON-RPC interface
- Use flutter_deltachat or build FFI bindings via dart:ffi + the same C shared library used by the iOS app
- All JSON-RPC methods (send_webxdc_realtime_advertisement, send_webxdc_realtime_data, leave_webxdc_realtime, set_chat_description, get_chat_description, change_contact_name, parse_vcard, make_vcard, set_webxdc_integration, init_webxdc_integration) map directly

### Notifications
- Replace UNNotificationServiceExtension with firebase_messaging or flutter_local_notifications + a background isolate
- FCM can replace APNS device token registration; dc_accounts_set_push_device_token accepts any token string
- For badge count: flutter_app_badger package
- For NSE-equivalent background fetch on iOS: background_fetch package; on Android: workmanager package

### VoIP Calls
- Replace CallKit + PushKit with flutter_callkit_incoming (wraps CXProvider on iOS, ConnectionService on Android)
- WebRTC peer connection: flutter_webrtc package
- The DcCall model maps directly; observe DC_EVENT_INCOMING_CALL and DC_EVENT_CALL_ENDED from event emitter

### WebXDC Mini-Apps
- Embed flutter_inappwebview (WKWebView on iOS, WebView on Android)
- Implement custom URL scheme handler for webxdc:// scheme
- Add JavaScript channel for window.webxdc API (sendUpdate, setUpdateListener, selfAddr, selfName)
- Replicate URL-blocking content rules via shouldOverrideUrlLoading

### Location Streaming
- Use geolocator package (wraps CLLocationManager on iOS)
- Map display: flutter_map (Leaflet-based, OSM tiles) or google_maps_flutter
- Call dc_send_locations_to_chat and dc_set_location via FFI

### Secure Storage
- flutter_secure_storage wraps iOS Keychain and Android Keystore
- Store per-account DB encryption secrets (equivalent to KeychainManager.swift)
- Use same keychain sharing group identifier for cross-reinstall persistence

### App Groups / Shared Container
- On iOS use path_provider with group container URL for shared directory
- Expose via a method channel if needed for widget or share extension communication
- Replace DarwinNotificationCenter inter-process signalling with shared UserDefaults flags (same fallback pattern already in the Swift code)

### Home-Screen Widget
- Must be implemented as a native iOS WidgetKit Swift extension alongside the Flutter app
- Flutter cannot directly render WidgetKit widgets
- Communicate data via shared UserDefaults (App Group: group.chat.delta.ios)
- Widget reads recent chats / webxdc apps from the shared UserDefaults key written by the Flutter app

### Share Extension
- Implement as native iOS share extension OR use receive_sharing_intent package (wraps NSExtension)
- Extension writes received data (files/text) to shared App Group container
- Main Flutter app picks it up on next foreground via receive_sharing_intent callbacks

### Audio Recording / Playback / Waveforms
- Recording and playback: flutter_sound or record package
- Waveform visualisation: audio_waveforms package (replaces SCSiriWaveformView)

### Image Loading / Caching
- cached_network_image or extended_image for async loading
- WebP: built-in on Android Flutter; on iOS handled by flutter_image_compress or native coders
- SVG: flutter_svg package

### QR Code
- Scanning: mobile_scanner or qr_code_scanner package
- Display/generation: qr_flutter package

### State Management (Multi-Account)
- Model DcAccounts as a top-level provider/bloc
- Recommended: riverpod or bloc for state management across account switches
- DcContext per account exposed as a scoped provider

### Navigation
- go_router with ShellRoute for the 3-tab bottom navigation (QR / Chats / Settings) mirrors AppCoordinator
- Named routes for deep links (openpgp4fpr:, dcaccount:, dclogin:, chat.delta.deeplink:, mailto:, i.delta.chat) handled in GoRouter redirect / onDeepLink

### Chat List / Chat View
- Inverted chat list: Flutter ListView.builder with reverse: true natively replicates the inverted UITableView trick
- Ephemeral timers, reactions, message editing/deletion: all handled by deltachat-core; UI observes DC_EVENT_MSGS_CHANGED and DC_EVENT_INCOMING_REACTION

### Context Menu on Messages
- Use flutter_context_menu or GestureDetector + Overlay
- Replicate 9-action menu: react, reply, forward, copy, info, save, edit, delete, select

### Proxy Settings
- deltachat-core supports proxy natively via dc_set_config('proxy_url')
- Flutter UI calls this via FFI/JSON-RPC; no platform-level proxy API needed

### Emoji Picker
- emoji_picker_flutter package (replaces MCEmojiPicker)

### Reactive / Combine Equivalent
- Dart streams (StreamController / StreamBuilder) replace Combine publishers used in ChatViewController

---

## Key Files to Reference

| File | Purpose |
|------|---------|
| /Volumes/KRYPTIX/test2/sources/deltachat-ios/deltachat-ios/AppDelegate.swift | App lifecycle, push registration, background fetch, account setup |
| /Volumes/KRYPTIX/test2/sources/deltachat-ios/deltachat-ios/Coordinator/AppCoordinator.swift | Deep link routing, QR handling, universal links, notification taps, account+chat navigation |
| /Volumes/KRYPTIX/test2/sources/deltachat-ios/deltachat-ios/DC/DcContext.swift | Per-account context; all C FFI calls for chat/message/contact operations |
| /Volumes/KRYPTIX/test2/sources/deltachat-ios/deltachat-ios/DC/DcAccounts.swift (as DcAccount.swift) | Singleton accounts manager; JSON-RPC bridge ownership |
| /Volumes/KRYPTIX/test2/sources/deltachat-ios/deltachat-ios/DC/DcMsg.swift | Message model; all message properties and C FFI wrappers |
| /Volumes/KRYPTIX/test2/sources/deltachat-ios/deltachat-ios/DC/DcChat.swift | Chat model; type detection, flags, C FFI wrappers |
| /Volumes/KRYPTIX/test2/sources/deltachat-ios/deltachat-ios/DC/DcContact.swift | Contact model; display name, verification, block status |
| /Volumes/KRYPTIX/test2/sources/deltachat-ios/deltachat-ios/DC/DcReaction.swift | Reaction data model |
| /Volumes/KRYPTIX/test2/sources/deltachat-ios/deltachat-ios/DC/DcVcard.swift | vCard contact model |
| /Volumes/KRYPTIX/test2/sources/deltachat-ios/deltachat-ios/DC/DcEnteredLoginParam.swift | Login credentials model for transport setup |
| /Volumes/KRYPTIX/test2/sources/deltachat-ios/deltachat-ios/DC/DcTransportListEntry.swift | Transport account list entry |
| /Volumes/KRYPTIX/test2/sources/deltachat-ios/deltachat-ios/Chat/ChatViewController.swift | Full chat thread view; Combine bindings, inverted table, input bar, context menu |
| /Volumes/KRYPTIX/test2/sources/deltachat-ios/deltachat-ios/Controller/ChatListViewController.swift | Chat list; search, edit mode, badges, archive |
| /Volumes/KRYPTIX/test2/sources/deltachat-ios/deltachat-ios/Controller/WebxdcViewController.swift | WebXDC mini-app runner; WKWebView sandbox, JS bridge, realtime bus |
| /Volumes/KRYPTIX/test2/sources/deltachat-ios/deltachat-ios/Calls/CallManager.swift | WebRTC call management; RTCPeerConnection lifecycle |
| /Volumes/KRYPTIX/test2/sources/deltachat-ios/deltachat-ios/Calls/VoIPPushManager.swift | PushKit VoIP push handling; routes to CallKit |
| /Volumes/KRYPTIX/test2/sources/deltachat-ios/deltachat-ios/Calls/CallViewController.swift | Call UI; mute/speaker/camera controls, PiP video |
| /Volumes/KRYPTIX/test2/sources/deltachat-ios/DcNotificationService/NotificationService.swift | NSE; background IMAP fetch, local notification delivery without main app wake |
| /Volumes/KRYPTIX/test2/sources/deltachat-ios/deltachat-ios/Helper/LocationManager.swift | CoreLocation streaming; dc_send_locations_to_chat integration |
| /Volumes/KRYPTIX/test2/sources/deltachat-ios/deltachat-ios/Helper/NotificationManager.swift | Notification scheduling, badge management, mute logic |
| /Volumes/KRYPTIX/test2/sources/deltachat-ios/DcCore/DcCore/Helper/KeychainManager.swift | Keychain read/write for per-account DB secrets; sharing group config |
| /Volumes/KRYPTIX/test2/sources/deltachat-ios/DcCore/DcCore/Helper/DarwinNotificationCenter.swift | Inter-process signalling between main app and NSE |
| /Volumes/KRYPTIX/test2/sources/deltachat-ios/DcCore/DcCore/DC/events.swift | DcEvent constants and DcEventEmitter wrapper |
| /Volumes/KRYPTIX/test2/sources/deltachat-ios/DcWidget/WidgetProvider.swift | WidgetKit timeline provider; reads App Group UserDefaults |
| /Volumes/KRYPTIX/test2/sources/deltachat-ios/DcShare/Controller/ShareViewController.swift | Share extension entry point; picks chat and sends received content |
| /Volumes/KRYPTIX/test2/sources/deltachat-ios/deltachat-ios/Controller/ProfileSetup/WelcomeViewController.swift | Onboarding landing screen |
| /Volumes/KRYPTIX/test2/sources/deltachat-ios/deltachat-ios/Controller/ProfileSetup/InstantOnboardingViewController.swift | SwiftUI chatmail account creation flow |
| /Volumes/KRYPTIX/test2/sources/deltachat-ios/deltachat-ios/Controller/BackupTransferViewController.swift | QR-based backup/restore/multi-device add flow |
| /Volumes/KRYPTIX/test2/sources/deltachat-ios/deltachat-ios/Controller/Settings/Transports/EditTransportViewController.swift | IMAP/SMTP transport add/edit; force E2EE, cert check, advanced config |
| /Volumes/KRYPTIX/test2/sources/deltachat-ios/deltachat-ios/Controller/Settings/Proxy/ProxySettingsViewController.swift | Proxy list management; add, enable, share as QR |
| /Volumes/KRYPTIX/test2/sources/deltachat-ios/deltachat-ios/Controller/MapViewController.swift | Location streaming map; MapKit pins, duration controls |
| /Volumes/KRYPTIX/test2/sources/deltachat-ios/Podfile | All CocoaPods dependencies and versions |

---

## Next Steps

1. **FFI Layer First** - Set up dart:ffi bindings to deltachat-core-rust shared library (.so / .dylib). Validate JSON-RPC bridge (dc_jsonrpc_blocking_call) works from Dart before building any UI. All messaging logic depends on this.

2. **Event Bus** - Implement a Dart StreamController wrapping DcEventEmitter polling. Every UI component depends on observing DC_EVENT_* events; this is the reactive backbone replacing Combine.

3. **Multi-Account State** - Model DcAccounts and per-account DcContext as riverpod/bloc providers early. Account switching must work before building chat screens.

4. **Navigation Shell** - Implement go_router ShellRoute with 3 tabs (QR / Chats / Settings). Wire deep link handlers for all custom URL schemes and universal links before building individual screens.

5. **Chat List Screen** - ChatListViewController equivalent using ChatListViewModel pattern. Implement unread badge, search, archive, multi-select. This is the most-used screen.

6. **Chat View Screen** - ChatViewController equivalent with reverse: true ListView, message cells (text, image, video, audio, file, webxdc, contact card, info/system), input bar, reply/draft area, context menu. Largest single component.

7. **Message Cell Types** - Implement all cell variants: TextMessageCell, ImageTextCell, AudioMessageCell, FileTextCell, WebxdcCell, ContactCardCell, InfoMessageCell. Each maps to a DcMsg viewType.

8. **Notifications** - Implement background_fetch (iOS) + workmanager (Android) for NSE-equivalent. Set up firebase_messaging for APNS token registration. Wire DarwinNotificationCenter equivalent via shared UserDefaults flags.

9. **Calls** - Integrate flutter_webrtc + flutter_callkit_incoming. Implement VoIP push handling. Wire DC_EVENT_INCOMING_CALL and DC_EVENT_CALL_ENDED to CallKit actions.

10. **WebXDC Runner** - Set up flutter_inappwebview sandbox with webxdc:// URL scheme, JavaScript channel, and URL-blocking rules. This is complex but self-contained.

11. **Secure Storage** - Integrate flutter_secure_storage for per-account DB encryption secrets before any account creation flow. Required for Keychain parity.

12. **Onboarding** - WelcomeViewController + InstantOnboardingViewController equivalents. Instant chatmail flow is the primary new-user path; must work early.

13. **Share Extension** - receive_sharing_intent or native iOS extension writing to App Group container. Lower priority but needed for sharing from other apps.

14. **Home-Screen Widget** - Native Swift WidgetKit extension reading from shared UserDefaults. Implement last; depends on App Group data being written correctly by main app.

15. **QR Features** - mobile_scanner for scanning; qr_flutter for display. Wire to all QR flows: contact add, group join, proxy share, backup transfer, account setup.

16. **Location Streaming** - geolocator + flutter_map. Wire dc_send_locations_to_chat via FFI. MapViewController equivalent for viewing shared locations.

17. **Enterprise / Proxy** - Proxy settings UI calling dc_set_config('proxy_url') via FFI/JSON-RPC. Simple UI; core handles the rest.

18. **Polishing** - Dark mode (Flutter ThemeData), dynamic font size (TextScaler), wallpaper/background, state restoration (SharedPreferences), in-app log viewer, connectivity screen.
