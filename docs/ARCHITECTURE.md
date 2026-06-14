# Omega — Architecture

## Overview

Omega is a Flutter messenger that wraps DeltaChat's JSON-RPC core. The Flutter layer is responsible for UI, state management, local caching, push notification delivery, and enterprise policy enforcement. It delegates all mail transport and cryptographic operations to `deltachat-rpc-server`, a compiled Rust binary.

---

## Layered Architecture

```
┌─────────────────────────────────────────────────────────┐
│                      UI Layer                           │
│  Screens · Widgets · Theme (OmegaColors/TextStyles)     │
├─────────────────────────────────────────────────────────┤
│                 State Management Layer                  │
│  Riverpod Providers (code-gen @riverpod)                │
│  Auth · ChatList · ChatMessages · Contacts · Settings   │
├─────────────────────────────────────────────────────────┤
│                   Service Layer                         │
│  NotificationService (FCM + local)                      │
│  StorageService (SharedPrefs + SecureStorage)           │
│  OmegaDatabase (Isar offline cache)                     │
├─────────────────────────────────────────────────────────┤
│                  RPC Abstraction Layer                   │
│  DeltaRpcClient                                         │
│  dev-mode: in-memory seeded state                       │
│  production: stdio JSON-RPC 2.0 to deltachat-rpc-server │
├─────────────────────────────────────────────────────────┤
│              DeltaChat Core (Rust / FFI)                │
│  deltachat-rpc-server subprocess                        │
│  SMTP · IMAP · Autocrypt · OpenPGP E2E                  │
└─────────────────────────────────────────────────────────┘
```

---

## Feature-First Folder Structure

```
lib/
├── main.dart                        App entry point
├── app/
│   ├── app.dart                     Root widget (MaterialApp.router)
│   ├── router.dart                  go_router definition + @riverpod GoRouter
│   └── theme/
│       ├── colors.dart              OmegaColors — all color tokens
│       ├── text_styles.dart         OmegaTextStyles — all text tokens
│       └── app_theme.dart           ThemeData builders (light + dark)
├── core/
│   ├── constants/
│   │   ├── app_constants.dart       Numeric constants, pagination, media limits
│   │   └── route_constants.dart     Route path strings
│   ├── network/
│   │   └── delta_rpc_client.dart    RPC abstraction + deltaRpcClientProvider
│   ├── utils/
│   │   └── logger.dart              AppLogger (logger package wrapper)
│   ├── errors/
│   │   ├── exceptions.dart          Typed exception classes
│   │   └── failures.dart            Either<Failure,T> types (dartz)
│   ├── di/                          Dependency injection helpers
│   └── extensions/                  Dart extension methods
├── features/
│   ├── auth/
│   │   └── presentation/
│   │       ├── providers/auth_provider.dart
│   │       └── screens/             welcome, login, account_setup
│   ├── chat/
│   │   └── presentation/
│   │       ├── providers/chat_provider.dart
│   │       ├── screens/             chat_screen, message_search, group/group_create
│   │       └── widgets/             message_bubble, chat_input_bar, typing_indicator,
│   │                                voice_message_widget, day_separator,
│   │                                chat_app_bar, message_reactions
│   ├── chat_list/
│   │   └── presentation/
│   │       ├── providers/chat_list_provider.dart
│   │       └── screens/chat_list_screen.dart
│   ├── contacts/
│   │   └── presentation/
│   │       ├── providers/contacts_provider.dart
│   │       └── screens/             contacts_screen, contact_detail_screen
│   ├── enterprise/
│   │   └── presentation/
│   │       └── screens/             admin_policy_screen, multi_account_screen
│   ├── media/
│   │   └── presentation/
│   │       └── screens/media_viewer_screen.dart
│   ├── notifications/               (notification feature screens)
│   ├── onboarding/
│   │   └── presentation/
│   │       └── screens/onboarding_screen.dart
│   ├── qr/
│   │   └── presentation/
│   │       └── screens/             qr_scanner_screen, qr_display_screen
│   └── settings/
│       └── presentation/
│           ├── providers/settings_provider.dart
│           └── screens/             settings, profile, notification,
│                                    privacy, advanced
└── shared/
    ├── database/
    │   └── isar_schema.dart         Collections + OmegaDatabase singleton
    ├── models/
    │   ├── account.dart             Account (Freezed)
    │   ├── chat.dart                Chat + ChatType + ChatVisibility (Freezed)
    │   ├── contact.dart             Contact (Freezed)
    │   └── message.dart             Message + MessageType + MessageState (Freezed)
    ├── services/
    │   ├── notification_service.dart FCM integration + local notifications
    │   └── storage_service.dart     SharedPreferences + flutter_secure_storage
    └── widgets/
        ├── omega_text_field.dart
        └── omega_avatar.dart
```

All feature directories follow the same internal convention: `presentation/screens/`, `presentation/widgets/`, `presentation/providers/`. There are no `data/` or `domain/` sub-layers per feature — the DeltaRpcClient serves as the unified data source.

---

## Data Flow Diagram

```
User action
    │
    ▼
Screen widget calls provider method
    │  (e.g. chatMessages.sendText("Hello"))
    ▼
Provider (ChatMessages / ChatList / Auth / ...)
    │  reads deltaRpcClientProvider
    ▼
DeltaRpcClient method
    │  dev-mode: mutates in-memory Maps + 80ms delay
    │  production: JSON-RPC 2.0 over stdio to deltachat-rpc-server
    ▼
Raw Map<String, dynamic> response
    │
    ▼
Provider maps raw data → typed model (Message / Chat / Contact / Account)
    │  updates state via state = state.copyWith(...)
    ▼
Riverpod invalidates dependent widgets
    │
    ▼
UI rebuilds with new state
```

**Optimistic send path** (message sending):

```
sendText("Hello")
    ├── 1. Insert temp Message (id = negative timestamp, state = pending) into state
    ├── 2. Await RPC sendTextMessage(chatId, text)
    │       success → replace temp id with real id, state = sent
    │       failure → state = failed (red error indicator)
    └── 3. State update triggers bubble rebuild
```

---

## State Management Patterns

### Code-Generated Providers

All providers use `@riverpod` from `riverpod_annotation`. Never write `StateNotifierProvider` or `ChangeNotifier` manually.

```dart
@riverpod
class ChatMessages extends _$ChatMessages {
  @override
  ChatMessagesState build(int chatId) {
    _loadMessages();
    return const ChatMessagesState(isLoading: true);
  }
  // methods mutate state via state = state.copyWith(...)
}
```

Generated output: `chat_provider.g.dart`. Run `build_runner build` after any annotation change.

### State Classes

Provider state classes are plain immutable Dart classes with `copyWith`. They are not Freezed (to keep code-gen dependencies explicit). Domain models (`Message`, `Chat`, `Contact`, `Account`) use Freezed for equality, `copyWith`, and JSON serialization.

### Provider Families

Parameterized providers use the family pattern implicitly through `@riverpod` with a parameter:

```dart
@riverpod
class ChatMessages extends _$ChatMessages {
  @override
  ChatMessagesState build(int chatId) { ... }  // chatId is the family parameter
}
// Consumed as: ref.watch(chatMessagesProvider(42))
```

### Derived Providers

Read-only derived state uses `@riverpod` functions (not classes):

```dart
@riverpod
int totalUnreadCount(TotalUnreadCountRef ref) {
  return ref.watch(chatListProvider).totalUnread;
}
```

---

## Navigation Structure

Router is a Riverpod provider (`routerProvider`). `OmegaApp` watches it:

```dart
final router = ref.watch(routerProvider);
return MaterialApp.router(routerConfig: router);
```

Auth flow: `/ → /onboarding → /account-setup` (new user) or `/ → /login` (returning user without configured account). On successful auth the app navigates to `/chats`.

ShellRoute wraps `/chats`, `/contacts`, and `/settings` — these share a common layout shell (currently a passthrough but ready for bottom nav).

Modal/overlay routes (QR scanner, media viewer, group create) live outside the ShellRoute so they can be pushed over any screen.

Path parameters use `:name` syntax. Query parameters are read via `state.uri.queryParameters`. Extra data (media viewer) is passed via `state.extra` as `Map<String, dynamic>`.

---

## Offline-First Strategy

**Isar** (`lib/shared/database/isar_schema.dart`) provides the offline cache. Collections:

| Collection | Key index | Purpose |
|-----------|-----------|---------|
| `IsarAccount` | `accountId` (unique) | Cached account profiles |
| `IsarChat` | `(accountId, chatId)` composite | Chat list cache |
| `IsarMessage` | `(accountId, chatId, messageId)` composite | Message cache |
| `IsarContact` | `(accountId, contactId)` composite | Contact cache |
| `IsarDraft` | `(accountId, chatId)` unique | Per-chat draft text |

`OmegaDatabase` is a singleton opened once via `OmegaDatabase.instance`. All write operations use `db.writeTxn(() async { ... })`.

**Cache strategy**: providers first render from Isar cache (instant), then fetch from RPC and upsert back to Isar. `cachedAt` timestamps are stored on each record for staleness checks.

**Draft flow**: `OmegaDatabase.saveDraft` is called on input change (debounced). `getDraft` is called when a chat screen opens to restore in-progress text. `clearDraft` is called on send.

---

## Security Model

End-to-end encryption is implemented entirely within `deltachat-rpc-server` using Autocrypt (OpenPGP). The Flutter layer has no access to private keys — it only sees encrypted/decrypted payloads.

**Signal indicators**:
- `showPadlock: true` on a `Message` — message was E2E encrypted
- `isVerified: true` on a `Chat` — all members have verified key fingerprints (Verified Group)
- `is_verified: true` on a `Contact` — contact fingerprint has been manually verified (QR scan)

**QR verification flow** (`QrScanMode.contact`):
1. User scans contact's QR code (`OPENPGP4FPR:...`).
2. `DeltaRpcClient.checkQr(qr)` returns `type: qr_ask_verifycontact`.
3. App prompts confirmation; on accept calls `continueKeyTransfer`.
4. Contact is marked verified in both DeltaChat core and Isar cache.

**Credentials**: email password is stored via `flutter_secure_storage` (keychain on iOS/macOS, Android Keystore-backed EncryptedSharedPreferences on Android). Never stored in `SharedPreferences` or plain files.

**Screen security**: `AppSettings.screenSecurity` — when true, the platform flag to disable screenshots is set (Android `FLAG_SECURE`, iOS `ignoresScreenshots`).

**Biometric lock**: `AppSettings.biometricLock` — enforced at app foreground resume. MDM can mandate this via the `require_biometric` policy key.

---

## Enterprise Features Overview

Enterprise features live in `lib/features/enterprise/`.

### MDM Integration

`AdminPolicyScreen` reads policy values from the platform MDM channel:
- **Android**: AppConfig / Enterprise Mobility Management (EMM) via `ManagedConfigurations`
- **iOS**: Apple MDM profile via `com.apple.configuration.managed`

Policy keys are read-only from the app's perspective — the MDM/EMM pushes them; the app enforces them.

### Available Policy Groups

| Group | Keys |
|-------|------|
| Account | `addr`, `mail_server`, `send_server`, `mail_security` |
| Feature restrictions | `show_emails`, `media_quality`, `only_one_account`, `disable_backup` |
| Security | `require_biometric`, `screen_security`, `auto_delete_days` |
| QR provisioning | `provisioning_url` |

See `docs/ENTERPRISE.md` for full key reference and MDM configuration payload examples.

### Multi-Account

`MultiAccountScreen` allows switching between configured accounts. When `only_one_account` policy is enforced, account addition is disabled.

### Audit Log

Events are recorded and exportable from `AdminPolicyScreen` → "Export Audit Log". See `docs/ENTERPRISE.md` for the log format.

### Push Notifications

Firebase Cloud Messaging via `NotificationService`. Two Android notification channels:
- `omega_chats` (Importance.high) — chat messages
- `omega_calls` (Importance.max) — calls

The FCM token is retrieved at startup and must be registered with the server-side push relay that bridges to `deltachat-rpc-server`.
