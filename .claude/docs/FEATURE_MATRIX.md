# Omega — Platform Feature Matrix

Cross-platform implementation guide. Each feature shows which platform has an existing implementation and what the unified Flutter approach is.

Legend: D = Desktop (Electron/React), A = Android (Kotlin/Java), iO = iOS (Swift), W = Web/PWA (deferred v2.0), ALL = all platforms.

---

## Section 1 — Core Features (ALL Platforms, P0/P1)

### Account Management
| Sub-feature | D | A | iO | Flutter |
|---|---|---|---|---|
| Add account (instant chatmail) | Y | Y | Y | `addAccount` RPC + chatmail HTTP fetch |
| Add account (manual IMAP/SMTP) | Y | Y | Y | Form + `setConfig` RPC |
| Remove account | Y | Y | Y | `removeAccount` RPC |
| Switch account | Y | Y | Y | `selectAccount` RPC + StateNotifier |
| Account display name + avatar | Y | Y | Y | `setDisplayname` + `setProfileImage` |
| Account color hash | Y | Y | Y | `getContact(self)` color field |
| Account list reordering | Y | Y | Y | ReorderableListView |
| QR-scan account setup | Y | Y | Y | `checkQr` → `addAccount` from QR |
| Backup import | Y | Y | Y | `importBackup` RPC |

### Onboarding
| Sub-feature | D | A | iO | Flutter |
|---|---|---|---|---|
| Welcome screen (two paths) | Y | Y | Y | WelcomeScreen → InstantRoute / ManualRoute |
| Chatmail instance list (HTTP) | Y | Y | Y | `http.get` chatmail directory |
| Auto-create chatmail account | Y | Y | Y | `addAccount` + `setConfig` |
| ProviderInfo banner | Y | Y | Y | Fetch provider DB JSON from DeltaChat CDN |
| Advanced server settings | Y | Y | Y | Collapsible form (IMAP/SMTP host/port/security) |
| Restore from backup file | Y | Y | Y | `importBackup` + file_picker |
| QR-based second-device transfer | Y | Y | Y | Show QR (sender) → scan (receiver) |
| Self-hosted chatmail server picker | Y | partial | partial | URL field in instant onboarding |

### Chat List
| Sub-feature | D | A | iO | Flutter |
|---|---|---|---|---|
| Virtualized list | Y | Y | Y | ListView.builder + `getChatListIds` |
| Avatar, name, preview, timestamp | Y | Y | Y | ChatListItemWidget |
| Unread badge | Y | Y | Y | `getChatListItemsByEntries` unread count |
| Muted/pin icons | Y | Y | Y | Chat flags from RPC |
| Contact-request badge | Y | Y | Y | `isSendingLocations` / contactRequest flag |
| Archive chat | Y | Y | Y | `setChatVisibility(Archived)` |
| Pin chat | Y | Y | Y | `setChatVisibility(Pinned)` |
| Mute chat | Y | Y | Y | `setChatMuteDuration` |
| Mark read / unread | Y | Y | Y | `markNoticedChat` / `markSeenMessages` |
| Delete chat | Y | Y | Y | `deleteChat` |
| Swipe-to-archive | Y | Y | Y | `flutter_slidable` |
| Global search (chats/contacts/messages) | Y | Y | Y | `searchMessages` + `queryContacts` RPCs |

### Chat View
| Sub-feature | D | A | iO | Flutter |
|---|---|---|---|---|
| Infinite-scroll reverse message list | Y | Y | Y | SliverList + `getMessageListItems` |
| Load older on scroll-to-top | Y | Y | Y | Prepend batch on scroll threshold |
| Day separators | Y | Y | Y | Provided by core in message list items |
| Sent bubble (right) | Y | Y | Y | MessageBubble alignment |
| Received bubble (left) | Y | Y | Y | MessageBubble alignment |
| Sender avatar + name (groups) | Y | Y | Y | Contact fetch per senderId |
| Delivery status icons | Y | Y | Y | MessageState enum → icon |
| Contact-request sticky banner | Y | Y | Y | Conditional widget above input |
| Ephemeral timer icon in header | Y | Y | Y | AppBar trailing icon |
| Encryption warning in header | Y | Y | Y | Encryption V2 UX (warning only) |
| System/info messages | Y | Y | Y | InfoMessage widget (centered, gray) |
| `markSeenMessages` on open | Y | Y | Y | Called when chat view is active |

### Message Types
| Type | D | A | iO | Flutter Widget |
|---|---|---|---|---|
| Text (linkified) | Y | Y | Y | `flutter_linkify` |
| Image | Y | Y | Y | `cached_network_image` / file |
| Video | Y | Y | Y | `video_player` (or `media_kit`) |
| GIF (animated) | Y | Y | Y | `Image.file` (GIF autoplay) |
| Audio | Y | Y | Y | `just_audio` |
| Voice (waveform) | Y | Y | Y | `audio_waveforms` |
| File/Document | Y | Y | Y | File icon + `open_file` |
| Sticker | Y | Y | Y | Image (lottie or static) |
| vCard | Y | Y | Y | vCard bubble + import action |
| WebXDC | Y | Y | Y | `flutter_inappwebview` |
| Call invitation | Y | N | Y | Call bubble widget |
| System/info | Y | Y | Y | InfoMessage widget |

### Message Composition
| Sub-feature | D | A | iO | Flutter |
|---|---|---|---|---|
| Auto-expanding text field | Y | Y | Y | `TextField` maxLines: null |
| Send / mic morphing button | Y | Y | Y | AnimatedSwitcher |
| Emoji picker | Y | Y | Y | `emoji_picker_flutter` |
| Attach: image | Y | Y | Y | `image_picker` |
| Attach: video | Y | Y | Y | `image_picker` (video mode) |
| Attach: audio | Y | Y | Y | `file_picker` |
| Attach: file | Y | Y | Y | `file_picker` |
| Attach: vCard | Y | Y | Y | Contact picker → vCard export |
| Attach: WebXDC | Y | Y | Y | `file_picker` `.xdc` filter |
| Voice recording | Y | Y | Y | `record` package (hold-to-record) |
| Reply-to-quote | Y | Y | Y | Quote bar + `sendMsg` quotedMessageId |
| Draft persistence | Y | Y | Y | `setDraft` / `getDraft` RPC |
| Paste image from clipboard | Y | partial | N | `Clipboard` API + send |
| Enter-key-sends toggle | Y | N | N | Settings preference |

### Message Actions (Context Menu)
| Action | D | A | iO | Flutter |
|---|---|---|---|---|
| Reply | Y | Y | Y | Set reply-quote + focus input |
| Forward | Y | Y | Y | Chat picker sheet + `forwardMessages` |
| Copy text | Y | Y | Y | `Clipboard.setData` |
| Copy image | Y | Y | Y | Platform clipboard image |
| React | Y | Y | Y | Reaction popover |
| Message info | Y | Y | Y | MessageInfoScreen |
| Download/save | Y | Y | Y | `gal` or `open_file` |
| Save to saved messages | Y | Y | Y | `forwardMessages` to self-chat |
| Edit own message | Y | Y | Y | `editMessage` RPC |
| Delete for me | Y | Y | Y | `deleteMessages` |
| Delete for everyone | Y | Y | Y | `deleteMessages` (for-all flag) |
| Private reply (groups) | Y | Y | Y | `createChatByContactId` + reply |
| Enter multiselect | Y | Y | Y | Long-press → multiselect mode |

### Message Reactions
| Sub-feature | D | A | iO | Flutter |
|---|---|---|---|---|
| Reaction bar below bubble | Y | Y | Y | Row of emoji chips |
| Quick-react popover (5 emoji) | Y | Y | Y | Popover widget on long-press |
| Full emoji picker for reactions | Y | Y | Y | `emoji_picker_flutter` |
| Toggle own reaction | Y | Y | Y | `sendReaction` RPC |
| Reactions detail sheet | Y | Y | Y | Bottom sheet: who reacted what |

### Group Chats
| Sub-feature | D | A | iO | Flutter |
|---|---|---|---|---|
| Create (name + avatar + members) | Y | Y | Y | `createGroupChat` + `addContactToChat` |
| Encrypted / unencrypted toggle | Y | Y | Y | `createGroupChat` protected param |
| Add / remove members | Y | Y | Y | `addContactToChat` / `removeContactFromChat` |
| Leave group | Y | Y | Y | `leaveGroup` |
| Group QR invite | Y | Y | Y | `getChatSecurejoinQrCodeSvg` |
| Member list with roles | Y | Y | Y | `getChatContacts` + role flags |
| Verified group (SecureJoin) | Y | Y | Y | `setChatProtection` |
| Group description | Y | Y | Y | `setChatDescription` |
| Admin permissions | Y | Y | Y | `setChatAdminsettings` |

### Contacts
| Sub-feature | D | A | iO | Flutter |
|---|---|---|---|---|
| Profile screen | Y | Y | Y | ContactDetailScreen |
| Create contact | Y | Y | Y | `createContact` |
| Block / unblock | Y | Y | Y | `blockContact` / `unblockContact` |
| Encryption info | Y | Y | Y | `getContactEncryptionInfo` |
| Verified badge | Y | Y | Y | `isVerified` field |
| Shared chats | Y | Y | Y | `getChatIdByContactId` |
| Edit name | Y | Y | Y | `createContact` (overwrite) |
| vCard send/receive/import | Y | Y | Y | Core vCard support |

### QR Codes
| Sub-feature | D | A | iO | Flutter |
|---|---|---|---|---|
| Show own QR (contact invite) | Y | Y | Y | `flutter_svg` renders SVG from `getQrCode` |
| QR scanner (camera) | Y | Y | Y | `mobile_scanner` |
| Handle: contact join | Y | Y | Y | `checkQr` → AskVerifyContact |
| Handle: group join | Y | Y | Y | `joinSecurejoin` |
| Handle: account setup | Y | Y | Y | `addAccount` from QR |
| Handle: backup transfer | Y | Y | Y | Core backup flow |
| Handle: proxy config | Y | Y | Y | Store proxy URL |
| Handle: channel join | Y | Y | Y | `joinSecurejoin` |

### Ephemeral Messages
| Sub-feature | D | A | iO | Flutter |
|---|---|---|---|---|
| Timer picker (off/1min…4weeks) | Y | Y | Y | `setEphemeralChatDuration` |
| Global auto-delete setting | Y | Y | Y | `delete_device_after` config |
| Timer icon in header | Y | Y | Y | AppBar icon |

### Media Gallery
| Sub-feature | D | A | iO | Flutter |
|---|---|---|---|---|
| Per-chat tabs (Images/Video/Audio/Files/Apps) | Y | Y | Y | TabBar in GalleryScreen |
| Thumbnail grid | Y | Y | Y | GridView + `cached_network_image` |
| Fullscreen viewer (zoom/pan) | Y | Y | Y | `photo_view` |
| Prev/next navigation | Y | Y | Y | PageView inside fullscreen |
| Download/save to device | Y | Y | Y | `gal` |
| Share | Y | Y | Y | `share_plus` |

### Backup & Multi-Device
| Sub-feature | D | A | iO | Flutter |
|---|---|---|---|---|
| Export .tar to file | Y | Y | Y | `exportBackup` + `file_picker` save |
| Import .tar from file | Y | Y | Y | `importBackup` + `file_picker` open |
| QR-based transfer (iroh-net) | Y | Y | Y | Core handles transport; show/scan QR |
| BCC-self toggle | Y | Y | Y | `setConfig('bcc_self', '1')` |

### Notifications
| Sub-feature | D | A | iO | Flutter |
|---|---|---|---|---|
| FCM token → core | N/A | Y | Y | `firebase_messaging` + `setConfig('device_token')` |
| Local notification display | Y | Y | Y | `flutter_local_notifications` |
| Tap → open chat | Y | Y | Y | Notification payload → go_router |
| Content privacy levels | Y | Y | Y | Settings enum → notification body |
| Per-chat mute | Y | Y | Y | `setChatMuteDuration` |
| Per-account toggle | Y | Y | Y | `setConfig` per accountId |
| App icon badge | partial | Y | Y | `flutter_app_badger` |
| Inline reply (Android) | N | Y | N | Android RemoteInput (P1) |
| Call notification | N | Y | Y | `flutter_callkit_incoming` |

### Settings
| Sub-feature | D | A | iO | Flutter |
|---|---|---|---|---|
| Profile settings | Y | Y | Y | ProfileSettingsScreen |
| Chats & Media | Y | Y | Y | ChatsSettingsScreen |
| Notifications | Y | Y | Y | NotificationSettingsScreen |
| Appearance | Y | Y | Y | AppearanceScreen |
| Advanced | Y | Y | Y | AdvancedSettingsScreen |
| All DeltaChat core configs | Y | Y | Y | `setConfig` / `getConfig` wrappers |

---

## Section 2 — Platform-Specific Features

### Desktop-Only [D]
| Feature | Flutter Impl |
|---|---|
| Two-pane layout (≥720dp) | LayoutBuilder → Row(ChatList + ChatView) |
| Three-pane layout (≥1200dp) | Row(AccountRail + ChatList + ChatView) |
| NavigationRail account sidebar | NavigationRail widget |
| System tray | `tray_manager` |
| Minimize-to-tray | `tray_manager` + `window_manager` |
| Autostart on login | `launch_at_startup` |
| Global keyboard shortcuts | `Shortcuts` widget + `Actions` |
| Drag-and-drop files | `desktop_drop` |
| Paste image from clipboard | `Clipboard` API → `sendMsg` |
| WebXDC in separate window | `window_manager` open new window |
| WebXDC developer tools | Devtools panel in WebXDC window |
| WebRTC calls | `flutter_webrtc` |
| HTML email window | `flutter_inappwebview` in dialog |
| RC_Config flags | Config keys with `ui.` prefix |

### Android-Only [A]
| Feature | Flutter Impl |
|---|---|
| FOSS build flavor (no Firebase) | Build flavor `foss`; `workmanager` polling instead |
| WorkManager background polling | `workmanager` package |
| Inline notification reply | Android RemoteInput platform channel |
| Direct share shortcuts | `ShortcutManager` platform channel |
| Share-sheet receive target | `receive_sharing_intent` |
| Wear OS remote reply | Platform channel → Wear OS API |
| PanicKit | Platform channel → GuardianProject panic |
| Incognito keyboard | `InputType.TYPE_TEXT_VARIATION_VISIBLE_PASSWORD` platform channel |
| Biometric screen lock | `local_auth` |
| Boot receiver | BroadcastReceiver in AndroidManifest → restart IO |
| FLAG_SECURE | `flutter_windowmanager.addFlags(FLAG_SECURE)` |
| FCM background fetch service | FirebaseMessagingService subclass |
| Video transcoding | MediaTranscoder platform channel |
| Image scribble editor | Canvas platform channel |
| Stats opt-in | `CONFIG_STATS_SENDING` + opt-in dialog |

### iOS-Only [iO]
| Feature | Flutter Impl |
|---|---|
| NSE (Notification Service Extension) | Native Swift Xcode target (NOT Flutter) |
| VoIP push (PushKit) | PushKit + `flutter_callkit_incoming` |
| CallKit native call UI | `flutter_callkit_incoming` |
| Share Extension | Native Xcode target + `receive_sharing_intent` |
| App Clip | Native Xcode target (P3) |
| WidgetKit widget | Native Swift target (P3) |
| Siri INStartAudioCallIntent | Platform channel (P3) |
| QuickLook preview | Platform channel |
| PiP video call | `pip_view` package |
| Keychain persistence across reinstalls | `flutter_secure_storage` `IOSOptions.groupId` |
| App Groups shared container | `group.chat.omega.messenger` in Entitlements |
| DarwinNotificationCenter | `darwin_notifications` or shared UserDefaults |
| ReachabilitySwift | `connectivity_plus` |
| State restoration | Flutter restoration framework |

### Web/PWA [W]
Status: **Deferred to v2.0**

- deltachat-core Rust is not WASM-compilable as of 2025
- Server-side core proxy would be required
- PWA manifest for thin shell is possible but not useful without core

---

## Section 3 — Features to Merge (Cross-Platform Unification)

| Feature | Desktop impl | Android impl | iOS impl | Flutter unified |
|---|---|---|---|---|
| Audio recording | lamejs (MP3) | Java AudioRecorder (OGG) | AVFoundation (M4A) | `record` package |
| Audio playback | HTML5 Audio | Media3/ExoPlayer | AVAudioPlayer | `just_audio` + `audio_session` |
| Image caching | CSS/img element | Glide 4.16 | SDWebImage | `cached_network_image` |
| QR scanning | jsqr (JS) | ZXing | AVFoundation | `mobile_scanner` |
| QR display | SVG string from core | AndroidSVG | SVG string from core | `flutter_svg` (render core SVG) |
| WebXDC runtime | Electron WebView | Android WebView | WKWebView | `flutter_inappwebview` |
| File receive (external) | Drag+drop / dialog | Share intent | Share extension | `receive_sharing_intent` + `desktop_drop` |
| Push notifications | Electron notify | FCM + WorkManager | APNS + NSE | `firebase_messaging` + `flutter_local_notifications` |
| Secure storage | OS keychain | AndroidKeyStore | iOS Keychain | `flutter_secure_storage` |
| Navigation | ScreenController enum | Activity stack | TabBarController + UINavigationController | `go_router` with StatefulShellRoute |
| Location streaming | WebXDC map (experimental) | GmsLocationSource | CLLocationManager | `geolocator` |
| WebRTC calls | Electron WebRTC (native) | webrtc-android | WebRTC-lib pod | `flutter_webrtc` + `flutter_callkit_incoming` |

---

## Section 4 — Enterprise Features

| Feature | Priority | Flutter Implementation | Status |
|---|---|---|---|
| Multi-account with private tags | P1 | `privateTag` field in Account model; display in switcher | [ ] |
| BCC-self / multi-device sync | P1 | `setConfig('bcc_self', '1')` toggle | [ ] |
| Force E2EE encryption | P1 | `setConfig('force_encryption', '1')` | [ ] |
| Encrypted SQLite DB (passphrase) | P0 | `flutter_secure_storage` → pass to core on account open | [ ] |
| Multiple IMAP/SMTP transports | P1 | Transport CRUD UI + `listTransportsEx` | [ ] |
| SOCKS5/HTTP/Shadowsocks proxy | P1 | `setConfig('proxy_url', url)` per account | [ ] |
| QR-based proxy import | P1 | `checkQr` returns `Qr.Proxy` type | [ ] |
| Screen security (no screenshots) | P2 | `flutter_windowmanager.addFlags(FLAG_SECURE)` | [ ] |
| Biometric screen lock | P2 | `local_auth` | [ ] |
| Incognito keyboard | P2 | Platform channel InputType flag | [ ] |
| Certificate check policy per transport | P1 | Strict / accept-all in EditTransport UI | [ ] |
| OpenPGP key import/export | P2 | `exportSelfKeys` / `importSelfKeys` RPC | [ ] |
| Auto-delete messages (device + server) | P1 | `delete_device_after`, `delete_server_after` config | [ ] |
| Download-on-demand size limit | P1 | `download_limit` config (40KB–10MB–unlimited) | [ ] |
| Notification privacy levels | P1 | full / sender-only / none in settings | [ ] |
| FOSS build (no Google Services) | P2 | Build flavor without `firebase_messaging` | [ ] |
| Verified groups (SecureJoin) | P1 | `setChatProtection`, securejoin flow | [ ] |
| Backup passphrase encryption | P1 | Passphrase field in export/import dialog | [ ] |
| Self-hosted chatmail server support | P1 | Server URL picker in instant onboarding | [ ] |
| allowBackup=false (Android) | P0 | `AndroidManifest.xml` attribute | [ ] |
| GDPR privacy-by-design | P0 | No central servers, no contact upload — document in privacy policy | [ ] |
| Encryption V2 UX | P1 | No lock on E2EE; only warning when NOT encrypted | [ ] |
| Sync all accounts background IO | P1 | `startIo` for all account IDs on launch | [ ] |
| Content protection flag (desktop) | P2 | Window flag to prevent screen capture | [ ] |
| Transport unpublished flag | P2 | Secondary emails not in Autocrypt headers | [ ] |
| Stats opt-in (anonymous telemetry) | P3 | `CONFIG_STATS_SENDING`, explicit user opt-in dialog | [ ] |
| PanicKit (Android) | P3 | Platform channel to GuardianProject panic responder | [ ] |

---

## Section 5 — RPC Reference (Key Methods)

### Account RPCs
- `getAllAccountIds` → `List<int>`
- `addAccount` → `int` accountId
- `removeAccount(accountId)`
- `selectAccount(accountId)`
- `startIo(accountId)` / `stopIo(accountId)` / `maybeNetwork(accountId)`

### Chat List RPCs
- `getChatListIds(accountId, {flags, queryStr, queryContactId})` → `List<int>`
- `getChatListItemsByEntries(accountId, entries)` → `Map<int, ChatListItem>`
- `setChatVisibility(accountId, chatId, visibility)` — Normal/Pinned/Archived
- `setChatMuteDuration(accountId, chatId, duration)`

### Message RPCs
- `getMessageListItems(accountId, chatId, {flags})` → `List<MessageListItem>`
- `getMessage(accountId, messageId)` → `Message`
- `markSeenMessages(accountId, messageIds)`
- `sendTextMessage(accountId, chatId, text)` → `int` messageId
- `sendMsg(accountId, chatId, MsgData)` → `int` messageId
- `forwardMessages(accountId, messageIds, chatId)`
- `deleteMessages(accountId, messageIds)`
- `editMessage(accountId, messageId, text)`

### Contact RPCs
- `getContacts(accountId, {flags, query})` → `List<int>`
- `getContact(accountId, contactId)` → `Contact`
- `createContact(accountId, email, name)` → `int` contactId
- `blockContact(accountId, contactId)` / `unblockContact`
- `getContactEncryptionInfo(accountId, contactId)` → `String`

### QR/SecureJoin RPCs
- `getQrCode(accountId, chatId?)` → `String` (SVG)
- `getChatSecurejoinQrCodeSvg(accountId, chatId)` → `String` (SVG)
- `checkQr(accountId, qrContent)` → `QrObject`
- `joinSecurejoin(accountId, qrContent)` → `int` chatId
- `setChatProtection(accountId, chatId, protect)`

### Config RPCs
- `setConfig(accountId, key, value?)`
- `getConfig(accountId, key)` → `String?`
- `setDisplayname(accountId, displayname)`
- `setProfileImage(accountId, imagePath?)`

### Backup RPCs
- `exportBackup(accountId, destdir, {passphrase})`
- `importBackup(accountId, tarfile, {passphrase})`

### Key Config Keys
- `bcc_self` — multi-device sync
- `force_encryption` — force E2EE
- `device_token` — FCM push token
- `mdns_enabled` — read receipts
- `delete_device_after` — auto-delete local
- `delete_server_after` — auto-delete server
- `download_limit` — download-on-demand size
- `proxy_url` — SOCKS5/HTTP proxy
- `show_emails` — mailing list mode
- `e2ee_enabled` — E2EE default

### Transport RPCs
- `listTransportsEx(accountId)` → `List<Transport>`
- `addTransport(accountId, TransportConfig)` → `int`
- `removeTransport(accountId, transportId)`

### Connectivity RPCs
- `getConnectivity(accountId)` → `ConnectivitySummary`
- `getConnectivityHtml(accountId)` → `String` (HTML)

### WebXDC RPCs
- `sendWebxdcStatusUpdate(accountId, messageId, json, descr)`
- `getWebxdcStatusUpdates(accountId, messageId, lastKnownSerial)` → `String` (JSON)

### Key Events (from event stream)
- `IncomingMsg(accountId, chatId, messageId)`
- `MsgsChanged(accountId, chatId, messageId)`
- `MsgDelivered(accountId, chatId, messageId)`
- `MsgRead(accountId, chatId, messageId)`
- `MsgFailed(accountId, chatId, messageId)`
- `MsgsNoticed(accountId, chatId)`
- `ChatlistChanged(accountId)`
- `ChatlistItemChanged(accountId, chatId)`
- `ContactsChanged(accountId, contactId?)`
- `ConnectivityChanged(accountId)`
- `WebxdcStatusUpdate(accountId, messageId, statusUpdateSerial)`
- `WebxdcRealtimeData(accountId, messageId, data)`
