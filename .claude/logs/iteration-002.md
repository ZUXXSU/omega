# Loop Iteration 002 — Phase 5: Providers, QR, Group Creation

**Date:** 2026-06-14
**Phase:** 5 — Platform Implementation

## What Was Done

### DeltaChat RPC Abstraction Layer
Created `lib/core/network/delta_rpc_client.dart`:
- Full JSON-RPC interface abstraction (swappable: dev-mode / real RPC process / WebSocket)
- Dev mode: in-memory seeded state (accounts, chats, messages, contacts)
- Methods: getAllAccountIds, getAccountInfo, addAccount, configureAccount, selectAccount, startIo
- Chat: getChatListIds, getChatInfo, createChatByContactId, createGroupChat, addContactToChat
- setChatVisibility, setChatMuteDuration, marknoticedChat, deleteChat
- Messages: getMessages, sendTextMessage, sendFileMessage, deleteMessage, markSeenMessages
- Contacts: getContacts, getContactInfo, createContact, blockContact, unblockContact, deleteContact
- QR: getQrCode, checkQr, continueKeyTransfer
- Config: getConfig, setConfig
- Riverpod provider: `deltaRpcClientProvider`

### Auth Provider (`auth_provider.dart`)
- AuthStatus enum: unknown, unauthenticated, configuring, authenticated, error
- Checks initial account state on build (reads all account IDs, starts IO)
- loginWithCredentials: addAccount → configureAccount → selectAccount → startIo
- loginWithQr: checkQr → auto-provision if qr_account type
- logout: clears storage, resets state
- Derived providers: `currentAccountProvider`, `isAuthenticatedProvider`

### Chat List Provider (`chat_list_provider.dart`)
- Loads all chats and archived chats on build
- Pins sorted first (visibility=2), then by last_message_time desc
- Methods: refresh, search, pinChat, unpinChat, archiveChat, unarchiveChat, muteChat, unmuteChat, markRead, deleteChat
- Derived: `totalUnreadCountProvider`

### Chat Provider (`chat_provider.dart`)
- Per-chatId provider: `chatMessagesProvider(chatId)`
- Paginates messages (50/page), loadMore() for infinite scroll
- sendText: optimistic update with tempId → replace with real ID on success, mark failed on error
- sendFile: same optimistic pattern, supports image/video/audio/file
- Reply support: setReply(messageId, text) / clearReply()
- deleteMessage, refresh

### Contacts Provider (`contacts_provider.dart`)
- Loads contacts and blocked contacts on build
- search(), addContact(), blockContact(), unblockContact(), deleteContact()
- Derived: `contactByIdProvider(contactId)` — single contact async lookup

### Settings Provider (`settings_provider.dart`)
- AppSettings immutable value class with all settings fields
- Loads from RPC config + SharedPreferences on build
- update() persists to RPC + SharedPreferences simultaneously
- toggle(key) helper for boolean settings

### QR Scanner (`qr_scanner_screen.dart`)
- MobileScanner controller with duplicate detection
- 4 modes: contact, groupInvite, accountLogin, backup
- Parses QR type from checkQr response → routes to correct confirmation dialog
- Verify contact dialog, Join group dialog, Account login dialog, Backup transfer dialog
- Custom overlay painter with corner brackets + dark mask
- Flash toggle, camera flip

### QR Display (`qr_display_screen.dart`)
- qr_flutter QrImageView with branded colors (blue eyes, dark modules)
- FutureBuilder → loads QR from RPC
- Share as text via share_plus
- Works for both contact QR and group invite QR

### Group Create (`group_create_screen.dart`)
- 2-tab layout: Members picker + Settings
- Members tab: checkbox list with selected contacts shown as horizontal avatar strip
- Settings tab: group name + photo (tap to change) + verified group toggle
- Verified group: shows informational banner about QR-only membership
- Creates group via RPC, adds each selected member, navigates to the new chat

### Router Updates
- Added routes: `/qr` (scanner with mode param), `/qr-display` (display), `/group/create`
- Added packages: mobile_scanner, qr_flutter, shared_preferences, image_cropper

## Files Created: 9

## Next Iteration Goals
- Isar database schema for offline-first caching
- Voice message recording + playback (record + audioplayers)
- File/image/video sharing (file_picker + image_picker)
- Message search
- Typing indicators
- Disappearing messages timer UI
- Background sync service
