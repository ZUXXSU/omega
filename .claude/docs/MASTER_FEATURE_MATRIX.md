# Omega — Unified Master Feature Matrix
# Flutter Implementation Guide
# Generated: 2026-06-14
# Source analyses: Desktop (Electron/React), Android (Java), iOS (Swift/UIKit), Web (Jekyll)

---

## HOW TO READ THIS DOCUMENT

- **P0** = Must ship in v1.0 (app is broken/unusable without it)
- **P1** = Must ship before public release (core UX completeness)
- **P2** = Ship in v1.x point releases (quality-of-life)
- **P3** = Future / platform-specific stretch goals
- **[ALL]** = Present on all 4 analyzed platforms
- **[D]** = Desktop only  **[A]** = Android only  **[iO]** = iOS only  **[W]** = Web/pages only
- **[D+A]** = Desktop + Android, etc.
- **MERGE** = Same feature exists on 2+ platforms with different implementations; Flutter unifies them

---

## SECTION 1 — CORE FEATURES PRESENT ON ALL PLATFORMS

These features exist (in some form) across Desktop, Android, iOS, and the documented app behavior on the web pages. Every one is **P0 or P1**.

### 1.1 Account Management [ALL]

| Feature | Priority | Flutter Package(s) | Notes |
|---|---|---|---|
| Add new account (chatmail instant signup) | P0 | http/dio | Single tap → auto-provision on chatmail server |
| Add account via manual IMAP/SMTP | P0 | — | Full advanced settings: server, port, TLS, cert checks |
| Add account via QR scan (dcaccount:/dclogin:) | P0 | mobile_scanner | URL scheme deep link handler required |
| Add account via backup import | P0 | file_picker | Import .tar backup file |
| Multi-account switcher UI | P0 | — | Sidebar (desktop), drawer/dialog (mobile) |
| Remove / delete account | P0 | — | With confirmation dialog |
| Account display name + avatar | P0 | image_picker, image_cropper | Editable from profile settings |
| Account color (derived from address hash) | P1 | — | Used in avatar fallback |
| Switch selected account | P0 | — | All IO switches to selected account context |
| Account list ordering / reorder | P2 | — | Drag-to-reorder on sidebar |

**Core RPC methods:** `getAllAccountIds`, `addAccount`, `removeAccount`, `getAccountInfo`, `selectAccount`, `startIo`, `stopIo`

### 1.2 Onboarding / Welcome Flow [ALL]

| Feature | Priority | Flutter Package(s) | Notes |
|---|---|---|---|
| Welcome screen (first launch, no account) | P0 | — | Two primary paths: instant or manual |
| Instant onboarding (chatmail, no email knowledge) | P0 | dio | Fetch chatmail instance list, auto-create account |
| Enter display name step | P0 | — | Required before chatmail creation |
| Manual email+password login | P0 | — | Standard IMAP/SMTP credential entry |
| Advanced server settings (host, port, TLS, cert) | P1 | — | Collapsible "advanced" section |
| Email provider info banner (ProviderInfo) | P1 | — | Show provider logo/help based on email domain |
| Restore from backup file (import) | P1 | file_picker | .tar backup |
| Receive-from-second-device (QR backup transfer) | P1 | mobile_scanner, qr_flutter | Scan QR on existing device to pull backup |
| OAuth2 login (Gmail/etc) | P2 | url_launcher | Open OAuth URL in browser |

**Flutter flow:** WelcomeScreen → (InstantOnboardingScreen OR ManualLoginScreen OR BackupRestoreScreen)

### 1.3 Chat List [ALL]

| Feature | Priority | Flutter Package(s) | Notes |
|---|---|---|---|
| Virtualized chat list (all chats) | P0 | ListView.builder | Use ChatListItemFetchResult for perf |
| Chat list item: avatar, name, preview, timestamp | P0 | timeago | Standard list row |
| Unread badge count per chat | P0 | badges | Red bubble with count |
| Muted chat indicator | P0 | — | Speaker-off icon |
| Pinned chat indicator | P0 | — | Pin icon, sorted to top |
| Archived chats section | P0 | — | Separate archive view |
| Contact request badge | P0 | — | Orange/warning badge style |
| Search chats + contacts + messages | P0 | — | Debounced search input |
| Typing indicator in list | P1 | — | "typing..." preview text |
| Archive/unarchive via swipe or context menu | P0 | flutter_slidable | Swipe action |
| Pin/unpin chat | P0 | — | Long-press or context menu |
| Mark as read / unread | P0 | — | Context menu action |
| Mute chat (duration picker) | P0 | — | 1hr/8hr/1day/7day/forever |
| Delete chat | P0 | — | With confirmation |
| Clear chat history | P1 | — | Delete all messages but keep chat |
| Sort: pinned first, then by last message time | P0 | — | Core returns sorted IDs |
| Global unread badge on app icon | P1 | flutter_app_badger | Sum across all accounts |

**Core RPC:** `getChatListIds`, `getChatListItemsByEntries`, `setChatVisibility`, `setChatMuteDuration`, `marknoticedChat`, `markfreshChat`

### 1.4 Chat View / Message Thread [ALL]

| Feature | Priority | Flutter Package(s) | Notes |
|---|---|---|---|
| Infinite-scroll message list (reverse chronological) | P0 | CustomScrollView + SliverList | Load older on scroll-to-top |
| Day separator markers | P0 | — | Core provides DayMarker items in list |
| Jump-to-message (from search, reply tap) | P0 | ScrollController | Scroll to specific index |
| Search within chat | P1 | — | In-chat search bar with prev/next |
| Message bubble (sent/received styles) | P0 | — | Distinct color/alignment |
| Sender name + avatar in groups | P0 | — | Only show for received messages in groups |
| Delivery status ticks (sending/sent/delivered/read/failed) | P0 | — | Icon set in message footer |
| Timestamp in message footer | P0 | intl | Format as HH:mm |
| Forwarded indicator | P0 | — | "Forwarded" label above message |
| Edited label | P0 | — | "Edited" label in message footer |
| Message encryption padlock | P1 | — | Only shown when not E2EE (V2 model: no lock when E2EE) |
| Contact request banner (accept/block) | P0 | — | Sticky banner at top of chat |
| Ephemeral timer icon in chat header | P1 | — | Flame/timer icon when active |
| Encryption status icon in chat header | P1 | — | Lock icon |
| Info messages (system events: join, leave, etc.) | P0 | — | Centered system message style |

**Core RPC:** `getMessages`, `getMessage`, `markSeenMessages`

### 1.5 Message Types — Rendering [ALL]

| Message Type | Priority | Flutter Package(s) | Notes |
|---|---|---|---|
| Text (with link detection) | P0 | flutter_linkify | clickable URLs, emails, phone numbers |
| Bold/italic markdown (**bold**, _italic_) | P1 | flutter_markdown or custom spans | Core may pre-process |
| Image (JPEG/PNG/WebP/GIF) | P0 | cached_network_image, extended_image | Thumbnail in bubble, tap to fullscreen |
| Animated GIF | P0 | extended_image | Auto-play |
| Video (MP4) | P0 | video_player | Thumbnail + play button |
| Audio | P0 | just_audio | Waveform + play/pause + progress slider |
| Voice message | P0 | just_audio, audio_waveforms | Distinct from audio: mic icon |
| File / Document | P0 | open_file | Icon + filename + size |
| Sticker | P1 | — | Image with transparent background, no bubble |
| vCard contact | P1 | — | Card widget: name + avatar + "Add contact" button |
| WebXDC mini-app | P1 | webview_flutter | App icon + name + summary |
| Call invitation (VideochatInvitation) | P1 | — | "Join call" button |
| Location (via WebXDC map) | P2 | — | Map pin preview |
| HTML email | P2 | webview_flutter | "View in browser" or inline WebView |
| Info/system messages | P0 | — | Group events, key changes |

### 1.6 Message Composition [ALL]

| Feature | Priority | Flutter Package(s) | Notes |
|---|---|---|---|
| Auto-expanding text input | P0 | — | TextField with maxLines: null |
| Send button (replaces mic when text present) | P0 | — | Morphing button state |
| Emoji picker | P0 | emoji_picker_flutter | Popover/bottom sheet |
| Sticker picker | P1 | — | Grid from filesystem sticker packs |
| Attach image from gallery | P0 | image_picker | |
| Attach image from camera | P0 | image_picker | |
| Attach video | P0 | image_picker | |
| Attach audio file | P0 | file_picker | |
| Attach arbitrary file | P0 | file_picker | |
| Attach vCard contact | P1 | — | Contact picker → make_vcard |
| Attach WebXDC app | P1 | file_picker | .xdc file, or from app store |
| Voice message recording | P0 | record | Hold mic to record, release to send |
| Voice message cancel (swipe to cancel) | P1 | — | Gesture dismiss recording |
| Voice message preview before send | P1 | — | Play before confirming send |
| Reply-to-quote | P0 | — | Shows quoted message above input |
| Draft persistence | P0 | — | saveDraft on leave, loadDraft on enter |
| Paste image from clipboard | P1 | — | Platform channel on desktop |
| Drag-and-drop files (desktop) | P2 | desktop_drop | Only Windows/macOS/Linux |
| Enter-key-sends toggle | P1 | — | Desktop default ON, mobile default OFF |
| Send location (via WebXDC map) | P2 | — | Location streaming feature |

**Core RPC:** `sendMessage`, `saveDraft`, `removeDraft`, `getDraft`

### 1.7 Message Actions / Context Menu [ALL]

| Action | Priority | Notes |
|---|---|---|
| Reply (sets quote) | P0 | Swipe-to-reply gesture on mobile |
| Forward to another chat | P0 | Chat picker dialog |
| Copy text | P0 | Clipboard.setData |
| Copy image | P1 | Platform channel |
| React with emoji | P0 | Quick-react row + full picker |
| Info / Details (delivery status, read receipts) | P1 | MessageInfo dialog |
| Download / Save to device | P1 | Permission + save to gallery/downloads |
| Save to Saved Messages | P1 | Forward to self-talk chat |
| Edit (own messages only) | P0 | Re-enter message in composer with editing mode |
| Delete for me only | P0 | Local delete |
| Delete for everyone | P0 | Requires remote delete request |
| Private reply (in groups) | P1 | Start 1:1 chat with sender |
| Select (enter multiselect) | P1 | Triggers multiselect mode |

**Core RPC:** `sendReaction`, `sendEditRequest`, `deleteMessages`, `forwardMessages`, `getMessageInfo`

### 1.8 Message Multiselect [ALL]

| Feature | Priority | Notes |
|---|---|---|
| Enter multiselect on long-press | P1 | Or via context menu |
| Select/deselect individual messages | P1 | Checkbox per message |
| Select all | P2 | |
| Bulk forward | P1 | Forward selected to another chat |
| Bulk delete | P1 | Delete all selected (for-me or for-everyone) |
| Multiselect toolbar | P1 | Replace composer with action toolbar |

### 1.9 Message Reactions [ALL]

| Feature | Priority | Flutter Package(s) | Notes |
|---|---|---|---|
| Reaction bar below message | P0 | — | Grouped by emoji, count, self-highlight |
| Quick-react popover (6 common emoji) | P1 | — | Tap-and-hold message → quick react |
| Full emoji picker for reaction | P1 | emoji_picker_flutter | "+" button in quick-react |
| Toggle own reaction (tap to add/remove) | P0 | — | sendReaction with empty list to remove |
| Reactions detail sheet | P1 | — | Who reacted with what, grouped by emoji |
| Incoming reaction notifications | P1 | — | DC_EVENT_INCOMING_REACTION |

**Core RPC:** `sendReaction`, reactions field on Message object

### 1.10 Message Status & Delivery [ALL]

| Feature | Priority | Notes |
|---|---|---|
| Sending (clock icon) | P0 | |
| Sent (single tick) | P0 | |
| Delivered (double tick) | P0 | |
| Read / Seen (colored double tick) | P0 | Requires MDN enabled |
| Failed (red X / error) | P0 | |
| Message info screen (per-recipient read receipts) | P1 | List of contacts + timestamp |
| Toggle MDN (read receipts) globally | P1 | Settings toggle |

### 1.11 Group Chats [ALL]

| Feature | Priority | Notes |
|---|---|---|
| Create encrypted group | P0 | |
| Create unencrypted (ad-hoc) group | P0 | |
| Set group name | P0 | |
| Set group avatar | P0 | image_picker + image_cropper |
| Add members | P0 | Contact picker |
| Remove members (admin only) | P0 | |
| Leave group | P0 | |
| Delete group (remove from all) | P1 | |
| Edit group name / avatar | P0 | |
| View all group members with roles | P0 | |
| QR code invite to group | P0 | qr_flutter |
| Clone group | P2 | |
| Admin/member role icons | P1 | |
| Verified group (E2EE, lock icon) | P1 | |
| Who-can-send permissions (groups) | P1 | |
| Group description / bio | P1 | set_chat_description RPC |

**Core RPC:** `createGroupChat`, `addContactToChat`, `removeContactFromChat`, `setGroupName`, `setGroupImage`

### 1.12 Contacts [ALL]

| Feature | Priority | Flutter Package(s) | Notes |
|---|---|---|---|
| View contact profile (name, address, avatar, status, last-seen) | P0 | — | Profile sheet/screen |
| Create new contact | P0 | — | Enter name + email address |
| Block / Unblock contact | P0 | — | From profile or chat context menu |
| Encryption info per contact | P1 | — | Key fingerprint, Autocrypt status |
| Verified badge on contact | P1 | — | SecureJoin verified |
| Last seen timestamp | P1 | timeago | "seen 5 minutes ago" |
| View shared chats with contact | P1 | — | List of mutual chats |
| Edit contact display name | P1 | — | Change locally visible name |
| Send vCard (contact as message) | P1 | — | makeVcard RPC |
| Import vCard from message | P1 | — | parseVcard + importVcard RPC |
| Contact request handling (accept/block) | P0 | — | Banner in chat |
| Blocked contacts list | P1 | — | In settings/advanced |
| Bot flag display | P2 | — | [BOT] badge on bot contacts |
| Contact status (bio text) | P1 | — | Shown in profile |

**Core RPC:** `createContact`, `getContact`, `blockContact`, `unblockContact`, `getContactEncryptionInfo`, `makeVcard`, `parseVcard`, `importVcard`

### 1.13 QR Codes [ALL]

| QR Action | Priority | Flutter Package(s) | Notes |
|---|---|---|---|
| Show own QR (contact invite) | P0 | qr_flutter | SVG from getChatSecurejoinQrCodeSvg |
| Scan QR to add contact (SecureJoin) | P0 | mobile_scanner | openpgp4fpr: scheme |
| Scan/show QR to join group | P0 | mobile_scanner, qr_flutter | |
| Scan/show QR to join broadcast channel | P1 | mobile_scanner, qr_flutter | |
| Scan QR to add account (dcaccount:/dclogin:) | P0 | mobile_scanner | Onboarding |
| Scan QR for backup transfer (receive) | P1 | mobile_scanner | |
| Show QR for backup transfer (send) | P1 | qr_flutter | |
| Scan QR for proxy config (socks5:/ss:) | P1 | mobile_scanner | |
| Scan QR for WebRTC instance | P2 | mobile_scanner | |
| QR scanner overlay UI | P0 | mobile_scanner | Camera viewfinder with corner guides |
| QR display with sharing | P0 | qr_flutter, share_plus | Allow user to share QR image |

**Core RPC:** `getChatSecurejoinQrCodeSvg`, `checkQr`, `setConfigFromQr`, `continueKeyTransfer`

### 1.14 Ephemeral / Disappearing Messages [ALL]

| Feature | Priority | Notes |
|---|---|---|
| Set timer per-chat | P0 | Dialog with radio options |
| Timer values: off, 1min, 5min, 30min, 1hr, 1day, 1week, 4weeks | P0 | All platforms support these |
| Timer icon in chat header when active | P1 | Flame/timer icon |
| Global auto-delete setting | P1 | Separate: device-side timer for all chats |
| Messages visually countdown/expire | P2 | Core handles deletion; UI just reflects |

**Core RPC:** `getChatEphemeralTimer`, `setChatEphemeralTimer`

### 1.15 Media Gallery [ALL]

| Feature | Priority | Flutter Package(s) | Notes |
|---|---|---|---|
| Per-chat media browser | P1 | — | Tabbed: Images/Videos/Audio/Files |
| WebXDC apps tab | P1 | — | Apps sent in chat |
| Image grid layout | P1 | GridView | Thumbnail grid |
| Video grid with play overlay | P1 | — | |
| Audio list | P1 | — | With playback |
| Files list | P1 | — | Open with external app |
| Fullscreen image viewer | P0 | photo_view / InteractiveViewer | Zoom/pan |
| Fullscreen video player | P0 | video_player | |
| Prev/next navigation in fullscreen | P1 | PageView | Swipe between media items |
| Download / save to device | P1 | — | gallery_saver or path_provider |
| Share media item | P1 | share_plus | |

**Core RPC:** `getChatMedia`

### 1.16 Backup & Multi-Device [ALL]

| Feature | Priority | Flutter Package(s) | Notes |
|---|---|---|---|
| Export backup to file (.tar) | P1 | file_picker | Choose save location |
| Import backup from file | P1 | file_picker | .tar file selection |
| Multi-device: send backup via QR (provider) | P1 | qr_flutter | Show QR with iroh-net address |
| Multi-device: receive backup via QR (receiver) | P1 | mobile_scanner | Scan QR, pull backup over local network |
| Progress indicator during backup | P1 | — | Core emits ProgressBar events |
| BCC-self toggle (sync across devices) | P1 | — | Settings toggle |

**Core RPC:** `exportBackup`, `importBackup`, `provideBackup`, `getBackup`, `getBackupQr`

### 1.17 Notifications [ALL]

| Feature | Priority | Flutter Package(s) | Notes |
|---|---|---|---|
| Incoming message notification | P0 | firebase_messaging, flutter_local_notifications | Per-account grouping |
| Notification shows sender + preview | P0 | — | |
| Notification privacy: hide content | P1 | — | Show only "New message" |
| Notification privacy: hide sender | P1 | — | Show only app name |
| Per-chat mute (suppress notifications) | P0 | — | Duration-based |
| Per-account notification toggle | P1 | — | |
| Mention-only mode | P2 | — | Only notify if @mentioned |
| Notification tap → open correct account + chat | P0 | go_router | Deep route via notification payload |
| Inline reply from notification (Android) | P1 | flutter_local_notifications | RemoteInput action |
| Mark as read from notification (Android) | P1 | flutter_local_notifications | Action button |
| Incoming call notification (WebRTC) | P1 | flutter_callkit_incoming | Separate high-priority notification |
| Badge count on app icon | P1 | flutter_app_badger | Sum of all unread |
| FCM push (Android/iOS) | P0 | firebase_messaging | Token registered with core |
| Background polling fallback (no FCM/FOSS) | P2 | workmanager | Periodic background fetch |

### 1.18 Connectivity Monitoring [ALL]

| Feature | Priority | Flutter Package(s) | Notes |
|---|---|---|---|
| Connection status toast/banner | P1 | — | "Connecting..." / "Connected" / "Offline" |
| Connectivity details screen | P1 | webview_flutter | Core returns HTML via getConnectivityHtml |
| IMAP/SMTP status per account | P1 | — | Connected / Connecting / Disconnected |
| Network change detection → reconnect | P0 | connectivity_plus | maybeNetwork on reconnect |

**Core RPC:** `maybeNetwork`, `getConnectivity`, `getConnectivityHtml`

### 1.19 Settings [ALL]

| Setting Category | Priority | Notes |
|---|---|---|
| **Profile**: name, avatar, status/bio, address | P0 | Self-profile edit |
| **Chats & Media**: enter-key-sends, media quality (standard/worse), auto-download limit, chat background | P1 | |
| **Notifications**: per-account toggle, content privacy, in-app sounds | P1 | |
| **Appearance**: light/dark/system theme, font size, chat wallpaper | P1 | |
| **Advanced**: read receipts (MDN), BCC-self, auto-delete, proxy, transports, log viewer, encryption info | P1 | |
| **Experimental**: location streaming, WebXDC dev tools, force encryption | P2 | |
| Settings accessible from main screen | P0 | Bottom sheet or settings screen |

### 1.20 Proxy Support [ALL]

| Feature | Priority | Notes |
|---|---|---|
| SOCKS5 proxy per account | P1 | |
| HTTP proxy per account | P1 | |
| Shadowsocks (ss://) via QR | P2 | Android-only in reference impl; extend to all |
| Add proxy via QR scan | P1 | mobile_scanner |
| Enable/disable proxy toggle | P1 | |
| Proxy list management | P1 | |

**Core RPC:** `setConfig(accountId, 'proxy_url', url)`, `setConfig(accountId, 'proxy_enabled', '1')`

### 1.21 Transport / Multi-Relay [D+A+iO]

| Feature | Priority | Notes |
|---|---|---|
| List multiple IMAP/SMTP transports per account | P1 | |
| Add transport (manual or via QR) | P1 | |
| Set default transport | P1 | |
| Delete transport | P1 | |
| Transport unpublished flag | P2 | Secondary emails not advertised |

**Core RPC:** `listTransportsEx`, `addOrUpdateTransport`, `deleteTransport`, `setDefaultTransport`

### 1.22 Broadcast Channels [ALL]

| Feature | Priority | Notes |
|---|---|---|
| Create broadcast channel (OutBroadcast) | P1 | One-to-many send |
| Subscribe to incoming broadcast (InBroadcast) | P1 | |
| View channel info | P1 | |
| Leave channel | P1 | |
| Read-only indication for subscribers | P1 | |

### 1.23 Saved Messages / Self-Talk [ALL]

| Feature | Priority | Notes |
|---|---|---|
| Dedicated self-talk chat (Saved Messages) | P0 | Always visible in chat list |
| Save any message to Saved Messages | P0 | Context menu action (forward to self) |
| Device messages chat (system info) | P1 | Read-only changelog/tips from core |

### 1.24 WebXDC Mini-Apps [ALL]

| Feature | Priority | Flutter Package(s) | Notes |
|---|---|---|---|
| Open WebXDC in sandboxed WebView | P1 | webview_flutter, flutter_inappwebview | No external network, no cookies |
| JS bridge: window.webxdc.sendUpdate() | P1 | — | Post message to/from WebView |
| JS bridge: window.webxdc.setUpdateListener() | P1 | — | Core pushes status updates |
| Realtime data channel (sendRealtimeData) | P2 | — | Peer-to-peer realtime via core |
| WebXDC app store browser | P2 | — | HTTP fetch via core getHttpResponse |
| WebXDC app thumbnail in chat | P1 | — | Icon + name + summary |
| WebXDC in-chat apps tab (media gallery) | P1 | — | List of all apps in chat |
| Integration webxdc (maps, etc.) | P2 | — | setWebxdcIntegration, initWebxdcIntegration |

**Core RPC:** `getWebxdcInfo`, `sendWebxdcUpdate`, `getWebxdcStatusUpdates`, `sendWebxdcRealtimeData`

### 1.25 Encryption & Security [ALL]

| Feature | Priority | Notes |
|---|---|---|
| E2EE info per contact | P1 | Key fingerprint display |
| E2EE info per chat/group | P1 | Protection status |
| Verified contact badge (SecureJoin) | P1 | Green checkmark (V1) or simplified (V2) |
| Force encryption toggle | P2 | Require E2EE on all outgoing |
| DB encryption (passphrase in secure storage) | P0 | flutter_secure_storage → Keychain/Keystore |
| Screen security (prevent screenshots) | P2 | flutter_windowmanager (Android), platform channel (iOS) |
| OpenPGP key export/import | P2 | exportSelfKeys/importSelfKeys |

---

## SECTION 2 — PLATFORM-SPECIFIC FEATURES

Features unique to one platform, with Flutter implementation guidance.

### 2.1 Desktop-Only [D]

| Feature | Priority | Flutter Package(s) | Notes |
|---|---|---|---|
| System tray icon with badge | P2 | tray_manager | Windows/macOS/Linux |
| Minimize to system tray | P2 | tray_manager | |
| Autostart on system startup | P3 | launch_at_startup | |
| Global keyboard shortcuts (Ctrl+N, Ctrl+F, etc.) | P2 | Shortcuts widget + Actions | Full keybinding map |
| Keyboard zoom (Ctrl+/−) | P3 | — | |
| Drag-and-drop files into composer | P1 | desktop_drop | Windows/macOS/Linux |
| Paste image from clipboard | P1 | — | Platform channel |
| WebXDC in separate window | P2 | — | Open WebView in new Flutter window |
| WebXDC developer tools | P3 | — | flutter_inappwebview devtools |
| Two-pane layout (chat list + message view) | P0 | LayoutBuilder | >= 720dp wide → dual pane |
| NavigationRail for account sidebar | P0 | NavigationRail | Vertical left sidebar |
| Video/audio calls (WebRTC) | P2 | flutter_webrtc | Desktop WebRTC peer connection |
| HTML email view in separate window | P2 | webview_flutter | or system browser |
| RC_Config flags (devmode, log-debug, etc.) | P3 | — | CLI args or config file |
| Keybinding cheat sheet popup | P3 | — | |

### 2.2 Android-Only [A]

| Feature | Priority | Flutter Package(s) | Notes |
|---|---|---|---|
| FCM push via Firebase (gplay flavor) | P0 | firebase_messaging | Token: `fcm-{appId}:{token}` |
| Background polling via WorkManager (FOSS flavor) | P2 | workmanager | No Google Services fallback |
| FOSS / F-Droid build variant | P2 | — | flavor with no Firebase |
| Inline reply from notification | P1 | flutter_local_notifications | Android RemoteInput |
| Mark-as-read from notification | P1 | flutter_local_notifications | Notification action |
| Direct share shortcuts to chats | P2 | — | ShortcutManager API via platform channel |
| System share sheet receive (share target) | P1 | receive_sharing_intent | Files/text from other apps |
| Wear OS remote reply | P3 | — | Platform channel |
| Samsung multi-window | P3 | — | Auto-handled by Flutter |
| PanicKit integration | P3 | — | GuardianProject panic button; platform channel |
| Incognito keyboard | P2 | — | InputType flag via platform channel |
| Screen lock (biometrics) | P2 | local_auth | System credential before opening app |
| Boot receiver (restart sync after reboot) | P1 | workmanager | Register boot completed receiver |
| FLAG_SECURE (block screenshots) | P2 | flutter_windowmanager | |
| FCM background fetch service | P0 | firebase_messaging | Background message handler |
| allowBackup=false in manifest | P0 | — | AndroidManifest.xml setting |
| Video transcoding before send | P2 | flutter_ffmpeg or platform channel | MP4 reencoding |
| Image scribble/draw editor | P2 | — | CustomPainter or painting_board |
| Stats sending opt-in (anonymous telemetry) | P3 | — | CONFIG_STATS_SENDING |

### 2.3 iOS-Only [iO]

| Feature | Priority | Flutter Package(s) | Notes |
|---|---|---|---|
| APNS push (Apple Push Notification Service) | P0 | firebase_messaging | Also registers with dc_accounts_set_push_device_token |
| VoIP push (PushKit) for calls | P1 | flutter_callkit_incoming | Wakes app for incoming calls |
| CallKit integration (native call UI) | P1 | flutter_callkit_incoming | Native iOS call screen |
| Notification Service Extension (NSE) | P1 | — | Native Swift extension; background fetch without waking app |
| App Clip (i.delta.chat invite links) | P3 | — | Native App Clip target |
| WidgetKit home-screen widget | P3 | — | Native Swift widget; shared UserDefaults |
| Share extension (receive from other apps) | P1 | receive_sharing_intent | Native share extension |
| State restoration (last tab + chat) | P1 | — | Persist in go_router or shared prefs |
| Siri/Shortcuts integration (INStartAudioCallIntent) | P3 | — | Platform channel |
| QuickLook file preview | P1 | open_file | iOS handles natively |
| Picture-in-Picture video call | P2 | pip_view or platform channel | |
| Keychain sharing group (persist across reinstalls) | P1 | flutter_secure_storage | accessGroup config |
| App Groups shared container (NSE + widget) | P1 | — | path_provider + group container |
| DarwinNotificationCenter (NSE ↔ app signal) | P1 | — | Platform channel or shared UserDefaults flag |
| ReachabilitySwift → maybeNetwork trigger | P0 | connectivity_plus | Flutter equivalent |
| Certificate pinning per transport | P1 | — | Accept-all or strict; core config |

### 2.4 Web / PWA [W]

| Feature | Priority | Flutter Package(s) | Notes |
|---|---|---|---|
| Progressive Web App (installable) | P2 | — | flutter build web with manifest.json |
| Service worker / offline cache | P2 | — | Flutter web has basic SW; custom for offline chat |
| Web-optimized landing page | P2 | — | Flutter web route or separate Jekyll page |
| Mastodon blog comments embed | P3 | webview_flutter | or link out |
| Language selector (20+ locales) | P1 | flutter_localizations | |
| Deep link handling in browser (i.delta.chat) | P1 | go_router | Universal links |
| Note: deltachat-core Rust not WASM-compatible | — | — | Web target requires server-side core component; defer full web support |

---

## SECTION 3 — FEATURES TO MERGE (SAME FEATURE, DIFFERENT IMPLEMENTATIONS)

### 3.1 Audio Recording

| Platform | Implementation | Flutter Unified |
|---|---|---|
| Desktop | lamejs (MP3 encoding in JS) | `record` package → OGG/Opus or M4A |
| Android | Java AudioRecorder + OGG/Opus | `record` package (platform-native codec) |
| iOS | AVFoundation + AVAudioRecorder | `record` package (AVAudioSession) |

**Decision:** Use `record` package with OGG/Opus output on Android, M4A on iOS, OGG on desktop. Core expects Viewtype.Voice; format must match what core can handle. Verify with `sendMessage(viewType: Viewtype.voice)`.

### 3.2 Audio Playback

| Platform | Implementation | Flutter Unified |
|---|---|---|
| Desktop | HTML5 Audio element | `just_audio` + `audio_session` |
| Android | Media3 / ExoPlayer + MediaSession | `just_audio` + `audio_session` |
| iOS | AVFoundation / AVAudioPlayer | `just_audio` + `audio_session` |

**Decision:** `just_audio` for all platforms. `audio_session` for lock-screen controls and audio focus. `audio_waveforms` for waveform visualization.

### 3.3 Image Loading & Caching

| Platform | Implementation | Flutter Unified |
|---|---|---|
| Desktop | CSS background / img tag | `cached_network_image` |
| Android | Glide 4.16 | `cached_network_image` |
| iOS | SDWebImage + WebP/SVG coders | `cached_network_image` + `flutter_svg` |

**Decision:** `cached_network_image` for network images. `flutter_svg` for SVG QR codes. For WebP: Flutter natively supports WebP on Android; iOS uses `extended_image`.

### 3.4 QR Scanning

| Platform | Implementation | Flutter Unified |
|---|---|---|
| Desktop | jsqr (JavaScript, from camera/screenshot) | `mobile_scanner` |
| Android | ZXing + zxing-android-embedded | `mobile_scanner` |
| iOS | AVFoundation QR scanner | `mobile_scanner` |

**Decision:** `mobile_scanner` (uses ZXing on Android, AVFoundation on iOS, camera on desktop).

### 3.5 QR Display

| Platform | Implementation | Flutter Unified |
|---|---|---|
| Desktop | SVG rendered from core RPC | `qr_flutter` or `flutter_svg` with SVG string |
| Android | AndroidSVG rendering SVG from core | `qr_flutter` or `flutter_svg` |
| iOS | Generated from core SVG string | `qr_flutter` or `flutter_svg` |

**Decision:** Core provides SVG string from `getChatSecurejoinQrCodeSvg`. Use `flutter_svg` to render directly; no need for `qr_flutter` to regenerate.

### 3.6 WebXDC Mini-App Runtime

| Platform | Implementation | Flutter Unified |
|---|---|---|
| Desktop | Electron WebView / iframe with JS bridge | `flutter_inappwebview` |
| Android | Sandboxed WebView with JS interface | `flutter_inappwebview` |
| iOS | WKWebView with custom URL scheme + content rules | `flutter_inappwebview` |

**Decision:** `flutter_inappwebview` provides WKWebView on iOS, WebView on Android. Implement:
1. Custom URL scheme handler for `webxdc://` to serve .xdc zip contents
2. JavaScript channel for `window.webxdc` API (`sendUpdate`, `setUpdateListener`, `sendRealtimeData`, `sendToChat`)
3. Content rules to block all external network requests
4. Inject webxdc-js bridge script on page load

### 3.7 File Sharing / Receive

| Platform | Implementation | Flutter Unified |
|---|---|---|
| Desktop | Drag-and-drop + file open dialog | `desktop_drop` + `file_picker` |
| Android | System share sheet (ShareActivity intent) | `receive_sharing_intent` |
| iOS | Share Extension (NSExtension) | `receive_sharing_intent` + native extension |

**Decision:** `file_picker` for proactive selection. `receive_sharing_intent` for incoming shares. `desktop_drop` for drag-and-drop on desktop.

### 3.8 Push Notifications

| Platform | Implementation | Flutter Unified |
|---|---|---|
| Desktop | OS notifications via Electron/Tauri | `flutter_local_notifications` |
| Android | FCM (gplay) + polling (foss) | `firebase_messaging` + `flutter_local_notifications` |
| iOS | APNS + NSE extension | `firebase_messaging` + `flutter_local_notifications` |

**Decision:** `firebase_messaging` handles FCM (Android) and APNS (iOS) token registration. Call `dc_accounts_set_push_device_token(token)` after receiving token. `flutter_local_notifications` for displaying notifications on all platforms. Desktop: `flutter_local_notifications` with OS notification backend.

**Token format for Android FCM:** `fcm-{appId}:{rawToken}`

### 3.9 Secure Storage (DB Passphrase)

| Platform | Implementation | Flutter Unified |
|---|---|---|
| Desktop | Safestore / OS keychain | `flutter_secure_storage` |
| Android | AndroidKeyStore AES-GCM | `flutter_secure_storage` |
| iOS | Keychain Services (shared group) | `flutter_secure_storage` with `iOptions.groupId` |

**Decision:** `flutter_secure_storage` everywhere. On iOS, configure `IOSOptions.groupId` to `group.chat.omega.messenger` for persistence across reinstalls.

### 3.10 Navigation / Routing

| Platform | Implementation | Flutter Unified |
|---|---|---|
| Desktop | ScreenController enum, DialogContext, React state | `go_router` with ShellRoute |
| Android | Activity stack (ConversationList → Conversation → Profile) | `go_router` |
| iOS | TabBarController (QR/Chats/Settings) + UINavigationController | `go_router` with StatefulShellRoute |

**Decision:** `go_router` with `StatefulShellRoute` for 3 persistent tabs (Chats / QR / Settings). Deep links handled via `GoRouter.redirect`. Chat detail pushed onto Chats branch stack.

### 3.11 Location Streaming

| Platform | Implementation | Flutter Unified |
|---|---|---|
| Desktop | WebXDC map (experimental) | `geolocator` + WebXDC map integration |
| Android | GmsLocationSource (gplay) or PlatformLocationSource (foss) | `geolocator` |
| iOS | CLLocationManager | `geolocator` |

**Decision:** `geolocator` package provides unified GPS API. Stream coordinates to `setLocation` RPC. Display via integrated WebXDC map app.

### 3.12 Video/Audio Calls (WebRTC)

| Platform | Implementation | Flutter Unified |
|---|---|---|
| Desktop | WebRTC in Electron window, custom call UI | `flutter_webrtc` |
| Android | im.conversations.webrtc:webrtc-android, PiP, CallActivity | `flutter_webrtc` + `flutter_callkit_incoming` |
| iOS | WebRTC-lib pod, CallKit, PushKit, PiP | `flutter_webrtc` + `flutter_callkit_incoming` |

**Decision:** `flutter_webrtc` for peer connection, signaling via DeltaChat core messages. `flutter_callkit_incoming` for platform native call UI (CallKit on iOS, ConnectionService on Android). Incoming call notification via high-priority FCM/VoIP push.

---

## SECTION 4 — ENTERPRISE FEATURES (COMBINED FROM ALL PLATFORMS)

All enterprise features ranked by cross-platform presence and enterprise relevance.

| Feature | Priority | Platforms | Flutter Implementation |
|---|---|---|---|
| **Multi-account with private tags** | P1 | A+iO+D | Account model includes `privateTag` field; display in account switcher |
| **BCC-self / multi-device sync** | P1 | ALL | `setConfig('bcc_self', '1')` toggle in settings |
| **Force E2EE encryption** | P1 | ALL | `setConfig('force_encryption', '1')` |
| **Encrypted SQLite DB (passphrase)** | P0 | ALL | `flutter_secure_storage` → pass passphrase to core |
| **Multiple IMAP/SMTP transports** | P1 | D+A+iO | Transport list UI + CRUD RPC calls |
| **Proxy support (SOCKS5/HTTP/Shadowsocks)** | P1 | ALL | `setConfig('proxy_url', url)` per account |
| **QR-based proxy import** | P1 | A+D | `checkQr` returns Qr.Proxy type |
| **Screen security (no screenshots)** | P2 | A+D | `flutter_windowmanager.addFlags(FLAG_SECURE)` |
| **Screen lock / biometric auth** | P2 | A | `local_auth` package |
| **Incognito keyboard** | P2 | A | TextInputType.visiblePassword or platform channel |
| **Certificate check policy per transport** | P1 | A+iO | Strict / accept-all setting in EditTransport |
| **OpenPGP key export/import** | P2 | A+D | `exportSelfKeys` / `importSelfKeys` RPC |
| **Auto-delete messages (device + server timer)** | P1 | ALL | `delete_device_after` and `delete_server_after` config |
| **Download-on-demand (size limit)** | P1 | ALL | `download_limit` config: 40KB/160KB/640KB/2.5MB/10MB/no-limit |
| **Notification privacy levels** | P1 | ALL | Settings: full / sender-only / none |
| **FOSS build (no Google Services)** | P2 | A | Build flavor without `firebase_messaging` |
| **Verified groups (SecureJoin)** | P1 | ALL | `setChatProtection`, SecureJoin flow |
| **Backup encryption (passphrase)** | P1 | A+iO | Passphrase field in export/import backup dialog |
| **Self-hosted chatmail server support** | P1 | ALL | Server URL picker in instant onboarding |
| **Sync all accounts (background IO)** | P1 | D+A | `startIo` for all accounts, not just selected |
| **allowBackup=false** | P0 | A | AndroidManifest.xml attribute |
| **Content protection flag** | P2 | D | Desktop: window flag to prevent capture |
| **Anonymous stats opt-in** | P3 | A | CONFIG_STATS_SENDING, explicit opt-in |
| **PanicKit integration** | P3 | A | GuardianProject panic responder; platform channel |
| **GDPR compliance architecture** | P0 | W+ALL | No server, no contact upload, all data local — document in privacy policy |
| **Encryption V2 UX (simplified security indicators)** | P1 | D (2025) | Remove lock icons from E2EE messages; only show warnings when NOT encrypted |
| **Transport unpublished flag** | P2 | A+D | Secondary emails not advertised in Autocrypt headers |

---

## SECTION 5 — RECOMMENDED FLUTTER PACKAGES BY FEATURE AREA

### 5.1 Core Engine Binding

```yaml
# deltachat-core-rust binding
# Option A (recommended): spawn deltachat-rpc-server subprocess, communicate via stdio JSON-RPC
# Option B: dart:ffi + flutter_rust_bridge for direct FFI
flutter_rust_bridge: ^2.x  # If FFI path chosen
```

**JSON-RPC client pattern:**
- Spawn `deltachat-rpc-server` binary as subprocess
- Communicate via stdin/stdout with JSON-RPC 2.0
- Background Dart isolate reads stdout stream, dispatches events to StreamControllers
- All RPC calls are async with correlation IDs

### 5.2 State Management

```yaml
flutter_riverpod: ^2.6.1       # DI + reactive state
riverpod_annotation: ^2.6.1    # Code generation
riverpod_generator: ^2.6.1     # dev dep
```

**Provider structure:**
- `AccountsProvider` — list of all accounts, selected account ID
- `ChatListProvider(accountId)` — paginated chat list for account
- `ChatProvider(accountId, chatId)` — full chat details
- `MessageListProvider(accountId, chatId)` — paginated message list
- `ContactProvider(accountId, contactId)` — single contact
- `SettingsProvider(accountId)` — account + desktop settings
- `EventStreamProvider(accountId)` — raw DC event stream from core

### 5.3 Navigation

```yaml
go_router: ^14.6.3
```

**Route tree:**
```
/ (shell with account sidebar)
  /welcome            — onboarding
  /account/:id        — account shell
    /chats            — chat list
      /:chatId        — chat view
        /profile      — contact/group profile
        /media        — gallery
        /info/:msgId  — message info
    /qr               — QR scan/show
    /settings         — settings navigator
      /profile
      /chats-media
      /notifications
      /appearance
      /advanced
        /transports
        /proxy
        /log
```

**Deep links:**
```
openpgp4fpr:...    → /account/:id/qr (securejoin)
dcaccount:...      → /welcome (account QR onboarding)
dclogin:...        → /welcome (login QR)
socks5://...       → /account/:id/settings/advanced/proxy
ss://...           → /account/:id/settings/advanced/proxy
https://i.delta.chat/... → /account/:id/qr (group join)
mailto:...         → /account/:id/chats (new contact)
```

### 5.4 UI & Chat Components

```yaml
# Chat UI base (or build custom)
flutter_chat_ui: ^2.x          # Optional: pre-built chat bubble system

# Emoji
emoji_picker_flutter: ^3.1.3

# Audio waveform
audio_waveforms: ^1.0.5        # Replace audioplayers for waveform display

# Virtualized lists (built-in Flutter — no extra package needed)
# ListView.builder / CustomScrollView + SliverList

# Markdown in messages (optional)
flutter_markdown: ^0.7.x       # Or custom InlineSpan parsing

# Link detection
flutter_linkify: ^6.x

# Photo/image viewer
photo_view: ^0.15.0
# or: InteractiveViewer (built-in)

# Fullscreen media with prev/next
# PageView (built-in) + photo_view per page

# Chat background
# BoxDecoration with image or color (no package needed)

# Swipe actions in chat list
flutter_slidable: ^3.1.1

# Badge counts
badges: ^3.1.2

# Time formatting
timeago: ^3.7.0
```

### 5.5 Media & Files

```yaml
# File picking
file_picker: ^8.3.7

# Image/video picking from gallery + camera
image_picker: ^1.1.2

# Image cropping (avatars)
image_cropper: ^8.x

# Image caching
cached_network_image: ^3.4.1
extended_image: ^9.x           # For better WebP/SVG/GIF support

# SVG rendering (QR codes from core)
flutter_svg: ^2.0.17

# Video playback
video_player: ^2.9.3
# or: media_kit + media_kit_video  (better desktop support)
media_kit: ^1.x
media_kit_video: ^1.x

# Audio recording
record: ^5.2.2

# Audio playback
just_audio: ^0.9.43
audio_session: ^0.1.21         # Audio focus + lock screen controls

# Audio waveform
audio_waveforms: ^1.0.5

# Open files with OS default app
open_file: ^3.x

# Drag and drop (desktop)
desktop_drop: ^0.4.x

# Save images to device gallery
gal: ^2.x                      # Cross-platform gallery save (replaces gallery_saver)
```

### 5.6 Camera / QR

```yaml
# QR scanning
mobile_scanner: ^6.x

# QR display (SVG preferred; use flutter_svg with SVG from core)
qr_flutter: ^4.1.0             # Fallback if SVG not available
flutter_svg: ^2.0.17           # Primary: render SVG from getChatSecurejoinQrCodeSvg
```

### 5.7 Notifications & Background

```yaml
# Notifications
flutter_local_notifications: ^18.0.1
firebase_messaging: ^15.2.5
firebase_core: ^3.13.0

# App badge count
flutter_app_badger: ^1.x
# or: app_badge_plus  (newer, cross-platform)

# Background tasks (Android WorkManager / iOS BGAppRefreshTask)
workmanager: ^0.5.x

# Call notifications (iOS CallKit + Android ConnectionService)
flutter_callkit_incoming: ^2.x
```

### 5.8 Security & Storage

```yaml
# Secure key storage
flutter_secure_storage: ^9.2.4

# Biometric / screen lock
local_auth: ^2.3.x

# Screen recording prevention
flutter_windowmanager: ^0.3.x  # Android FLAG_SECURE; iOS via platform channel

# Permissions
permission_handler: ^11.4.0
```

### 5.9 Networking & Connectivity

```yaml
# HTTP (for chatmail instance list, webxdc store)
dio: ^5.8.0

# Network status
connectivity_plus: ^6.1.4
```

### 5.10 WebXDC & WebView

```yaml
# WebView for WebXDC mini-apps and HTML email / connectivity
flutter_inappwebview: ^6.x

# Or simpler WebView for one-way content:
webview_flutter: ^4.x
```

### 5.11 Calls (WebRTC)

```yaml
# WebRTC peer connection
flutter_webrtc: ^0.x

# Native call UI (CallKit iOS / ConnectionService Android)
flutter_callkit_incoming: ^2.x
```

### 5.12 Location

```yaml
# GPS coordinates
geolocator: ^13.x

# Map display (via WebXDC map app, but optionally native)
flutter_map: ^7.x              # If native map needed outside WebXDC
```

### 5.13 Desktop-Specific

```yaml
# System tray
tray_manager: ^0.2.x

# Auto-start on login
launch_at_startup: ^0.3.x

# Window management
window_manager: ^0.4.x

# Drag and drop files
desktop_drop: ^0.4.x

# Keyboard shortcuts
# Use Flutter's built-in Shortcuts + Actions widgets
```

### 5.14 Sharing & Receiving

```yaml
# Receive files/text from other apps (Android intents / iOS share extension)
receive_sharing_intent: ^2.x

# Share content to other apps
share_plus: ^10.1.4

# URL launching
url_launcher: ^6.3.1
```

### 5.15 Localization

```yaml
flutter_localizations:         # Built-in Flutter package
  sdk: flutter
intl: ^0.20.2
```

**Language support:** 40+ languages from DeltaChat translations. Use `flutter gen-l10n` with `.arb` files. Map Transifex strings to Flutter l10n format.

### 5.16 Utilities

```yaml
# Serialization / code generation
freezed_annotation: ^2.4.4
json_annotation: ^4.9.0
freezed: ^2.5.7               # dev
json_serializable: ^6.9.4     # dev

# Crypto (for fingerprint display, not core crypto which is in Rust)
pointycastle: ^3.9.1          # Only if needed for UI-side crypto display

# Unique IDs
uuid: ^4.5.1

# Date/time
intl: ^0.20.2

# Logging
logger: ^2.5.0

# Package / device info
package_info_plus: ^8.3.0
device_info_plus: ^11.4.0
```

---

## SECTION 6 — IMPLEMENTATION PRIORITY ORDER

### P0 — Critical (App Unusable Without)

These must be implemented before any testing or QA. Target: **Sprint 1-2**.

1. **DeltaChat core RPC binding** — JSON-RPC subprocess or FFI; event loop isolate
2. **Account creation (instant onboarding)** — chatmail signup, display name entry
3. **Account creation (manual IMAP/SMTP)** — email + password entry + test connection
4. **Database encryption** — flutter_secure_storage passphrase on account open
5. **Chat list** — fetch, render, real-time updates via events
6. **Chat view** — message list (reverse scroll, infinite load), day markers
7. **Text message send/receive** — composer, sendMessage RPC
8. **Message status indicators** — sending/sent/delivered/read/failed
9. **Image message send/receive** — image_picker + display in bubble
10. **File message send/receive** — file_picker + filename display
11. **Go Router setup** — all routes, deep link handlers, tab navigation
12. **Riverpod providers** — AccountsProvider, ChatListProvider, MessageListProvider
13. **Push notifications setup** — firebase_messaging init, token registration with core
14. **Notification display** — flutter_local_notifications with tap-to-open-chat
15. **Network reconnect** — connectivity_plus → maybeNetwork on reconnect

### P1 — Important (Must Be Complete Before Public Release)

Target: **Sprint 3-6**.

**Messaging Core:**
16. Voice message record + send + playback
17. Audio message playback (waveform)
18. Video message send + playback
19. Reply-to-quote (message quoting)
20. Message reactions (bar + picker + detail sheet)
21. Message context menu (full 10-action menu)
22. Message forwarding (chat picker)
23. Message editing (own messages)
24. Message deletion (for-me + for-everyone)
25. Message multiselect (bulk forward/delete)
26. Message info screen (delivery status per contact)
27. Draft persistence per chat

**Groups & Contacts:**
28. Create group chat (encrypted + unencrypted)
29. Group management (add/remove members, name, avatar, leave)
30. Group QR code invite
31. Contact profile screen
32. Block/unblock contact
33. Contact request accept/block
34. Contact search in new-chat flow
35. vCard send/receive

**QR & Security:**
36. QR scanner UI (mobile_scanner)
37. QR display (flutter_svg with SVG from core)
38. SecureJoin flow (contact + group join via QR)
39. Encryption info dialog (per contact + per chat)
40. SecureJoin verified badge

**Settings:**
41. Settings screen with all categories
42. Self-profile edit (name, avatar, status)
43. Appearance settings (light/dark/system theme)
44. Notification settings (privacy levels, per-chat mute)
45. Read receipts toggle (MDN)
46. BCC-self toggle
47. Auto-delete settings
48. Download-on-demand limit

**Media & Files:**
49. Fullscreen image viewer (photo_view)
50. Fullscreen video player
51. Per-chat media gallery (tabs: images/video/audio/files)
52. Save media to device gallery

**Backup & Multi-device:**
53. Export backup to file
54. Import backup from file
55. QR-based multi-device transfer

**Infrastructure:**
56. Multi-account switcher UI
57. Connectivity status banner
58. Connectivity details screen (WebView with HTML from core)
59. Proxy settings (SOCKS5/HTTP)
60. Transport list (add/edit/delete/set-default)
61. Log viewer (in-app)
62. Ephemeral messages timer per chat
63. Broadcast channels (create, join, leave)
64. Saved messages / self-talk
65. WebXDC mini-app rendering (sandboxed WebView + JS bridge)
66. WebXDC thumbnail in chat bubble
67. Localization (at minimum: EN, DE, ES, FR, PT, RU, ZH)
68. RTL layout support

**Platform-specific P1:**
69. iOS: NSE (Notification Service Extension) for background fetch
70. iOS: CallKit (flutter_callkit_incoming) for call UI
71. iOS: VoIP push (PushKit) for incoming calls
72. iOS: Share extension (receive_sharing_intent)
73. Android: FCM background service
74. Android: Inline reply from notification
75. Android: Share target (receive_sharing_intent)
76. Android: Boot receiver for background sync restart
77. Desktop: Two-pane layout (LayoutBuilder >= 720dp)
78. Desktop: NavigationRail account sidebar
79. Desktop: Drag-and-drop files (desktop_drop)

### P2 — Nice to Have (v1.x Point Releases)

Target: **post-launch sprints**.

80. Sticker picker (local packs from filesystem)
81. Emoji shortcode / text-to-emoji in composer
82. Message search within chat
83. Message jump (from search result, from reply tap)
84. Private reply in groups
85. Chat background wallpaper (per-account or per-chat)
86. Mailing list read-only view
87. Location streaming (via WebXDC map)
88. WebXDC app store browser
89. WebXDC realtime data channel
90. HTML email rendering (WebView)
91. Video transcoding before send (flutter_ffmpeg or platform channel)
92. Image scribble/draw editor before send
93. QR for proxy config (socks5:/ss: scheme)
94. Multiple notification sounds / per-chat sounds
95. Mention-only notification mode
96. Global sync all accounts (background IO for non-selected)
97. FOSS build flavor (no Firebase; WorkManager polling)
98. Screen security / prevent screenshots
99. Biometric screen lock
100. Incognito keyboard (Android)
101. OpenPGP key import/export
102. Force encryption toggle
103. Desktop: System tray with badge
104. Desktop: Minimize to tray
105. Desktop: Keyboard shortcuts (Ctrl+N, Ctrl+F, etc.)
106. Desktop: WebXDC in separate window
107. iOS: Picture-in-Picture video call
108. iOS: App Groups for NSE data sharing
109. Desktop/iOS/Android: WebRTC video/audio calls
110. App icon badge (flutter_app_badger)
111. About dialog (version, build info, licenses)
112. Keybinding cheat sheet (desktop)
113. Zoom level for WebXDC (desktop)
114. Custom theme colors
115. Outgoing media quality setting (standard/worse)
116. Full 40+ language localization
117. Stats opt-in (anonymous telemetry)
118. Encryption V2 UX (simplified security indicators, no lock on E2EE)

### P3 — Future / Platform Stretch

Target: **v2.0+**.

119. Desktop: Autostart on login
120. Desktop: WebXDC developer tools
121. Desktop: RC_Config flags (devmode, etc.)
122. Desktop: Keybinding remapping
123. iOS: App Clip (i.delta.chat)
124. iOS: WidgetKit home-screen widget
125. iOS: Siri/Shortcuts call intent
126. Android: PanicKit integration
127. Android: Wear OS remote reply
128. Android: Direct share shortcuts
129. PWA / Flutter Web (requires server-side core; defer)
130. Iroh-based P2P realtime (advanced WebXDC)
131. Bot detection badge UI
132. Zero metadata mode (future core feature)

---

## SECTION 7 — DATA MODELS (UNIFIED DART)

All models should be generated via `freezed` + `json_serializable` from the JSON-RPC schema.

```dart
// Core unified models for Omega

// Account
@freezed
class Account with _$Account {
  const factory Account.configured({
    required int id,
    required String addr,
    String? displayName,
    String? profileImage,
    required int color,
    String? privateTag,  // enterprise: Work, Family, etc.
  }) = ConfiguredAccount;
  
  const factory Account.unconfigured({
    required int id,
  }) = UnconfiguredAccount;
}

// Chat (FullChat from RPC)
@freezed
class Chat with _$Chat {
  const factory Chat({
    required int id,
    required String name,
    required int color,
    String? profileImage,
    required ChatType chatType,
    required List<int> contactIds,
    required int freshMessageCounter,
    required bool isPinned,
    required bool isArchived,
    required bool isMuted,
    required bool isEncrypted,
    required bool canSend,
    required bool selfInGroup,
    required bool isContactRequest,
    required bool isSelfTalk,
    required bool isDeviceChat,
    required bool wasSeenRecently,
    int? ephemeralTimer,
    String? mailingListAddress,
    int? lastUpdatedTimestamp,
  }) = _Chat;
}

enum ChatType { single, group, mailingList, inBroadcast, outBroadcast }

// Message
@freezed
class Message with _$Message {
  const factory Message({
    required int id,
    required int chatId,
    required int fromId,
    String? text,
    required ViewType viewType,
    String? file,
    String? fileName,
    int? fileBytes,
    int? dimensionsWidth,
    int? dimensionsHeight,
    required int timestamp,
    required bool isForwarded,
    required bool isEdited,
    required bool isInfo,
    MessageQuote? quote,
    Reactions? reactions,
    int? savedMessageId,
    int? originalMsgId,
    VcardContact? vcardContact,
    String? webxdcHref,
    MessageState state,
    SystemMessageType? systemMessageType,
    Contact? sender,
  }) = _Message;
}

enum ViewType { text, image, video, gif, audio, voice, file, sticker, webxdc, vcard, videochatInvitation, webxdcInfoMessage }
enum MessageState { undefined, outPreparing, outDraft, outPending, outFailed, outMdnRcvd, inFresh, inNoticed, inSeen }

// MessageListItem — union type
@freezed
class MessageListItem with _$MessageListItem {
  const factory MessageListItem.message(Message message) = MessageItem;
  const factory MessageListItem.dayMarker(int timestamp) = DayMarkerItem;
}

// Contact
@freezed
class Contact with _$Contact {
  const factory Contact({
    required int id,
    required String displayName,
    required String authName,
    required String address,
    required int color,
    String? profileImage,
    required bool isVerified,
    required bool isBot,
    required bool isBlocked,
    int? lastSeen,
    String? status,
  }) = _Contact;
}

// Reactions
@freezed
class Reactions with _$Reactions {
  const factory Reactions({
    required Map<String, List<String>> reactionsByContact,  // contactId -> [emoji]
    required List<Reaction> reactions,
  }) = _Reactions;
}

@freezed
class Reaction with _$Reaction {
  const factory Reaction({
    required String emoji,
    required int count,
    required bool isFromSelf,
  }) = _Reaction;
}

// QR result — discriminated union
@freezed
class QrResult with _$QrResult {
  const factory QrResult.askVerifyContact(int contactId, String fingerprint) = QrAskVerifyContact;
  const factory QrResult.askVerifyGroup(int contactId, String groupName, String fingerprint) = QrAskVerifyGroup;
  const factory QrResult.askJoinBroadcast(int contactId, String broadcastName) = QrAskJoinBroadcast;
  const factory QrResult.account(String address) = QrAccount;
  const factory QrResult.backup2(String authToken) = QrBackup2;
  const factory QrResult.webrtcInstance(String domain, String json) = QrWebrtcInstance;
  const factory QrResult.proxy(String url) = QrProxy;
  const factory QrResult.addr(int contactId, String address) = QrAddr;
  const factory QrResult.url(String url) = QrUrl;
  const factory QrResult.text(String text) = QrText;
  const factory QrResult.fprOk(int contactId) = QrFprOk;
  const factory QrResult.fprMismatch(int contactId) = QrFprMismatch;
  const factory QrResult.login(String address) = QrLogin;
}

// Settings
@freezed
class AccountSettings with _$AccountSettings {
  const factory AccountSettings({
    required String configuredAddr,
    String? displayName,
    String? selfStatus,
    required bool mdnsEnabled,
    required bool bccSelf,
    int? deleteDeviceAfter,
    int? deleteServerAfter,
    int? downloadLimit,
    bool? forceEncryption,
    int? mediaQuality,
    required bool isChatmail,
    required WhoCanCallMe whoCanCallMe,
  }) = _AccountSettings;
}

@freezed
class AppSettings with _$AppSettings {
  const factory AppSettings({
    required ThemeMode themeMode,
    String? chatViewBgImg,
    required bool enterKeySends,
    required String locale,
    required NotificationSettings notifications,
    bool? showNotificationContent,
    required bool syncAllAccounts,
    bool? contentProtectionEnabled,
  }) = _AppSettings;
}

enum WhoCanCallMe { everybody, contacts, nobody }
```

---

## SECTION 8 — CORE RPC INTEGRATION ARCHITECTURE

### 8.1 Event Loop (replace DcEventCenter / DcEventEmitter)

```dart
// Background isolate: reads events from core subprocess
// Dispatches to StreamController per account per event type

class DcEventBus {
  final Map<int, StreamController<DcEvent>> _controllers = {};
  
  Stream<DcEvent> eventsFor(int accountId) =>
    _controllers.putIfAbsent(accountId, () => StreamController.broadcast()).stream;
  
  // Riverpod provider consumes this:
  Stream<DcEvent> filteredEvents(int accountId, DcEventType type) =>
    eventsFor(accountId).where((e) => e.type == type);
}

// Key events to handle:
// IncomingMsg        → invalidate MessageListProvider, show notification
// MsgsChanged        → invalidate MessageListProvider
// ChatModified       → invalidate ChatProvider
// ContactsChanged    → invalidate ContactProvider
// WebxdcStatusUpdate → push to WebXDC WebView JS bridge
// ImexFileWritten    → update backup progress
// ProgressBar        → update operation progress
// ConnectivityChanged → update connectivity banner
// IncomingReaction   → show reaction notification, update message
// ConfigSynced       → refresh settings
// AccountsChanged    → refresh account list
```

### 8.2 RPC Method Categories

**Account lifecycle:** `getAllAccountIds`, `addAccount`, `removeAccount`, `getAccountInfo`, `selectAccount`, `startIo`, `stopIo`, `getSelectedAccountId`

**Config:** `getConfig`, `setConfig`, `batchSetConfig`

**Chat CRUD:** `getFullChatById`, `getChatListIds`, `getChatListItemsByEntries`, `createGroupChat`, `createGroupChatUnencrypted`, `createBroadcast`, `setChatVisibility`, `setChatMuteDuration`, `getChatEphemeralTimer`, `setChatEphemeralTimer`, `marknoticedChat`, `markSeenMessages`, `acceptChat`, `blockChat`, `deleteChatAndMessages`, `setGroupName`, `setGroupImage`, `setChatDescription`, `getChatDescription`

**Messages:** `getMessageListItems`, `getMessage`, `getMessages`, `sendMessage`, `sendEditRequest`, `saveDraft`, `getDraft`, `removeDraft`, `deleteMessages`, `forwardMessages`, `sendReaction`, `getMessageInfo`, `searchMessages`, `messageIdsToSearchResults`, `getMessageHtml`

**Contacts:** `getAllContactIds`, `createContact`, `getContact`, `getContacts`, `blockContact`, `unblockContact`, `getBlockedContacts`, `getContactEncryptionInfo`, `getChatEncryptionInfo`, `changeContactName`, `makeVcard`, `parseVcard`, `importVcard`, `addContactToChat`, `removeContactFromChat`, `getChatContacts`

**Media:** `getChatMedia`

**WebXDC:** `getWebxdcInfo`, `sendWebxdcStatusUpdate`, `getWebxdcStatusUpdates`, `sendWebxdcRealtimeAdvertisement`, `sendWebxdcRealtimeData`, `leaveWebxdcRealtime`, `setWebxdcIntegration`, `initWebxdcIntegration`, `getWebxdcBlob`, `getHttpResponse`

**QR:** `checkQr`, `setConfigFromQr`, `getChatSecurejoinQrCodeSvg`, `getSecurejoinQrCodeSvg`, `secureJoinContact`, `joinSecurejoin`

**Backup:** `exportBackup`, `importBackup`, `provideBackup`, `getBackup`, `getBackupQr`

**Calls:** `placeOutgoingCall`, `acceptIncomingCall`, `endCall`, `getMsgById` (for call type), `getWebrtcOfferAndStart`, `getWebrtcStationOffer`, `getWebrtcAnswer`, `setWebrtcAnswer`, `iceServers`

**Transport:** `listTransportsEx`, `addOrUpdateTransport`, `deleteTransport`, `setDefaultTransport`

**Location:** `setLocation`, `getLocations`, `deleteAllLocations`

**Keys:** `exportSelfKeys`, `importSelfKeys`

**Proxy:** via `setConfig`/`getConfig` with `proxy_url`, `proxy_enabled` keys

**Provider:** `getProviderFromEmail`

**Push:** `setPushDeviceToken`

**Connectivity:** `maybeNetwork`, `getConnectivity`, `getConnectivityHtml`

**Log:** `getNextErrorEntry`, via log file path

---

## SECTION 9 — NAVIGATION & LAYOUT ARCHITECTURE

### 9.1 Responsive Layout Strategy

```
Screen width < 600dp (phone portrait)
  → Single pane
  → BottomNavigationBar: Chats | QR | Settings
  → Chat list fills screen
  → Chat view pushed as new route

Screen width 600-1200dp (tablet, large phone landscape)
  → Two pane: ChatList (left, ~320dp) + ChatView (right, rest)
  → NavigationRail on left edge: Account avatars
  → BottomNavigationBar replaced by NavigationRail

Screen width > 1200dp (desktop, large tablet)
  → Three pane: AccountSidebar + ChatList + ChatView
  → NavigationRail (72dp) for accounts
  → Fixed-width ChatList panel (320dp)
  → ChatView fills remaining space
```

### 9.2 Account Sidebar (Desktop)

- `NavigationRail` with `NavigationRailDestination` per account
- Account avatar + unread badge
- Drag-to-reorder via `ReorderableListView`
- "Add account" button at bottom
- Settings gear at bottom

### 9.3 Dialog Strategy

Use Flutter's native dialog system:
- `showDialog` → AlertDialog for simple confirmations
- `showModalBottomSheet` → for pickers, action sheets (mobile)
- `showGeneralDialog` → for full-screen modals (gallery, profile)
- `Navigator.push` with `MaterialPageRoute` → for full-screen sub-screens
- Custom `Overlay` → for context menus positioned near message

---

## SECTION 10 — LOCALIZATION STRATEGY

**Source:** DeltaChat Transifex translations (same string keys used by all platforms)

**Flutter approach:**
1. Export DeltaChat strings as `.arb` files (one per language)
2. Run `flutter gen-l10n` to generate type-safe `AppLocalizations` class
3. Use `flutter_localizations` package for built-in widget translations
4. Support RTL via `Directionality` widget (Arabic, Hebrew, etc.)

**Priority languages (P1):** English, German, Spanish, French, Portuguese, Russian, Chinese Simplified, Turkish, Italian, Dutch, Polish

**Full language list (P2):** + Catalan, Czech, Basque, Galician, Indonesian, Slovak, Albanian, Ukrainian, + 25 more from Transifex

**String key mapping:** DeltaChat uses `strings.xml` (Android) and `.strings` (iOS) with similar key names. Map these to unified `.arb` keys.

---

## SECTION 11 — TESTING STRATEGY

### Unit Tests (lib/...)
- RPC client JSON serialization/deserialization
- Data model fromJson/toJson round-trips
- Provider state transitions
- QR result parsing
- Message list pagination logic

### Widget Tests
- ChatListItem rendering (various states: muted, pinned, contact-request, etc.)
- Message bubble rendering (all ViewTypes)
- Composer state transitions (empty → text → recording)
- Settings screens

### Integration Tests
- Full onboarding flow (instant + manual)
- Send/receive text message (test account pair)
- Group create + member add
- Backup export + import round-trip
- QR contact exchange (SecureJoin)

### Platform Tests
- iOS: NSE delivery, CallKit incoming call
- Android: FCM background delivery, inline reply
- Desktop: Drag-and-drop file, keyboard shortcuts, tray icon

---

## SECTION 12 — OPEN QUESTIONS & DECISIONS NEEDED

1. **Core binding method:** JSON-RPC subprocess vs dart:ffi + flutter_rust_bridge. Subprocess is simpler and matches Desktop/Android approach. FFI is faster but requires maintaining Dart bindings. **Recommendation:** subprocess JSON-RPC first, migrate to FFI later.

2. **Web target:** deltachat-core-rust cannot run in WASM (2025 state). Flutter Web target would require a server-side core proxy. **Decision:** Defer Flutter Web to v2.0; focus on Android/iOS/Desktop for v1.0.

3. **Video transcoding:** Android Java implementation uses MP4 reencoding. Flutter equivalent needs either `flutter_ffmpeg` (large binary) or a platform channel to native transcoder. **Decision:** Skip transcoding in P0; add native platform channel in P2.

4. **Encryption V2 UX:** 2025 updates remove lock icons from E2EE messages (they're always E2EE). Show warning icons only when NOT encrypted. **Decision:** Implement V2 model from the start — no green locks on encrypted messages, red warning on unencrypted.

5. **NSE for iOS:** Notification Service Extension must be a native Swift target alongside the Flutter app. It shares data via App Group (`group.chat.omega.messenger`). This is a separate Xcode target, not Flutter code. **Decision:** Include in v1.0 iOS build.

6. **WidgetKit:** Native Swift WidgetKit target. Flutter code runs in app; widget reads from shared UserDefaults. **Decision:** P3 (post-launch).

7. **PanicKit:** Android-only, niche security feature (GuardianProject ecosystem). **Decision:** P3.

8. **Sticker storage location:** Core provides `miscGetStickers` returning `{collection: [paths]}`. Flutter needs to read from core blob directory. Use `path_provider` + core blob dir path. **Decision:** implement as P2 feature.

9. **App name:** "Omega" throughout — no Delta Chat branding in UI. Core RPC version headers may still say "Delta Chat"; this is fine as it's internal.

10. **Min SDK targets:** Android 21 (confirmed), iOS 14 (confirmed from IMPLEMENTATION.md), macOS 12+, Windows 10+.
