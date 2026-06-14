# Desktop Platform Analysis Log

## Status: Analysis Complete

**Date:** 2026-06-14
**Platform Analyzed:** Flutter Desktop (Windows/macOS/Linux target, with Web support)
**Source Codebase:** deltachat-desktop (React 19 + TypeScript + Electron/Tauri/Browser)
**Purpose:** Reference document for Flutter reimplementation agent

---

## Tech Stack (Source)

### Current Source Stack
- **Framework:** React 19 + TypeScript
- **Primary Desktop Target:** Electron
- **Secondary Desktop Target:** Tauri
- **Web/Browser Target:** Supported
- **Monorepo Tool:** pnpm with packages:
  - `frontend` — React UI layer
  - `runtime` — abstraction layer over Electron/Tauri/Browser runtimes
  - `shared` — shared TypeScript types
  - `target-electron` — Electron main process, IPC, native bridges
  - `target-tauri` — Tauri-specific integration
  - `target-browser` — Browser target shims
- **Styling:** SCSS modules
- **Core Messaging:** `@deltachat/jsonrpc-client` — DeltaChat core RPC client
- **Virtualized Lists:** `react-window` + `react-virtualized-auto-sizer`
- **Emoji Picker:** `emoji-mart-awesome`
- **Date Formatting:** `moment.js`
- **Link Detection:** `linkifyjs`
- **QR Scanning:** `jsqr` (camera-based)
- **Audio Encoding:** `lamejs` (MP3 voice messages)

### Flutter Target Stack (Planned)
- **Framework:** Flutter (stable channel)
- **State Management:** `flutter_bloc` or `Riverpod`
- **Core Binding:** `deltachat_ffi` (dart:ffi) or JSON-RPC via subprocess stdin/stdout
- **Local State/Cache:** `drift` (SQLite ORM for Dart)
- **Notifications:** `flutter_local_notifications`

---

## All Screens/Views

### Top-Level Screens (ScreenController enum: `Screens`)
| Screen Name | Purpose | Flutter Mapping |
|---|---|---|
| `Loading` | Splash/init screen while accounts load | `FutureBuilder` splash route |
| `Welcome` | Onboarding entry point (no configured accounts) | Named route `/welcome` |
| `Login` | Account setup/configuration screen | Named route `/login` |
| `Main` | Primary app screen (chat list + message view) | Shell route with NavigationRail |
| `DeleteAccount` | Account deletion confirmation flow | Dialog or dedicated route |
| `NoAccountSelected` | Fallback when no account is active | Empty state widget in shell |

### Main Screen Layout
- **Two-pane layout (>= 720px wide):** Chat list (left column) + Message view (right column) rendered simultaneously
- **Single-pane layout (< 720px):** Chat list OR message view, with back button navigation between them
- **Account sidebar:** Always visible on the left of the chat list as a vertical strip of account avatars
- **Chat selection:** In-memory state via `ChatContext`, not URL-based routing

### Welcome/Onboarding Sub-Flow
- `WelcomeScreen` -> `OnboardingScreen`
  - Path A: `InstantOnboardingScreen` — one-tap chatmail account creation
  - Path B: `AlternativeSetupsDialog` — manual login / backup import / second-device
    - `LoginForm` — manual IMAP/SMTP entry with advanced server options
    - Backup import flow — file picker + progress
    - Receive-from-second-device flow — QR scan or local network

### Dialogs / Modals (stacked via `DialogContext`)
All of these are modal overlays, not separate routes. Multiple can be open simultaneously.

| Dialog | Purpose |
|---|---|
| `Settings` | Multi-section settings modal with internal navigation |
| `ViewProfile` | Contact info, shared chats, block/unblock actions |
| `ViewGroup` | Group info, members list, QR invite, edit options |
| `CreateChat` | New chat flow: contact list + create group/broadcast |
| `ForwardMessage` | Chat picker to forward a message |
| `SelectContact` | Contact list with search (generic picker) |
| `AddMember` | Multi-select contact list for group membership |
| `QrCode` | Display QR code (contact share, group invite, account) |
| `QrScanner` | Camera-based QR code scanner |
| `MediaView` | Full-screen media browser (Gallery) |
| `Gallery` | Per-chat or global media tabs: Apps/Images/Video/Audio/Files |
| `FullscreenMedia` | Zoom/pan viewer for single image or video |
| `ReactionsDialog` | Full list of who reacted with which emoji |
| `DisappearingMessages` | Timer picker for ephemeral messages per chat |
| `MuteChat` | Duration picker for muting a chat |
| `ProxyConfiguration` | List/add/edit/delete SOCKS5 or HTTP proxies |
| `TransportsDialog` | IMAP/SMTP transport management per account |
| `SetupMultiDevice` | Send/receive backup via QR for multi-device |
| `ChatContextMenu` | Positioned popup: pin/archive/mute/clear/delete/search/block |
| `MessageContextMenu` | Positioned popup: reply/forward/copy/info/download/edit/delete |
| `EmojiAndStickerPicker` | Emoji grid + sticker pack tabs popover |
| `ImageCropper` | Circle/square crop for avatar selection |
| `About` | Version info, build info, open-source credits |
| `KeybindingCheatSheet` | All keyboard shortcuts popup |
| `ConnectivityToast` | Floating toast: connected/connecting/offline |
| `ConnectivityDialog` | Full connectivity details dialog |
| `LogViewer` | In-app log file viewer |
| `SmallSelectDialog` | Generic single-option picker |
| `AccountHoverInfo` | Tooltip popup on account avatar hover |
| `ShortcutMenu` | Mini floating quick-reaction emoji row |
| `EncryptionInfo` | E2E encryption info per contact or group |
| `ProtectionStatusDialog` | Chat protection status explanation |
| `HtmlEmailView` | HTML email viewer (dedicated window or system browser) |

### Settings Internal Navigation
`Settings` modal has five sections (internal Navigator.push within modal):
1. **Main** — Profile (avatar, name, email, bio), account actions
2. **Chats and Media** — enter-key-sends, media quality, download limits, read receipts, auto-delete, WebXDC dev tools
3. **Notifications** — enable/disable, show content, mention-only, in-chat sounds, volume
4. **Appearance** — theme (light/dark/system/custom), chat background, font, zoom
5. **Advanced** — encryption, BCC self, sync all accounts, proxy, transports, experimental features, log viewer, about

---

## All Features

### Account Management
- Add multiple DeltaChat accounts (chatmail, IMAP/SMTP, backup import, second-device)
- Remove account (with confirmation)
- Switch between accounts via vertical account sidebar
- Account avatar with unread badge in sidebar
- Drag-to-reorder accounts in sidebar
- Sync all accounts simultaneously in background (toggle)
- Per-account mute toggle

### Onboarding
- **Instant onboarding:** One-tap chatmail account creation (no email knowledge required), server list fetched via HTTP, auto-configures IMAP/SMTP
- **Manual IMAP/SMTP:** Full login form with server, port, TLS mode, certificate validation options, provider info hints
- **Advanced server settings:** Separate IMAP and SMTP host/port/user/password/security/certificate fields
- **Backup import:** File picker for `.tar` backup file, progress monitoring
- **Receive from second device:** QR-code-based or local-network-based backup receive
- **QR account provisioning:** Scan QR to add pre-configured account (chatmail profile QR)

### Chat List
- Virtualized scrollable list of all chats (react-window `FixedSizeList`)
- Chat preview per row: avatar, name, last message text/type label, timestamp, unread badge, muted icon, pin icon, contact-request badge
- Search across chats, contacts, and messages simultaneously
- Archive view (separate scrollable archive section at bottom or toggle)
- Pinned chats shown at top of list
- Unread badge counts per chat
- Typing indicators in chat preview
- Contact request badge on incoming contact request chats
- Group/broadcast/mailing-list visual differentiation

### Chat View / Message Thread
- Full message thread with infinite scroll (load older messages on top-scroll)
- Virtualized reverse-scroll rendering
- Date group separators between messages from different days
- Jump-to-message (scroll to specific message by ID)
- Search within chat (highlights matching messages)
- Message grouping: consecutive messages from same sender grouped visually

### Message Composition (Composer)
- Multi-line auto-expanding text input
- Enter-key-sends toggle (Enter sends vs. Shift+Enter for newline)
- Reply-to-quote: shows quoted message above input, dismissible
- File attachments: image, video, audio, generic file — via file picker or drag-and-drop
- Emoji picker (emoji-mart grid)
- Sticker picker (local sticker packs from filesystem, per-sticker delete)
- Voice message recording: tap to start/stop, waveform display, timer, saved as MP3
- Paste from clipboard (text + image)
- Drag-and-drop files into composer
- WebXDC app attachment (from app store or local file)
- vCard contact attachment
- App picker (WebXDC app store integration)
- Draft auto-save per chat
- Editing mode: press Up arrow when input empty, or context menu "Edit" — shows "Editing" label above input with original text pre-filled

### Message Types
| Type | Description |
|---|---|
| `Text` | Plain text with linkify, bold/italic markdown |
| `Image` | Inline image thumbnail, tap to fullscreen |
| `Video` | Inline video thumbnail, inline player or fullscreen |
| `Audio` | Inline audio player with progress/speed |
| `Voice` | Voice message: inline player, GlobalVoiceMessagePlayer |
| `File` | File attachment with filename/size, tap to open/download |
| `Sticker` | Sticker image displayed without bubble |
| `GIF` | Animated GIF displayed inline |
| `Webxdc` | Mini-app tile with icon/name/summary, tap to open in window |
| `Vcard` | Contact card with avatar/name, tap to view profile or add contact |
| `VideochatInvitation` | Join call button |
| `WebxdcInfoMessage` | System message from WebXDC app |
| System messages | Group member add/remove, protection status, encryption info, etc. |

### Message Reactions
- Emoji reaction bar below message bubble (`ReactionsBar`)
- Tap a reaction to add/remove your own reaction
- Reactions summary dialog shows who reacted with which emoji (`ReactionsDialog`)
- Send reaction via message context menu
- Reactions sync from core via `MsgsChanged` events

### Message Context Menu
Right-click or long-press on a message:
- Reply (quotes message in composer)
- Forward (opens `ForwardMessage` dialog)
- Copy text
- Copy link (if message contains link)
- Copy image (to clipboard)
- Info/Details (message timestamp, delivery status, sender info)
- Download (save attachment to disk)
- Save to Saved Messages (self-talk)
- Edit (own messages only: switches composer to editing mode)
- Delete for me only
- Delete for everyone (own messages, if supported)
- Private reply (in groups: opens 1:1 chat with that member)
- React (opens emoji reaction picker)

### Message Multiselect
- Long-press or checkbox to enter multiselect mode
- Select multiple messages across the thread
- Bulk actions: Forward selected, Delete selected
- Selection toolbar replaces composer while active
- Deselect all / exit multiselect button

### Message Status Indicators
| Status | Icon |
|---|---|
| Sending | Clock/pending icon |
| Sent | Single checkmark |
| Delivered | Double checkmark |
| Read (MDN) | Double checkmark (filled/blue) |
| Failed | Error/exclamation icon |

### Forwarding
- "Forward" context menu action on any message
- Opens `ForwardMessage` dialog: chat list with search
- Select target chat(s), message is forwarded with "Forwarded" label

### Group Chats
- Create encrypted or unencrypted group
- Set group name and avatar on creation
- Add/remove members
- Leave group
- Clone group (create copy with same members)
- Show QR code to invite new members (securejoin)
- Edit group name and avatar after creation
- View all group members with role indicators
- Who-can-send permissions (all members or admins only)
- Group protection status (E2E encryption status dialog)

### Broadcast Channels
- Create `OutBroadcast`: you send to all subscribers, they cannot reply to group (one-to-many)
- Subscribe to `InBroadcast` channel
- Leave channel
- View channel info

### Mailing Lists
- Read-only view of mailing list messages
- Subscribe/unsubscribe link display

### Contact Management
- View contact profile (`ViewProfile` dialog)
- See shared chats with contact
- Send message (create or open 1:1 chat)
- Block/unblock contact
- E2E encryption info dialog (`getContactEncryptionInfo`)
- Last-seen timestamp display
- Status/bio text display
- Verified badge (if contact is verified via securejoin)
- `isBot` indicator

### Contact Requests
- Incoming contact requests shown with special badge in chat list
- Accept or block/delete contact request via banner inside chat view
- Blocked contacts cannot send new requests

### Disappearing/Ephemeral Messages
- Per-chat timer: off, 1 min, 5 min, 30 min, 1 hr, 1 day, 1 week, 4 weeks
- Timer icon shown in chat header when active
- Set via `DisappearingMessages` dialog or chat context menu
- Core handles actual deletion after timer

### Chat Actions (Chat Context Menu / Chat Header)
- Pin / Unpin chat
- Archive / Unarchive
- Mute: 1 hr / 8 hr / 1 day / 7 days / forever
- Clear chat (delete all messages locally)
- Delete chat
- Search in chat
- Block contact (for 1:1 chats)
- Mark as read / unread
- Disappearing messages timer

### Voice/Audio Calls
- Outgoing video call or audio-only call in encrypted 1:1 chats (Electron only)
- Incoming call window with WebRTC offer/answer negotiation
- Signaling via DeltaChat core call messages (`VideochatInvitation` message type)
- Uses WebRTC for actual media transport

### Gallery / Media Browser
- Per-chat or global media browser
- Tabs: Apps (WebXDC), Images/GIF, Video, Audio, Files
- Grid layout for images/GIF, list layout for audio/files
- Fullscreen viewer with zoom/pan (`InteractiveViewer` equivalent)
- Previous/next navigation between media items in fullscreen

### WebXDC Apps
- Open WebXDC mini-apps in their own window or iframe (Electron: BrowserWindow)
- App store integration: browse and download apps via `getHttpResponse` through core
- Realtime data sync between app instances (`WebxdcRealtimeData` events)
- `sendUpdate` / `setUpdateListener` JS bridge
- Location map app (experimental, uses location streaming)
- WebXDC dev tools toggle (enables Chromium DevTools for WebXDC windows)

### QR Codes
- Scan QR: join contact (securejoin), join group, join channel, add account (chatmail provisioning), verify contact
- Show QR: share own contact, share group invite
- Camera-based QR scanner (jsqr library)
- QR URLs: `OPENPGP4FPR:`, `DCACCOUNT:`, `DCLOGIN:`, `mailto:`, group join URLs

### Backup
- Export backup to `.tar` file (file save dialog, core `exportBackup`)
- Import backup from `.tar` file (file open dialog, core `importBackup`)
- Multi-device setup via QR backup transfer:
  - Sender: shows QR with local network address of backup server
  - Receiver: scans QR, downloads and imports backup over local network
  - Progress monitored via `ProgressBar` and `ImexFileWritten` core events

### Notifications
- OS-level notifications for new messages (`DcNotification`)
- Per-account mute toggle
- Per-chat mute with duration
- Show/hide notification content setting (privacy mode)
- Badge counter on app icon
- In-chat sounds with volume control slider
- Mention-only notifications mode
- Notification grouping by account

### Location Streaming
- On-demand location sharing via WebXDC map app (experimental, behind feature toggle)
- `enableOnDemandLocationStreaming` desktop setting

### Connectivity Monitoring
- `ConnectivityToast`: floating bottom toast showing connected/connecting/offline state
- `ConnectivityDialog`: full details on IMAP/SMTP connection state
- Updates from `ConnectivityChanged` core events
- "Retry now" button calls `maybeNetwork()`

### Proxy Settings
- SOCKS5 and HTTP proxy configuration per account
- `ProxyConfiguration` dialog: list, add, edit, delete proxies
- Proxy URL stored in core account config

### Transport / Server Management
- `TransportsDialog`: list multiple IMAP/SMTP transports per account
- Set default transport for outgoing messages
- Delete transport
- Scan transport QR to add transport
- `listTransportsEx` and `setDefaultTransport` core methods

### Encryption
- E2E encryption info dialog per contact (`getContactEncryptionInfo`)
- E2E encryption info per group (`getChatEncryptionInfo`)
- Protection status dialog (shows whether group has full E2E protection)
- Verified contact icons (green checkmark)
- `force_encryption` core setting: enforce E2E on all outgoing (throws error on non-E2E chats)

### HTML Email View
- View HTML emails in dedicated Electron window or system browser
- Controls for remote content loading (ask / always load / never load)
- Settings: `HTMLEmailAskForRemoteLoadingConfirmation`, `HTMLEmailAlwaysLoadRemoteContent`

### Saved Messages (Self-Talk)
- Dedicated chat with self (`isSelfTalk = true`)
- "Save to Saved Messages" action on any message
- Accessible as a normal chat in list

### Private Replies
- In group messages, "Reply privately" opens a 1:1 chat with that group member
- Quote of the original group message is pre-filled

### Auto-Delete
- Delete device messages after configurable time: off, 1 hr, 1 day, 1 week, 4 weeks, 1 year
- Separate settings for sent and received messages
- `delete_device_after` core config key

### Download on Demand
- Max auto-download size: off, 40 KB, 160 KB, 640 KB, 2.5 MB, 10 MB, no limit
- `download_limit` core config key
- Messages above threshold show "Download" button instead of inline content

### Outgoing Media Quality
- Standard or Worse (smaller file size) mode
- `media_quality` core config key

### Read Receipts (MDN)
- Toggle on/off globally
- `mdns_enabled` core config key

### BCC Self / Multi-Device Sync
- `bcc_self` toggle: copies all sent messages to self for multi-device sync

### System Tray (Desktop)
- Minimize to system tray on window close
- Tray icon with unread count badge
- Re-open app from tray
- `minimizeToTray` desktop setting

### Autostart
- Launch on system startup (Electron and Tauri)
- `autostart` desktop setting

### Content / Screen Protection
- Prevent OS-level screenshots and screen recording
- `contentProtectionEnabled` desktop setting
- Maps to platform-specific API calls

### Theme System
- Themes: light, dark, system (follows OS), custom (CSS-based)
- Custom chat background: preset images, custom image file, solid color
- `activeTheme` and `chatViewBgImg` desktop settings
- `useSystemUIFont` toggle

### Localization
- 40+ languages
- RTL (right-to-left) layout support
- System locale auto-detection
- `locale` desktop setting

### Keyboard Shortcuts (Desktop)
- `Ctrl+N` — new chat
- `Ctrl+F` — search
- `Ctrl+,` — open settings
- `Alt+Up/Down` — navigate between chats
- `Escape` — close dialog / clear search
- `Up arrow` (empty composer) — edit last sent message
- `Enter` — send message (if enter-key-sends enabled)
- `Shift+Enter` — newline (if enter-key-sends enabled)
- Full cheat sheet accessible via keybinding popup dialog

### Log Viewer
- In-app log viewer dialog showing current log file contents
- `log-debug` and `log-to-console` RC_Config flags

### Device Messages
- System-generated info messages in device chat (e.g., changelogs, tips)
- `isDeviceChat = true` flag on the device chat

### Stickers
- Local sticker packs loaded from filesystem path
- Sticker picker with pack tabs
- Per-sticker delete action

### About Dialog
- App version, build info
- Runtime versions (Electron, Chrome, Node, etc.)
- Open-source library credits
- Links (website, source, etc.)

---

## Data Models

### Account
```
id: int
kind: 'Configured' | 'Unconfigured'
configured_addr: string          // email address
displayname: string
selfstatus: string               // bio/status text
profile_image: string | null     // file path
```

### FullChat
```
id: int
name: string
color: string                    // hex color derived from contact
profileImage: string | null
chatType: 'Single' | 'Group' | 'Mailinglist' | 'InBroadcast' | 'OutBroadcast'
contactIds: int[]
freshMessageCounter: int         // unread count
isPinned: bool
isArchived: bool
isMuted: bool
ephemeralTimer: int              // seconds, 0 = off
isEncrypted: bool
canSend: bool
selfInGroup: bool
isContactRequest: bool
isSelfTalk: bool
isDeviceChat: bool
wasSeenRecently: bool
lastUpdatedTimestamp: int        // unix timestamp
mailingListAddress: string | null
```

### ChatListItemFetchResult
Reduced version of FullChat for list rendering performance — avoids fetching all fields for every row.

### Message
```
id: int
chatId: int
fromId: int                      // contact ID of sender
text: string | null
viewType: Viewtype               // enum (see below)
file: string | null              // file path for attachments
fileName: string | null
fileBytes: int | null
dimensionsWidth: int | null
dimensionsHeight: int | null
timestamp: int                   // unix timestamp
isForwarded: bool
quote: MessageQuote | null
reactions: { [emoji: string]: int[] } | null   // emoji -> array of contact IDs
isEdited: bool
savedMessageId: int | null
originalMsgId: int | null        // for forwarded/edited tracking
vcardContact: Contact | null
systemMessageType: string | null
webxdcHref: string | null
parentId: int | null
sender: Contact                  // denormalized sender contact
```

### Viewtype Enum
```
Text | Image | Video | Gif | Audio | Voice | File | Sticker | Webxdc | Vcard |
VideochatInvitation | WebxdcInfoMessage
```

### Contact
```
id: int
displayName: string
authName: string                 // name from email headers
address: string                  // email address
color: string                    // hex
profileImage: string | null
isVerified: bool
isBot: bool
lastSeen: int                    // unix timestamp
status: string                   // bio text
```

### MessageQuote
```
kind: 'WithMessage' | 'WithoutMessage'
messageId: int | null
chatId: int | null
authorDisplayName: string
authorDisplayColor: string
text: string | null
image: string | null
viewType: Viewtype | null
isForwarded: bool
overrideSenderName: string | null
```

### DraftObject
```
text: string | null
file: string | null
fileName: string | null
viewType: Viewtype | null
quote: MessageQuote | null
vcardContact: Contact | null
```

### SettingsStoreState
```
accountId: int
selfContact: Contact
settings: {
  configured_addr: string
  displayname: string
  selfstatus: string
  mdns_enabled: bool              // read receipts
  bcc_self: bool
  delete_device_after: int        // seconds
  download_limit: int             // bytes
  force_encryption: bool
  media_quality: 'Standard' | 'Worse'
  is_chatmail: bool
  who_can_call_me: WhoCanCallMe
  ui.mentions_enabled: bool
}
desktopSettings: DesktopSettingsType
rc: RC_Config
```

### DesktopSettingsType
```
bounds: WindowBounds
chatViewBgImg: string | null
lastAccount: int | null
enableOnDemandLocationStreaming: bool
enterKeySends: bool
locale: string | null
notifications: bool
showNotificationContent: bool
inChatSoundsVolume: number        // 0.0 - 1.0
activeTheme: string
minimizeToTray: bool
syncAllAccounts: bool
enableWebxdcDevTools: bool
HTMLEmailAskForRemoteLoadingConfirmation: bool
HTMLEmailAlwaysLoadRemoteContent: bool
galleryImageKeepAspectRatio: bool
useSystemUIFont: bool
contentProtectionEnabled: bool
autostart: bool
```

### TransportListEntry
```
param.addr: string               // email address for this transport
param.type: string               // 'imap' | 'smtp'
isDefault: bool
```

### WebxdcMessageInfo
```
name: string
document: string | null
summary: string | null
icon: string                     // data URI or path
sendUpdateInterval: int
sendUpdateMaxSize: int
selfAddr: string
// additional app manifest fields
```

### DcNotification
```
title: string
body: string
icon: string | null
chatId: int
messageId: int
accountId: int
notificationType: string
```

### Theme
```
name: string
description: string
address: string                  // path to CSS theme file
is_prototype: bool
```

### WhoCanCallMe Enum
```
Everybody = '0'
Contacts = '1'
Nobody = '2'
```

### RC_Config (Runtime Config)
```
log-debug: bool
log-to-console: bool
machine-readable-stacktrace: bool
theme: string | null
theme-watch: bool
devmode: bool
translation-watch: bool
minimized: bool
allow-unsafe-core-replacement: bool
```

---

## Flutter Implementation Notes

### Core Binding Strategy
- **Option A (Recommended):** Spawn `deltachat-rpc-server` as a subprocess, communicate via `stdin`/`stdout` JSON-RPC using Dart isolates. Use `dart:isolate` + `Stream` for event handling.
- **Option B:** Use deltachat-core Rust library via `flutter_rust_bridge` or `dart:ffi` for tighter integration (no subprocess overhead, better performance, but more complex setup).
- Events from core (e.g., `IncomingMsg`, `MsgsChanged`) should be delivered as a `Stream<DcEvent>` consumed by BLoC/Riverpod providers.

### State Management Architecture
Use `Riverpod` (preferred) or `flutter_bloc`:
- `AccountStoreProvider`: selected account ID, list of all accounts
- `ChatStoreProvider`: selected chat ID, chat list IDs per account
- `SettingsStoreProvider`: core settings + desktop settings, scoped to selected account
- `MessageListProvider(chatId)`: paginated message IDs + message cache for a specific chat
- `ContactProvider(contactId)`: contact details cache
- `DraftProvider(chatId)`: draft text/file/quote per chat

### Virtualized Chat List
- Use `ListView.builder` with `itemCount` from `getChatListIds` result
- Wrap each `ChatListItem` in `RepaintBoundary` to limit repaint scope
- Use `ValueListenableBuilder` or `ref.watch` on per-chat unread counts for badge updates without full list rebuild

### Virtualized Message List
- Use `CustomScrollView` with `SliverList` in reverse order (`reverse: true`)
- Implement top-scroll-to-load-older-messages with `ScrollController.addListener` checking `position.pixels >= position.maxScrollExtent - threshold`
- Alternative: use `flutter_chat_ui` as base (handles virtualization, grouping, date separators)
- Group messages by date separator (compare `DateTime` from timestamp)
- Group consecutive messages from same sender (no avatar repeat)

### Responsive Layout
```dart
LayoutBuilder(builder: (context, constraints) {
  if (constraints.maxWidth >= 720) {
    return Row(children: [AccountSidebar(), ChatListPane(), MessageViewPane()]);
  } else {
    return currentChat == null
      ? Row(children: [AccountSidebar(), ChatListPane()])
      : MessageViewPane();
  }
})
```
- Account sidebar: `NavigationRail` with account avatar buttons, or custom `Column` with `GestureDetector` for drag-to-reorder

### Composer Implementation
```
Scaffold bottomNavigationBar:
  Column([
    QuotePreviewWidget (if replying),
    EditingPreviewWidget (if editing),
    Row([
      AttachmentMenuButton,
      Expanded(TextField(maxLines: null, textInputAction: TextInputAction.newline)),
      EmojiButton,
      VoiceRecordButton / SendButton (toggle based on text empty),
    ])
  ])
```
- `TextField(maxLines: null)` auto-expands; wrap in `ConstrainedBox(maxHeight: 120)` for max height
- Enter-key-sends: handle `onSubmitted` when `enterKeySends=true`; `textInputAction: TextInputAction.send`

### Audio Recording (Voice Messages)
- Use `record` package (cross-platform) for recording
- Encode to MP3: use `flutter_lame` or platform codec (Android: MediaRecorder with AMR/AAC, convert to MP3; iOS/macOS: AVAudioRecorder; Windows/Linux: ffmpeg subprocess)
- Save to temp file, attach as `Voice` viewtype draft
- Show waveform: use `AnimatedContainer` with simulated or real amplitude data from microphone stream

### Audio Playback
- Use `audioplayers` or `just_audio` package
- Inline `AudioPlayerWidget`: play/pause `IconButton`, `Slider` for seek, speed selector (`DropdownButton`)
- `GlobalVoiceMessagePlayer`: persistent `BottomAppBar`-style overlay that persists across chat navigation; use `OverlayEntry`

### Emoji Picker
- Use `emoji_picker_flutter` package
- Trigger via `showBottomSheet` or `Overlay` positioned above composer
- Sticker picker: custom `GridView` with tabs per sticker pack; load pack images from filesystem path via `File(path).readAsBytesSync()`

### QR Code
- **Display:** `qr_flutter` package — `QrImageView(data: qrString)`
- **Scanning:** `mobile_scanner` package (works on Android/iOS); for desktop (Windows/macOS/Linux) use `camera` plugin + `jsqr` via `js` interop on web, or platform channel to native camera API

### File Attachments
- Use `file_picker` package for cross-platform file selection
- Determine `Viewtype` from MIME type or file extension:
  - `image/*` -> `Image`; `video/*` -> `Video`; `audio/*` -> `Audio`
  - `.gif` -> `Gif`; `.vcf` -> `Vcard`; `.xdc` -> `Webxdc`; else -> `File`
- Drag-and-drop: use `desktop_drop` package; handle `DropTarget` wrapping the `Scaffold`

### Notifications
- Use `flutter_local_notifications` for OS notifications
- Implement `DcNotification` mapping: title = contact name, body = message preview (if `showNotificationContent`)
- Notification grouping by `accountId` using notification channels
- Badge counter: `flutter_app_badger` or platform channels
- On notification tap: navigate to `chatId` in the correct `accountId`

### Theming
```dart
ThemeData(
  brightness: Brightness.light/dark,
  colorScheme: ColorScheme.fromSeed(seedColor: dcColor),
  // Map DC CSS variables to Flutter ThemeData fields
)
```
- Persist selected theme in `DesktopSettingsType.activeTheme`
- Chat background: `BoxDecoration` with `DecorationImage` or `Color` on the message list container
- Support system theme via `MediaQuery.platformBrightnessOf(context)`

### Navigation Architecture
- Use `go_router` or `Navigator 2.0`
- Shell route for main screen (persistent `AccountSidebar`)
- Named routes: `/loading`, `/welcome`, `/login`, `/main`
- For dialogs: `Navigator.of(context).push(DialogRoute(...))` or `showDialog`/`showModalBottomSheet`
- `DialogContext` equivalent: maintain a stack of open dialogs in a `Notifier`; close all on account switch
- Chat selection: store in `Riverpod`/BLoC state, not in URL

### Keyboard Shortcuts
- Use `Shortcuts` widget at root level with `Intent` + `Actions`
- `SingleActivator(LogicalKeyboardKey.keyN, control: true)` -> `NewChatIntent`
- Handle `RawKeyEvent` in `Focus` widget for Up-arrow-to-edit in composer
- Show cheat sheet dialog on dedicated shortcut

### WebXDC Apps
- Launch in `flutter_inappwebview` (`InAppWebView` widget) in a new window (use `Navigator.push` full-screen route or separate `Window` on desktop)
- Implement WebXDC JS bridge via `InAppWebView.addJavaScriptHandler`:
  - `sendUpdate(update, descr)` -> call core `sendWebxdcUpdate`
  - `setUpdateListener(callback, since)` -> subscribe to `WebxdcStatusUpdate` events
  - `sendRealtimeData(data)` -> core `sendWebxdcRealtimeData`
- `WebxdcInstanceDeleted` event -> close the WebXDC window

### Video Calls
- Use `flutter_webrtc` package
- Signaling via core `VideochatInvitation` messages (send/receive SDP offer/answer via DeltaChat messages)
- Show incoming call window: full-screen overlay with accept/reject buttons
- Outgoing: create `RTCPeerConnection`, create offer, send via core, wait for answer

### System Tray
- Use `tray_manager` package
- On window close (if `minimizeToTray` enabled): intercept `onWindowClose` via `window_manager` and hide instead of quit
- Tray menu: "Open", "Quit"
- Update tray icon badge with total unread count

### Autostart
- Use `launch_at_startup` package or platform-specific:
  - Windows: write registry key `HKCU\Software\Microsoft\Windows\CurrentVersion\Run`
  - macOS: `LaunchAgent` plist in `~/Library/LaunchAgents/`
  - Linux: `.desktop` file in `~/.config/autostart/`

### Content Protection / Screen Security
- Use `flutter_screen_security` or platform channels:
  - Windows: `SetWindowDisplayAffinity(WDA_EXCLUDEFROMCAPTURE)`
  - macOS: `NSWindow.sharingType = .none`
  - Linux: X11 overlay or compositor hint (limited support)

### Image Cropper
- Use `image_cropper` package for avatar selection (circle crop mode)

### Fullscreen Media Viewer
```dart
InteractiveViewer(
  boundaryMargin: EdgeInsets.all(20),
  minScale: 0.5,
  maxScale: 5.0,
  child: Image.file(file),
)
```
- Wrap in `PageView` for previous/next navigation between media items in the same chat

### Linkify
- Use `flutter_linkify` package
- Add custom link recognizers for `OPENPGP4FPR:`, `dcaccount:`, `dclogin:` URL schemes
- Handle link taps: open in system browser (`url_launcher`), or handle internally for DC deep links

### Clipboard
- `Clipboard.setData(ClipboardData(text: text))` for text
- For image clipboard: platform channel to `NSPasteboard` (macOS) / `Clipboard.SetImage` (Windows) / `xclip`/`xdg-clipboard` (Linux)
- `Clipboard.getData(Clipboard.kTextPlain)` for paste

### Backup Import/Export Progress
- Core emits `ProgressBar` events (0-1000 scale) during `exportBackup`/`importBackup`
- Show `LinearProgressIndicator` in a dialog, updating via `StreamBuilder` on core events
- `ImexFileWritten` event provides the final file path

### Multi-Device QR Backup
- Sender side: call core to start local HTTP server, get URL, display as QR via `qr_flutter`
- Receiver side: scan QR with `mobile_scanner`, pass URL to core `importBackup`
- Monitor `ProgressBar` events for both sides

### Message Multiselect
- Maintain `Set<int> selectedMessageIds` in `MessageListProvider`
- When non-empty: hide composer, show selection toolbar (`AppBar` replacement or `BottomSheet`)
- Toolbar actions: "Forward" (opens `ForwardMessage` dialog), "Delete" (confirmation then bulk delete)
- Each message bubble: show `Checkbox` overlay when multiselect mode active

### Performance Best Practices
- Use `const` constructors on all stateless widgets
- Cache avatar images with `cached_network_image` (or `Image.memory` with LRU cache)
- Debounce search input with `Timer(Duration(milliseconds: 300), () => search())`
- Use `compute()` for heavy JSON parsing of message lists
- Throttle `MsgsChanged` event handling with debounce (50-100ms) to batch rapid updates
- `RepaintBoundary` on `ChatListItem` and `Message` bubble widgets

### Accessibility
- `Semantics(label: '...', button: true)` on all `GestureDetector` custom buttons
- Use `Semantics(liveRegion: true)` on the new message arrival indicator
- All icon buttons: use `Tooltip` with descriptive `message`
- RTL support: `Directionality` widget at root, use `start`/`end` instead of `left`/`right` in `EdgeInsets`

### Enterprise / RC_Config Equivalent
- Expose runtime config via a JSON file read at startup (e.g., `assets/rc_config.json` or platform-specific path)
- `force_encryption`: expose as a toggle in settings, call `setConfig('force_encryption', '1')`
- `contentProtectionEnabled`: platform channel call on toggle
- `syncAllAccounts`: call `startIo()` for all account IDs on app start, not just selected one
- No MDM/SSO/SAML integration currently required (not present in source)

---

## Key Files to Reference

| File | Purpose |
|---|---|
| `/Volumes/KRYPTIX/test2/sources/deltachat-desktop/packages/frontend/src/ScreenController.tsx` | Top-level screen routing, account loading, ScreenContext |
| `/Volumes/KRYPTIX/test2/sources/deltachat-desktop/packages/frontend/src/components/screens/MainScreen/MainScreen.tsx` | Two-pane main layout, responsive breakpoint, ChatContext |
| `/Volumes/KRYPTIX/test2/sources/deltachat-desktop/packages/frontend/src/components/composer/Composer.tsx` | Full composer logic: draft, reply, edit, attachments, send |
| `/Volumes/KRYPTIX/test2/sources/deltachat-desktop/packages/frontend/src/components/composer/menuAttachment.tsx` | Attachment menu: file types, WebXDC, vCard, sticker |
| `/Volumes/KRYPTIX/test2/sources/deltachat-desktop/packages/frontend/src/components/Settings/Settings.tsx` | Settings modal root, internal navigation between sections |
| `/Volumes/KRYPTIX/test2/sources/deltachat-desktop/packages/frontend/src/components/Settings/Advanced.tsx` | Advanced settings: encryption, BCC, proxy, transports |
| `/Volumes/KRYPTIX/test2/sources/deltachat-desktop/packages/frontend/src/components/Settings/ChatsAndMedia.tsx` | Chats & media settings: enter-key-sends, media quality, auto-delete |
| `/Volumes/KRYPTIX/test2/sources/deltachat-desktop/packages/frontend/src/components/Settings/Appearance.tsx` | Theme picker, background image, font, zoom settings |
| `/Volumes/KRYPTIX/test2/sources/deltachat-desktop/packages/frontend/src/components/Settings/Notifications.tsx` | Notification settings: toggle, content, sounds, volume |
| `/Volumes/KRYPTIX/test2/sources/deltachat-desktop/packages/frontend/src/components/Settings/ExperimentalFeatures.tsx` | Experimental feature toggles |
| `/Volumes/KRYPTIX/test2/sources/deltachat-desktop/packages/frontend/src/components/chat/ChatContextMenu.tsx` | Chat-level context menu: pin/archive/mute/clear/delete/block |
| `/Volumes/KRYPTIX/test2/sources/deltachat-desktop/packages/frontend/src/components/message/Message.tsx` | Message bubble: all message types, reactions, status, context menu |
| `/Volumes/KRYPTIX/test2/sources/deltachat-desktop/packages/frontend/src/components/message/messageFunctions.ts` | Message action handlers: forward, delete, copy, reply, etc. |
| `/Volumes/KRYPTIX/test2/sources/deltachat-desktop/packages/frontend/src/components/Gallery.tsx` | Tabbed media browser: Apps/Images/Video/Audio/Files |
| `/Volumes/KRYPTIX/test2/sources/deltachat-desktop/packages/frontend/src/components/dialogs/CreateChat/index.tsx` | New chat flow: contact search, group/broadcast creation |
| `/Volumes/KRYPTIX/test2/sources/deltachat-desktop/packages/frontend/src/components/dialogs/ViewProfile/index.tsx` | Contact profile dialog: info, shared chats, actions |
| `/Volumes/KRYPTIX/test2/sources/deltachat-desktop/packages/frontend/src/components/dialogs/ViewGroup.tsx` | Group info dialog: members, QR, edit, leave |
| `/Volumes/KRYPTIX/test2/sources/deltachat-desktop/packages/frontend/src/components/dialogs/Transports/index.tsx` | IMAP/SMTP transport management dialog |
| `/Volumes/KRYPTIX/test2/sources/deltachat-desktop/packages/frontend/src/components/screens/WelcomeScreen/index.tsx` | Welcome/onboarding screen root |
| `/Volumes/KRYPTIX/test2/sources/deltachat-desktop/packages/frontend/src/components/screens/WelcomeScreen/AlternativeSetupsDialog.tsx` | Alternative onboarding: backup import, second-device, manual |
| `/Volumes/KRYPTIX/test2/sources/deltachat-desktop/packages/frontend/src/components/AccountListSidebar/AccountListSidebar.tsx` | Account sidebar: avatars, unread badges, drag-to-reorder |
| `/Volumes/KRYPTIX/test2/sources/deltachat-desktop/packages/frontend/src/keybindings.ts` | All keyboard shortcut definitions and handlers |
| `/Volumes/KRYPTIX/test2/sources/deltachat-desktop/packages/frontend/src/stores/settings.ts` | SettingsStore: core + desktop settings state, persistence |
| `/Volumes/KRYPTIX/test2/sources/deltachat-desktop/packages/frontend/src/system-integration/notifications.ts` | OS notification dispatch, grouping, badge updates |
| `/Volumes/KRYPTIX/test2/sources/deltachat-desktop/packages/frontend/src/system-integration/webxdc.ts` | WebXDC JS bridge, app window management, realtime events |
| `/Volumes/KRYPTIX/test2/sources/deltachat-desktop/packages/runtime/runtime.ts` | Runtime abstraction layer over Electron/Tauri/Browser |
| `/Volumes/KRYPTIX/test2/sources/deltachat-desktop/packages/shared/shared-types.d.ts` | All shared TypeScript type definitions (canonical data model reference) |
| `/Volumes/KRYPTIX/test2/sources/deltachat-desktop/packages/target-electron/src/ipc.ts` | Electron main process IPC handlers, native bridges |
| `/Volumes/KRYPTIX/test2/sources/deltachat-desktop/packages/target-electron/src/windows/video-call.ts` | WebRTC video call window, signaling flow |
| `/Volumes/KRYPTIX/test2/sources/deltachat-desktop/packages/frontend/src/components/LoginForm.tsx` | Manual IMAP/SMTP login form with all advanced fields |

---

## Next Steps

### Priority 1: Foundation
1. **Core binding:** Set up `deltachat-rpc-server` subprocess + Dart isolate JSON-RPC communication layer; implement `DcEvent` stream
2. **State management scaffolding:** Create `AccountStoreProvider`, `ChatStoreProvider`, `SettingsStoreProvider`, `MessageListProvider` with Riverpod
3. **Navigation scaffold:** Set up `go_router` shell route, routes for `/loading`, `/welcome`, `/login`, `/main`
4. **Main layout:** Implement responsive `LayoutBuilder` two-pane layout with `AccountSidebar` + `ChatListPane` + `MessageViewPane`

### Priority 2: Core Chat Flow
5. **Account sidebar:** `NavigationRail` with account avatars, unread badges, drag-to-reorder
6. **Chat list:** `ListView.builder` with `ChatListItem` widgets — avatar, name, last message, timestamp, unread badge, muted/pinned icons
7. **Message list:** `CustomScrollView` + `SliverList` reverse scroll, date separators, load-more-on-scroll, message grouping
8. **Message bubbles:** Text, Image, Video, Audio, Voice, File, Sticker types; sender avatar in groups; timestamp + status icons
9. **Composer:** Text input, send button, reply preview, edit mode, voice record toggle

### Priority 3: Attachments and Media
10. **File attachments:** `file_picker` integration, MIME-type-to-Viewtype mapping, drag-and-drop (`desktop_drop`)
11. **Image/video viewer:** `InteractiveViewer` + `PageView` for fullscreen with prev/next
12. **Gallery/media browser:** Tabbed view with grid (images) and list (audio/files) per tab
13. **Audio recording:** `record` package + MP3 encoding + waveform display
14. **Audio playback:** `audioplayers` inline player + `GlobalVoiceMessagePlayer` overlay

### Priority 4: Dialogs and Settings
15. **Settings modal:** Multi-section internal Navigator, all five sections with their controls
16. **ViewProfile / ViewGroup dialogs:** Full contact/group info with actions
17. **CreateChat flow:** Contact list + search + group/broadcast creation steps
18. **Context menus:** Chat-level and message-level positioned popup menus
19. **Emoji picker:** `emoji_picker_flutter` integration + sticker pack tabs

### Priority 5: Advanced Features
20. **Onboarding:** Welcome screen, instant chatmail flow, manual login form, backup import
21. **QR codes:** `qr_flutter` for display, `mobile_scanner` for scanning
22. **Notifications:** `flutter_local_notifications` with grouping, badge counter
23. **WebXDC apps:** `flutter_inappwebview` with JS bridge for `sendUpdate`/`setUpdateListener`
24. **Keyboard shortcuts:** `Shortcuts` + `Actions` at root, cheat sheet dialog

### Priority 6: Desktop-Specific
25. **System tray:** `tray_manager` + `window_manager` for minimize-to-tray
26. **Autostart:** `launch_at_startup` package or platform-specific registry/plist/desktop file
27. **Content protection:** Platform channel for `SetWindowDisplayAffinity` / `NSWindow.sharingType`
28. **Video calls:** `flutter_webrtc` + WebRTC signaling via core call messages
29. **Theme system:** Full `ThemeData` mapping, custom background images, light/dark/system toggle

### Known Complexity Areas
- **Core event handling at scale:** `MsgsChanged` fires very frequently; must debounce/batch UI updates aggressively
- **WebXDC JS bridge:** Complex two-way communication between Dart and JavaScript in webview
- **Multi-account background sync:** `startIo()` for all accounts simultaneously; handle events from multiple accounts concurrently in a single stream
- **Voice message MP3 encoding:** Cross-platform MP3 encoding is non-trivial; may need `ffmpeg` subprocess on desktop
- **QR scanning on desktop:** No built-in camera API on desktop Flutter; need platform channel or `camera` plugin with desktop support
- **Drag-to-reorder account sidebar:** `ReorderableListColumn` or custom drag logic with `LongPressDraggable`
- **HTML email view:** Sandboxed webview with remote content controls; requires careful security review
- **RTL layout:** Test all `Row`/`EdgeInsets` usages with Arabic/Hebrew locales; use `EdgeInsetsDirectional`
