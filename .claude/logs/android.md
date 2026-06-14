# Android Platform Analysis Log

## Status: Analysis Complete

**Platform:** Android
**App Version:** 2.52.0
**Min SDK:** 21 | **Target SDK:** 36
**Primary Language:** Java (no Kotlin)
**Analysis Date:** 2026-06-14

---

## Tech Stack (Source)

| Layer | Technology |
|---|---|
| Language | Java (primary, no Kotlin) |
| Native core | deltachat-core-rust via JNI (libdeltachat.so) |
| RPC bridge | JSON-RPC over FFI: chat.delta.rpc.Rpc, BaseRpcTransport, FFITransport |
| JSON | Jackson ObjectMapper (jackson-databind 2.11.1) |
| UI framework | AndroidX / Material Components 1.12 |
| Image loading | Glide 4.16.0 (animated GIF + SVG support) |
| Audio/Video playback | ExoPlayer (legacy) + Media3 1.8.0 |
| VoIP/Video calls | WebRTC — im.conversations.webrtc:webrtc-android:129.0.0 |
| Push notifications | Firebase Messaging 24.1.2 (gplay flavor only) |
| Location (gplay) | Google Play Services Location 21.3.0 |
| Location (foss) | Standard Android LocationManager (PlatformLocationSource) |
| QR scanning | ZXing + zxing-android-embedded |
| Database encryption | AndroidKeyStore (AES-GCM) via DatabaseSecretProvider |
| File sharing | SafeContentResolver + FileProvider |
| Background tasks | WorkManager (WebxdcGarbageCollectionWorker, FetchWorker) |
| Build | MultiDex, ProGuard/R8 minification, NDK 27 (.so strip) |
| Product flavors | foss (no Google services, F-Droid), gplay (FCM + GMS) |
| SVG rendering | AndroidSVG |
| Emoji | androidx.emoji2 |
| Telecom routing | androidx.core.telecom (CallEndpointCompat) |
| Panic integration | GuardianProject PanicKit |

---

## All Screens/Activities

### Root / Launcher
- **ConversationListActivity** — main chat list screen with search bar and FAB (root/launcher screen)
- **WelcomeActivity** — onboarding screen shown when no account is configured (scan QR, manual setup, restore backup)

### Chat List & Navigation
- **ConversationListFragment** — RecyclerView of chat list items with swipe-to-archive and search
- **ConversationListArchiveActivity** — archived chats screen
- **ConversationListRelayingActivity** — chat picker for forwarding/sharing

### Conversation / Messages
- **ConversationActivity** — single chat screen host
- **ConversationFragment** — message list with input panel, swipe-to-reply, context menu
- **ConversationItem (sent/received)** — bubble with thumbnail, document, audio, sticker, vcard, webxdc views
- **ConversationUpdateItem** — system/info messages (day markers, group events)
- **ConversationTitleView** — chat title bar with avatar, name, online status
- **ConversationInputPanel** — compose bar with attachment, mic, emoji, send buttons
- **QuoteView** — reply preview bubble in composer and in message
- **MicrophoneRecorderView** — recording UI with waveform and timer
- **RecentPhotoViewRail** — horizontal strip of recent photos above keyboard
- **AttachmentTypeSelector** — bottom sheet for camera/gallery/file/contact/location/webxdc

### Media
- **MediaPreviewActivity** — full-screen media viewer with zoom and nav
- **AllMediaActivity** — tabbed media gallery (images/videos/documents) per chat
- **ScribbleActivity** — image editor with draw/text/sticker tools
- **StickerSelectActivity** — sticker set browser

### Profile & Contacts
- **ProfileActivity** — contact/group/self profile with avatar, info rows, shared media
- **ProfileFragment** — rows: avatar, name, email, status, encryption, shared media, calls
- **BlockedContactsActivity** — list of blocked contacts
- **AttachContactActivity** — vCard attachment picker

### Group / Chat Creation
- **GroupCreateActivity** — create group with member picker and name/image
- **NewConversationActivity** — new chat with contact search and QR invite
- **ContactSelectionListFragment** — contact picker with search
- **ContactMultiSelectionActivity** — multi-contact picker for groups/broadcasts

### Onboarding & Account Setup
- **InstantOnboardingActivity** — DCACCOUNT/DCLOGIN QR onboarding flow
- **CreateProfileActivity** — set display name and avatar after account creation
- **RegistrationQrActivity** — account registration QR

### QR Code
- **QrActivity** — scan/show QR tabs
- **QrScanFragment** — camera QR scanner
- **QrShowFragment** — display own QR code as SVG
- **QrShowActivity** — show contact/group QR

### Backup & Transfer
- **BackupTransferActivity** — backup via QR/iroh-net (provider + receiver fragments)

### Calls
- **CallActivity** — full-screen VoIP/video call with PiP, mic/cam toggle, audio device picker
- **AudioDevicePickerDialog** — earpiece/speaker/bluetooth selector during call

### WebXDC
- **WebxdcActivity** — WebView host for webxdc mini-apps
- **WebxdcStoreActivity** — webxdc app store

### Help / Debug
- **LocalHelpActivity** — local HTML help viewer
- **ConnectivityActivity** — IMAP/SMTP connectivity HTML report
- **LogViewActivity / LogViewFragment** — debug log viewer
- **FullMsgActivity** — full HTML message viewer

### Settings
- **ApplicationPreferencesActivity** — settings screen host (fragment container)
- **AppearancePreferenceFragment** — theme (light/dark/system) + chat background
- **NotificationsPreferenceFragment** — notification sound/vibrate/LED/privacy/priority
- **ChatsPreferenceFragment** — read receipts, enter-to-send, compression, auto-download, auto-delete, backup
- **AdvancedPreferenceFragment** — log, transports, proxy, BCC-self, location streaming, screen lock, incognito keyboard, stats
- **RelayListActivity / EditRelayActivity** — transport email accounts list and editor
- **ProxySettingsActivity** — SOCKS5/SS proxy list and toggle
- **ChatBackgroundActivity** — wallpaper picker (color or image)

### Utility / Share
- **ShareActivity** — system share target (forward to chat)
- **SearchFragment** — global message and contact search results

### Dialogs / Fragments
- **ReactionsDetailsFragment** — who reacted and with what emoji
- **MuteDialog** — mute duration picker
- **EphemeralMessagesDialog** — disappearing message timer picker
- **AccountSelectionListFragment** — multi-account switcher dialog

### Custom View Components
- **AvatarView / AvatarImageView** — circular avatar with generated letter fallback
- **DeliveryStatusView** — sent/delivered/read tick indicators
- **ConversationItemFooter** — timestamp + delivery status row
- **AudioView** — playback controls with waveform
- **DocumentView** — document attachment with icon and filename
- **WebxdcView** — webxdc mini-app thumbnail card
- **VcardView** — vCard contact preview
- **SearchToolbar** — animated search bar
- **SendButton** — morphs between mic and send states

---

## Navigation Architecture

| Flow | Path |
|---|---|
| Default launch | ConversationListActivity (root) |
| No account | WelcomeActivity shown |
| Main back stack | ConversationList -> ConversationActivity -> ProfileActivity -> AllMediaActivity |
| QR flow | ConversationList -> QrActivity (tabs: scan/show) -> handler dispatches to verify/join/proxy/backup |
| Onboarding | WelcomeActivity -> InstantOnboardingActivity (dcaccount:/dclogin:) or RegistrationQrActivity or BackupTransferActivity |
| Settings | ApplicationPreferencesActivity hosts preference fragments via fragment replacement |
| Call | CallActivity as singleTask with separate task affinity for PiP |
| Share | ShareActivity (system share sheet) -> ConversationListRelayingActivity |
| Deep links | openpgp4fpr: -> ConversationListActivity (QR handler); https://i.delta.chat -> ConversationListActivity; ss:/socks5: -> ProxySettingsActivity; dcaccount:/dclogin: -> InstantOnboardingActivity |
| Account switch | AccountSelectionListFragment dialog from ConversationList toolbar |
| Webxdc | ConversationItem tap -> WebxdcActivity (fullscreen webview) |
| Media | Thumbnail tap -> MediaPreviewActivity; toolbar icon -> AllMediaActivity |
| New chat | FAB in ConversationList -> NewConversationActivity -> ConversationActivity |
| Group create | NewConversationActivity or GroupCreateActivity -> ConversationActivity |

---

## All Features

### Messaging & Chat
- Multi-account management (add, remove, select, reorder accounts)
- Email-based end-to-end encrypted messaging over IMAP/SMTP
- Multiple transports per account (multiple email addresses as sending channels)
- 1:1 and group chats (encrypted protected groups and unencrypted ad-hoc groups)
- Broadcast channels (send-only one-to-many chats)
- Message types: text, image, GIF, video, audio, voice, file/document, sticker, vCard, webxdc, call
- Message quoting/reply
- Message reactions (emoji reactions with per-contact breakdown)
- Message editing (send_edit_request)
- Message forwarding (within account and cross-account)
- Message deletion (local and for all)
- Message saving/starring (saveMsgs)
- Draft messages
- Message read receipts (optional)
- Ephemeral/disappearing messages (timer per chat)
- Message download state (partial/full download control)
- Message search (full-text across chats or per-chat)

### Contacts & Verification
- SecureJoin / verified contact protocol via QR code (contact verification and group joining)
- QR code scan and show for: contact invite, group join, broadcast channel join, account setup, backup transfer, proxy config, WebRTC instance, fingerprint verification
- Contact management: create, block, unblock, delete, rename, import/export vCard
- vCard contact attachment sending and parsing
- Bot detection flag on contacts and messages
- Encryption info per chat and per contact

### Chat Organization
- Archived chats
- Pinned chats
- Muted chats (duration-based)
- Chat visibility controls (archived, pinned, normal)
- Chat background wallpaper customization per-account

### Calls & Media
- VoIP and video calls (WebRTC, picture-in-picture, audio device picker)
- Location sharing / streaming (real-time GPS location sent to chat)
- Webxdc mini-apps (web apps inside chat messages, with status updates and realtime data)
- Webxdc store (browse and install webxdc apps)
- Integrated maps webxdc for location display
- Media gallery (images/videos/documents per-chat or global)
- Image editor / scribble (draw, add stickers to images before sending)
- Sticker picker and sticker sets
- Audio recording and playback with waveform
- Video recording/transcoding (MP4 re-encoding before send)

### Backup & Connectivity
- Backup export/import (encrypted, file or QR-based transfer via iroh-net)
- Connectivity monitoring screen (IMAP/SMTP status, HTML report)
- Proxy support: SOCKS5, Shadowsocks (ss://) via URL scheme
- Relay/transport list management (add/edit/delete email transports via QR or manual)

### Notifications & Background
- Multiple notification channels per account-chat with inline reply, mark-read action
- FCM push notifications (gplay) and polling fallback (foss)
- Background fetch with WorkManager and foreground service
- In-chat notification sounds
- Notification privacy levels (no content / sender only / full preview)
- Mention-only notification mode

### Security & Privacy
- Screen lock / incognito keyboard option
- Panic button response (GuardianProject PanicKit integration)
- OpenPGP key import/export
- Auto-delete messages (device-side timer)
- BCC-self / multi-device sync toggle
- Stats sending opt-in

### OS Integration
- Direct share shortcuts to chats
- System share-sheet integration (receive files/text from other apps)
- mailto: URL scheme handling
- openpgp4fpr: URL scheme for QR contact verification
- dcaccount:/dclogin: URL scheme for instant onboarding
- i.delta.chat deep link for verified group joining
- Boot receiver to restart background sync after reboot
- Wear OS remote reply support
- Samsung multi-window support
- Emoji picker integration (androidx.emoji2)
- Network state monitoring for connectivity-aware reconnect

---

## Data Models

### Accounts
- **Account** — discriminated union by 'kind': Configured (id, addr, displayName, color, profileImage, privateTag) | Unconfigured (id)

### Chats
- **FullChat** — id, name, chatType, isEncrypted, archived, pinned, isMuted, isSelfTalk, isDeviceChat, isContactRequest, isUnpromoted, canSend, selfInGroup, ephemeralTimer, freshMessageCounter, contactIds, pastContactIds, profileImage, color, mailingListAddress, wasSeenRecently
- **BasicChat** — id, name, chatType, color, profileImage
- **ChatListItemFetchResult** — chat list item data (summary text, timestamp, unread count, etc.)
- **ChatType enum** — Single, Group, Broadcast, MailingList
- **ChatVisibility enum** — Normal, Archived, Pinned

### Messages
- **Message** — id, chatId, fromId, text, viewType, file, fileMime, fileName, fileBytes, dimensionsWidth, dimensionsHeight, duration, timestamp, sortTimestamp, receivedTimestamp, state, isInfo, isForwarded, isBot, isEdited, showPadlock, hasHtml, hasLocation, downloadState, quote, reactions, sender, systemMessageType, vcardContact, webxdcHref, error, overrideSenderName, parentId, originalMsgId, savedMessageId, infoContactId, subject
- **MessageData** — outgoing message builder (text, file, viewType, quotedMessageId, location, etc.)
- **MessageQuote** — id, text, authorDisplayName, authorAddress, viewType, file
- **MessageListItem** — discriminated union: Message | DayMarker
- **MessageLoadResult** — result wrapper for bulk message fetch
- **MessageNotificationInfo** — notification preview data
- **MessageInfo** — delivery details including read receipts
- **MessageReadReceipt** — contactId, timestamp, state
- **MessageSearchResult** — id, chatId, authorId, summary
- **Viewtype enum** — Text, Image, Gif, Sticker, Audio, Voice, Video, File, Call, Webxdc, Vcard, Unknown
- **DownloadState enum** — Done, Available, Failure, InProgress, Undecided
- **EphemeralTimer** — timer values enum
- **SystemMessageType enum**

### Contacts
- **Contact** — id, address, name, displayName, nameAndAddr, status, color, profileImage, isBlocked, isBot, isVerified, isKeyContact, e2eeAvail, verifierId, wasSeenRecently, lastSeen, authName
- **VcardContact** — parsed vCard fields

### Location & Reactions
- **Location** — accountId, chatId, contactId, latitude, longitude, accuracy, timestamp, independent
- **Reaction** — emoji, isFromSelf
- **Reactions** — reactions list, reactionsByContact map
- **MuteDuration** — mute duration enum

### Authentication & Config
- **EnteredLoginParam** — addr, password, imapHost, imapPort, imapSecurity, smtpHost, smtpPort, smtpSecurity, certificate
- **EnteredCertificateChecks enum**
- **Socket enum** — Automatic, Ssl, Starttls, Plain
- **ProviderInfo** — email provider metadata
- **TransportListEntry** — param, isUnpublished
- **NotifyState enum** — Connected, Disconnected, NotSupported

### QR
- **Qr discriminated union** — AskVerifyContact, AskVerifyGroup, AskJoinBroadcast, FprOk, FprMismatch, FprWithoutAddr, Account, Backup2, BackupTooNew, WebrtcInstance, Proxy, Addr, Url, Text, WithdrawVerify*, ReviveVerify*, Login

### Calls & WebXDC
- **CallInfo / CallState**
- **WebxdcMessageInfo** — name, summary, document, sourceCodeUrl, icon
- **HttpResponse**
- **SecurejoinSource / SecurejoinUiPath**

### Events
- **EventType** — discriminated union (50+ event types: IMAP/SMTP, messages, chats, contacts, location, webxdc, calls, accounts)
- **Event** — accountId, type: EventType

### JNI Wrappers (legacy, alongside JSON-RPC)
- **DcMsg** — id, chatId, fromId, toId, text, type/viewtype, file, fileMime, fileName, mediaW, mediaH, duration, timestamp, state, isInfo, isForwarded, hasDeviatingTimestamp, summaryText
- **DcChat** — id, name, type, isVerified, profileImage, color
- **DcContact** — id, name, nameAndAddr, addr, status, isBlocked, isVerified, profileImage, color
- **DcAccounts** — accountList, selectedAccount

### UI / Database
- **ThreadRecord** — database model for chat list items
- **SearchResult** — contacts + messages

---

## API Integrations

| Integration | Purpose | Flavor |
|---|---|---|
| deltachat-core-rust JSON-RPC (FFI) | All messaging, account, chat, contact, location, webxdc, call ops via libdeltachat.so | both |
| IMAP/SMTP | Handled entirely inside deltachat-core-rust | both |
| Firebase Cloud Messaging (FCM) | Push: FcmReceiveService registers token, receives push, triggers FetchForegroundService | gplay only |
| Google Play Services Location (GMS) | GPS via GmsLocationSource | gplay only |
| Standard Android LocationManager | GPS via PlatformLocationSource | foss only |
| WebRTC signaling | Via core RPC (rpc.iceServers), media via im.conversations.webrtc | both |
| iroh-net | Inside core for backup QR transfer (getBackupQr, getBackup, provideBackup) | both |
| WebXDC JS bridge | sendStatusUpdate, getStatusUpdates, sendRealtimeData in sandboxed WebView | both |
| ZXing | QR scanning via zxing-android-embedded | both |
| Glide | Image loading/caching including animated GIF and SVG | both |
| AndroidSVG | SVG rendering for QR codes | both |
| androidx.core.telecom | CallEndpointCompat for audio device routing in calls | both |
| androidx.media3 + ExoPlayer | Audio/video playback with MediaSessionService for lock-screen controls | both |
| GuardianProject PanicKit | Panic button app integration (info.guardianproject.panic.action.TRIGGER) | both |
| SafeContentResolver | Secure file sharing, prevents Surreptitious Sharing attacks | both |
| FileProvider | Secure file URI for sharing attachments and logs | both |
| WorkManager | Periodic WebxdcGarbageCollectionWorker, FetchWorker for background sync | both |
| Android Keystore (AES-GCM) | DatabaseSecretProvider stores encrypted database key | both |

---

## Enterprise / Security Features

- **Multi-account support** — unlimited accounts, reorderable, each with private tag (e.g. Work, Family)
- **Account private tag** — CONFIG_PRIVATE_TAG for profile labeling in multi-account scenarios
- **Multiple transport/relay addresses** — add_or_update_transport, list_transports per account
- **Transport unpublished flag** — secondary emails not advertised to contacts (for gradual migration)
- **BCC-self / multi-device sync** — mirrors sent messages to all devices via IMAP Sent folder
- **Force encryption config** — CONFIG_FORCE_ENCRYPTION: require E2EE on all chats
- **Proxy support** — SOCKS5, Shadowsocks (ss://) with QR-configurable proxy import
- **Screen security** — FLAG_SECURE to block screenshots
- **Incognito keyboard** — InputType flag to prevent keyboard learning
- **PanicKit integration** — respond to external panic-button apps (hooks for locking app)
- **Screen lock** — system credential authentication required to open app (ScreenLockUtil)
- **Stats opt-in** — CONFIG_STATS_SENDING, anonymous telemetry
- **OpenPGP key import/export** — exportSelfKeys, importSelfKeys with passphrase
- **Backup encryption** — passphrase-encrypted export/import
- **SecureJoin verified groups** — cryptographic contact verification before group membership
- **Encryption info** — getChatEncryptionInfo, getContactEncryptionInfo per contact and chat
- **Auto-delete messages** — device-side and server-side timer, estimateAutoDeletionCount
- **Notification privacy levels** — hide message content and/or sender from lock-screen
- **No analytics SDKs** — WebView metrics opted out, no Firebase Analytics
- **allowBackup=false** — in manifest, prevents Android backup of app data
- **hasFragileUserData=true** — system warns before uninstall
- **FOSS flavor** — zero Google dependencies, pure open-source build for F-Droid

---

## Flutter Implementation Notes

### Core Engine
- Use deltachat-core-rust as a native library via flutter_ffi or a Dart FFI plugin wrapping the same JSON-RPC interface used by the Android app (chat.delta.rpc.Rpc).
- The entire messaging stack lives in Rust. Flutter is purely a UI layer. No messaging logic belongs in Dart.

### Event Loop
- Implement a background Dart isolate that calls rpc.getNextEventBatch() in a loop and dispatches EventType subtypes to StreamControllers or Riverpod/BLoC providers.
- This replaces DcEventCenter.

### Message List
- Use a CustomScrollView with SliverList and a virtual/paging approach since getMessageListItems returns MessageListItem (Message | DayMarker).
- Day markers are already provided by the API — no need to compute them in Dart.

### Chat List
- getChatlistEntries + getChatlistItemsByEntries pattern — fetch IDs then batch-fetch items.
- Use chatlistChanged / chatlistItemChanged events to invalidate cache selectively.

### Attachments
- All file paths come from core blob dir. Use path_provider to locate blobs, open_file or share_plus for OS-level opening.
- No separate attachment database needed.

### Audio
- Recording: use flutter_sound or record package. Voice messages require OGG/Opus format matching what core expects for Viewtype.Voice.
- Playback: use just_audio + audio_session for background playback with lock-screen controls (replaces AudioPlaybackService / Media3).

### Video
- Playback: use video_player or media_kit.
- Transcoding (VideoRecoder.java) will need a platform channel or a Dart-side FFmpeg wrapper.

### Image Editor / Scribble
- Implement with CustomPainter or use packages like painting_board.
- Needed for pre-send image annotation.

### QR
- Scanning: use mobile_scanner (camera QR scan).
- Display: qr_flutter for QR SVG from rpc.getChatSecurejoinQrCodeSvg.

### WebRTC Calls
- Use flutter_webrtc. Signal via core RPC: placeOutgoingCall, acceptIncomingCall, endCall, iceServers.
- CallActivity PiP: use pip_view or platform channel for Android PiP.

### WebXDC
- Embed a WebView (webview_flutter) running the webxdc .xdc zip file with a JS bridge for sendStatusUpdate / setUpdateListener / sendRealtimeData.
- Core provides blob access via getWebxdcBlob.

### Location
- Use geolocator package for GPS. Replaces both GmsLocationSource and PlatformLocationSource.
- Stream coords to rpc.setLocation, subscribe to LocationChanged events.

### Push Notifications
- Use firebase_messaging for Android/iOS (gplay flavor).
- Token prefix must match 'fcm-{appId}:{rawToken}' format used by core's setPushDeviceToken.
- FOSS build: make FCM optional via dart-define/flavor. Use WorkManager via workmanager package for background fetch when no FCM.

### Local Notifications
- flutter_local_notifications for message and call notifications.
- Use person API equivalent for messaging style. Inline reply via android notification actions.

### Multi-Account
- Each account is a separate DcContext (integer account ID).
- Account switcher UI shows configured accounts from getAllAccounts(). Current account stored in selected_account.

### Security & Crypto
- Use flutter_secure_storage to store the database secret (replaces AndroidKeyStore + DatabaseSecretProvider).
- Pass passphrase to core when opening accounts.
- Use flutter_windowmanager to set FLAG_SECURE on Android, or use a platform channel call for screen security.

### Theme & Appearance
- Implement light/dark/system theme.
- Chat background: color or image (stored as file path in core config or SharedPreferences).

### Navigation & Deep Links
- Use go_router with deep link handling for: openpgp4fpr:, dcaccount:, dclogin:, ss:, socks5:, https://i.delta.chat URL schemes.

### Backup
- Use file_picker to let user choose export destination.
- rpc.exportBackup / rpc.importBackup handle the actual work.
- Backup QR transfer uses iroh-net inside core — expose via rpc.provideBackup / rpc.getBackup.

### Stickers
- rpc.miscGetStickers returns {collectionName: [paths]}.
- Display in grid picker. Save via rpc.miscSaveSticker.

### Reactions
- Display emoji reaction bar below message.
- Tap to add/toggle via rpc.sendReaction.
- Long-press shows per-contact breakdown (ReactionsDetailsFragment equivalent).

### Search
- Debounced input calls rpc.searchMessages then rpc.messageIdsToSearchResults.
- Display combined contacts + messages list.

### Ephemeral Messages
- Chat settings dialog uses rpc.setChatEphemeralTimer with EphemeralTimer enum values.

### Verified Groups
- Show lock icon when FullChat.isEncrypted=true, email icon when false.
- Disable add-member / QR invite for unencrypted (ad-hoc) groups.

### vCard
- rpc.parseVcard / rpc.importVcard / rpc.makeVcard.
- Display VcardView-equivalent card widget in chat.

### Connectivity Screen
- rpc.getConnectivityHtml returns HTML — render in WebView (replaces ConnectivityActivity).

### Proxy
- rpc.setConfig(accountId, 'proxy_url', url) and rpc.setConfig(accountId, 'proxy_enabled', '1').
- UI is a simple list of proxy URLs.

### Transports (Relays)
- rpc.listTransportsEx / addOrUpdateTransport / deleteTransport.
- Each entry is an email account acting as SMTP/IMAP transport.

### Dart Code Generation
- The RPC types in chat.delta.rpc.types are auto-generated from core schema.
- Generate equivalent Dart classes using json_serializable or freezed from the same schema to keep in sync with core.

### Platform Channels Required
- AudioDevicePicker (Bluetooth/earpiece/speaker routing via TelecomManager)
- BiometricPrompt / screen lock
- FLAG_SECURE
- Notification inline-reply on older Android

---

## Key Files to Reference

| File | Purpose |
|---|---|
| `/Volumes/KRYPTIX/test2/sources/deltachat-android/build.gradle` | Gradle config: flavors, deps, SDK versions, NDK |
| `/Volumes/KRYPTIX/test2/sources/deltachat-android/src/main/AndroidManifest.xml` | Permissions, deep links, activities, receivers, services |
| `/Volumes/KRYPTIX/test2/sources/deltachat-android/src/main/java/chat/delta/rpc/Rpc.java` | JSON-RPC client over FFI — all API calls go through here |
| `/Volumes/KRYPTIX/test2/sources/deltachat-android/src/main/java/chat/delta/rpc/types/EventType.java` | All 50+ event type definitions |
| `/Volumes/KRYPTIX/test2/sources/deltachat-android/src/main/java/chat/delta/rpc/types/Message.java` | Message model with all fields |
| `/Volumes/KRYPTIX/test2/sources/deltachat-android/src/main/java/chat/delta/rpc/types/FullChat.java` | Full chat model |
| `/Volumes/KRYPTIX/test2/sources/deltachat-android/src/main/java/chat/delta/rpc/types/Contact.java` | Contact model |
| `/Volumes/KRYPTIX/test2/sources/deltachat-android/src/main/java/chat/delta/rpc/types/Account.java` | Account discriminated union (Configured/Unconfigured) |
| `/Volumes/KRYPTIX/test2/sources/deltachat-android/src/main/java/chat/delta/rpc/types/Viewtype.java` | Viewtype/message-type enum |
| `/Volumes/KRYPTIX/test2/sources/deltachat-android/src/main/java/chat/delta/rpc/types/Qr.java` | QR discriminated union with all scan result types |
| `/Volumes/KRYPTIX/test2/sources/deltachat-android/src/main/java/org/thoughtcrime/securesms/ApplicationContext.java` | App-level init: core, accounts, event center setup |
| `/Volumes/KRYPTIX/test2/sources/deltachat-android/src/main/java/org/thoughtcrime/securesms/connect/DcHelper.java` | Central helper: account access, config, notification setup |
| `/Volumes/KRYPTIX/test2/sources/deltachat-android/src/main/java/org/thoughtcrime/securesms/connect/DcEventCenter.java` | Event dispatch from core to UI — event subscription model |
| `/Volumes/KRYPTIX/test2/sources/deltachat-android/src/main/java/org/thoughtcrime/securesms/notifications/NotificationCenter.java` | Notification building, channels, inline reply |
| `/Volumes/KRYPTIX/test2/sources/deltachat-android/src/gplay/java/org/thoughtcrime/securesms/notifications/FcmReceiveService.java` | FCM push receiver (gplay flavor only) |
| `/Volumes/KRYPTIX/test2/sources/deltachat-android/src/main/java/org/thoughtcrime/securesms/ConversationActivity.java` | Chat screen host activity |
| `/Volumes/KRYPTIX/test2/sources/deltachat-android/src/main/java/org/thoughtcrime/securesms/ConversationFragment.java` | Message list, input panel, swipe-to-reply, context menu |
| `/Volumes/KRYPTIX/test2/sources/deltachat-android/src/main/java/org/thoughtcrime/securesms/ConversationListActivity.java` | Root launcher activity |
| `/Volumes/KRYPTIX/test2/sources/deltachat-android/src/main/java/org/thoughtcrime/securesms/calls/CallActivity.java` | WebRTC call UI with PiP and audio routing |
| `/Volumes/KRYPTIX/test2/sources/deltachat-android/src/main/java/org/thoughtcrime/securesms/WebxdcActivity.java` | WebXDC mini-app WebView host and JS bridge |
| `/Volumes/KRYPTIX/test2/sources/deltachat-android/src/main/java/org/thoughtcrime/securesms/WelcomeActivity.java` | Onboarding entry point |
| `/Volumes/KRYPTIX/test2/sources/deltachat-android/src/main/java/org/thoughtcrime/securesms/ProfileActivity.java` | Contact/group/self profile screen |
| `/Volumes/KRYPTIX/test2/sources/deltachat-android/src/main/java/org/thoughtcrime/securesms/geolocation/LocationStreamingService.java` | Real-time GPS location streaming to chat |
| `/Volumes/KRYPTIX/test2/sources/deltachat-android/src/main/java/org/thoughtcrime/securesms/service/PanicResponderListener.java` | GuardianProject PanicKit response handler |
| `/Volumes/KRYPTIX/test2/sources/deltachat-android/src/main/java/org/thoughtcrime/securesms/qr/QrCodeHandler.java` | Routes scanned QR types to correct actions |
| `/Volumes/KRYPTIX/test2/sources/deltachat-android/src/main/res/xml/preferences.xml` | Main settings preference definitions |
| `/Volumes/KRYPTIX/test2/sources/deltachat-android/src/main/res/xml/preferences_advanced.xml` | Advanced settings preference definitions |
| `/Volumes/KRYPTIX/test2/sources/deltachat-android/src/main/res/xml/preferences_notifications.xml` | Notification preference definitions |
| `/Volumes/KRYPTIX/test2/sources/deltachat-android/src/main/res/xml/preferences_chats.xml` | Chat preference definitions |
| `/Volumes/KRYPTIX/test2/sources/deltachat-android/src/main/java/com/b44t/messenger/DcContext.java` | JNI wrapper around DcContext (legacy, alongside JSON-RPC) |

---

## Next Steps

### Immediate (Flutter scaffolding)
1. Set up the Dart FFI plugin wrapping libdeltachat.so for Android (and equivalent for iOS).
2. Generate Dart data models from the same core JSON schema used by chat.delta.rpc.types — use freezed or json_serializable. Start with: Account, FullChat, Message, Contact, EventType, Viewtype, Qr.
3. Implement the background Dart isolate event loop calling rpc.getNextEventBatch() and broadcasting to StreamControllers.
4. Scaffold go_router navigation matching the Android back stack: ConversationList -> Conversation -> Profile -> AllMedia.

### Core Screens (Priority Order)
5. ConversationListScreen — chat list with search, FAB, account switcher.
6. ConversationScreen — message list (SliverList + paging), input panel, swipe-to-reply.
7. WelcomeScreen — onboarding (QR scan, manual setup, backup restore).
8. ProfileScreen — contact/group profile with shared media.
9. SettingsScreen — preferences (appearance, notifications, chats, advanced).

### Feature Implementation
10. Multi-account switcher UI from getAllAccounts().
11. QR scan (mobile_scanner) and QR display (qr_flutter) with full QrCodeHandler dispatch logic.
12. WebRTC call screen via flutter_webrtc with PiP platform channel.
13. WebXDC WebView host with JS bridge (sendStatusUpdate, setUpdateListener, sendRealtimeData).
14. Notification system: flutter_local_notifications with inline reply and mark-read actions.
15. FCM push integration with gplay/foss flavor split via dart-define.
16. Location streaming via geolocator -> rpc.setLocation.
17. Audio recording (OGG/Opus) + playback with waveform (just_audio).
18. Image editor/scribble (CustomPainter) for pre-send annotation.
19. Sticker picker via rpc.miscGetStickers.
20. Backup export/import with file_picker + iroh-net QR transfer.

### Security & Polish
21. flutter_secure_storage for database secret (replaces AndroidKeyStore).
22. FLAG_SECURE via flutter_windowmanager or platform channel.
23. Screen lock via BiometricPrompt platform channel.
24. PanicKit integration via platform channel.
25. FOSS flavor: zero Google deps build with WorkManager fallback polling.
26. Deep link registration for all URL schemes: openpgp4fpr:, dcaccount:, dclogin:, ss:, socks5:, https://i.delta.chat.
27. Proxy settings UI (rpc.setConfig proxy_url / proxy_enabled).
28. Transport/relay list UI (rpc.listTransportsEx / addOrUpdateTransport / deleteTransport).
