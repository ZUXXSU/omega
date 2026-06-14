# Omega — Claude Code Project Reference

## Overview

Omega is an enterprise-grade secure messenger built with Flutter. It is a full reimplementation of the DeltaChat protocol stack with an enterprise feature layer on top. The app targets Android, iOS, macOS, Windows, and Web from a single codebase.

- **Package**: `com.omega.messenger`
- **Version**: 1.0.0+1
- **Dart SDK**: ^3.10.4
- **Flutter**: 3.x
- **Status**: Phase 6 (Enterprise Features) in progress — see `completion.md`

The messaging backend is DeltaChat's JSON-RPC server (`deltachat-rpc-server`). The Flutter layer never calls SMTP/IMAP directly; it speaks only to that RPC process. End-to-end encryption is handled entirely inside the RPC core (Autocrypt / OpenPGP).

---

## Architecture

```
lib/
  main.dart               — app entry: Firebase init, NotificationService, ProviderScope
  app/
    app.dart              — OmegaApp (ConsumerWidget, MaterialApp.router)
    router.dart           — go_router definition (@riverpod GoRouter)
    theme/
      colors.dart         — OmegaColors (all color tokens)
      text_styles.dart    — OmegaTextStyles (all text tokens)
      app_theme.dart      — AppTheme.light() / AppTheme.dark()
  core/
    constants/
      app_constants.dart  — AppConstants (msg types, chat types, pagination, media limits, UI)
      route_constants.dart — RouteConstants (all route path strings)
    network/
      delta_rpc_client.dart — DeltaRpcClient abstraction (dev-mode + production interface)
    utils/
      logger.dart         — AppLogger (wraps logger package)
    errors/
      exceptions.dart     — typed exceptions
      failures.dart       — Either<Failure, T> types (dartz)
    di/                   — dependency injection helpers
    extensions/           — Dart extension methods
  features/               — feature-first structure (one folder per product feature)
    auth/
    chat/
    chat_list/
    contacts/
    enterprise/
    media/
    notifications/
    onboarding/
    qr/
    settings/
  shared/
    database/
      isar_schema.dart    — Isar collections + OmegaDatabase singleton
    models/               — Freezed data models (account, chat, contact, message)
    services/
      notification_service.dart — FCM + local notifications
      storage_service.dart      — SharedPreferences + flutter_secure_storage
    widgets/
      omega_text_field.dart — shared text input
      omega_avatar.dart     — shared avatar widget
```

Each feature under `lib/features/<name>/` follows:

```
<feature>/
  presentation/
    screens/    — Screen widgets
    widgets/    — Feature-scoped widgets
    providers/  — Riverpod providers (@riverpod annotated)
```

---

## Key Files

| File | Purpose |
|------|---------|
| `lib/core/network/delta_rpc_client.dart` | RPC abstraction; dev-mode uses in-memory state |
| `lib/app/router.dart` | All go_router routes; generated `router.g.dart` required |
| `lib/app/theme/colors.dart` | `OmegaColors` — single source of truth for colors |
| `lib/app/theme/text_styles.dart` | `OmegaTextStyles` — single source of truth for typography |
| `lib/shared/database/isar_schema.dart` | Isar schema + `OmegaDatabase` query helpers |
| `lib/core/constants/app_constants.dart` | Numeric constants for message types, chat types, limits |
| `lib/core/constants/route_constants.dart` | All route path strings |
| `completion.md` | Phase tracking — update this after every session |

---

## DeltaRpcClient Abstraction

`DeltaRpcClient` in `lib/core/network/delta_rpc_client.dart` is the single point of contact between Flutter and the DeltaChat backend.

**Dev mode** (current): the class maintains in-memory `Map` state seeded with fake accounts, chats, contacts, and messages. Every method adds an 80 ms artificial delay to simulate real I/O. This is the active implementation used for development.

**Production mode** (future): replace the in-memory maps with a `dart:io Process` that spawns `deltachat-rpc-server` and communicates over stdio using JSON-RPC 2.0. The public method signatures stay identical, so callers require no changes.

The Riverpod provider is:

```dart
@riverpod
DeltaRpcClient deltaRpcClient(DeltaRpcClientRef ref) {
  final client = DeltaRpcClient();
  client.start();
  ref.onDispose(() => client.stop());
  return client;
}
```

All providers read from `deltaRpcClientProvider` — never construct `DeltaRpcClient` directly.

**Adding a new RPC method**:
1. Add the in-memory implementation to `DeltaRpcClient` with the 80 ms `_delay()`.
2. Add the production path (stdio JSON-RPC call) when wiring production.
3. Use it from a provider via `ref.read(deltaRpcClientProvider)`.

---

## Riverpod Provider Hierarchy

Code-gen providers use `@riverpod` annotation (from `riverpod_annotation`) and require running `build_runner` to generate `.g.dart` files.

```
deltaRpcClientProvider          — DeltaRpcClient singleton (core/network)
    |
    +-- authProvider            — Auth (AuthState: status, account, loading, error)
    |     +-- currentAccountProvider     — Account?
    |     +-- isAuthenticatedProvider    — bool
    |
    +-- chatListProvider        — ChatList (chats, archivedChats, searchQuery, totalUnread)
    |     +-- totalUnreadCountProvider   — int
    |
    +-- chatMessagesProvider(chatId)     — ChatMessages (messages, loading, hasMore, replyTo)
    |
    +-- contactsProvider        — ContactsNotifier
    |
    +-- settingsProvider        — Settings (AppSettings: RPC config + local prefs)
    |
    +-- routerProvider          — GoRouter instance
```

State classes use immutable `copyWith` patterns (no Freezed for provider state, but domain models use Freezed). Optimistic updates are used for message sending: a temp message with a negative ID is inserted immediately, then replaced with the real ID on success or marked failed on error.

---

## go_router Route Structure

Initial location: `/` (WelcomeScreen).

```
/                           WelcomeScreen
/onboarding                 OnboardingScreen
/login                      LoginScreen
/account-setup              AccountSetupScreen

ShellRoute (bare child passthrough)
  /chats                    ChatListScreen
  /chats/:chatId            ChatScreen(chatId)
  /contacts                 ContactsScreen
  /contacts/:contactId      ContactDetailScreen(contactId)
  /settings                 SettingsScreen
  /settings/profile         ProfileSettingsScreen
  /settings/notifications   NotificationSettingsScreen
  /settings/privacy         PrivacySettingsScreen
  /settings/advanced        AdvancedSettingsScreen

/qr?mode=<mode>             QrScannerScreen (modes: contact, group, account, backup)
/qr-display?chatId=<id>     QrDisplayScreen
/group/create               GroupCreateScreen
/media                      MediaViewerScreen (extra: {path, type})
```

Route constants live in `RouteConstants`. Never hard-code path strings in widgets — use `RouteConstants.*` or `context.go(RouteConstants.chat.replaceFirst(':chatId', '$id'))`.

---

## OmegaColors Usage

All colors come from `lib/app/theme/colors.dart`. Never use raw hex literals in widgets.

```dart
import '../../../app/theme/colors.dart';

// Brand
OmegaColors.primary          // #2B5BE8 — main blue
OmegaColors.primaryDark      // #4F7CF5 — dark-mode primary
OmegaColors.secondary        // #00C896 — green accent

// Surfaces
OmegaColors.surfaceLight     OmegaColors.surfaceDark
OmegaColors.backgroundLight  OmegaColors.backgroundDark
OmegaColors.inputFill        OmegaColors.inputFillDark

// Text
OmegaColors.textPrimary      OmegaColors.textPrimaryDark
OmegaColors.textSecondary    OmegaColors.textSecondaryDark
OmegaColors.textDisabled     OmegaColors.textDisabledDark

// Status
OmegaColors.error   OmegaColors.warning   OmegaColors.success   OmegaColors.info

// Chat bubbles
OmegaColors.bubbleOutgoing   OmegaColors.bubbleIncoming
OmegaColors.bubbleOutgoingDark OmegaColors.bubbleIncomingDark

// Message states
OmegaColors.messageSent   OmegaColors.messageDelivered
OmegaColors.messageRead   OmegaColors.messageFailed
```

---

## OmegaTextStyles Usage

All typography comes from `lib/app/theme/text_styles.dart`. Font family is Inter (bundled in `assets/fonts/`).

```dart
import '../../../app/theme/text_styles.dart';

OmegaTextStyles.displayLarge    // 32px w700
OmegaTextStyles.displayMedium   // 28px w700
OmegaTextStyles.titleLarge      // 20px w600
OmegaTextStyles.titleMedium     // 17px w600
OmegaTextStyles.titleSmall      // 15px w600
OmegaTextStyles.bodyLarge       // 16px w400 h1.5
OmegaTextStyles.bodyMedium      // 14px w400 h1.4
OmegaTextStyles.bodySmall       // 13px w400 h1.4
OmegaTextStyles.labelLarge      // 15px w600
OmegaTextStyles.labelMedium     // 13px w500
OmegaTextStyles.labelSmall      // 11px w500
OmegaTextStyles.caption         // 12px w400 textSecondary

// Apply color overrides with copyWith
OmegaTextStyles.bodyLarge.copyWith(color: OmegaColors.textSecondary)
```

`OmegaTextStyles.textTheme` and `OmegaTextStyles.textThemeDark` are passed to `ThemeData` in `AppTheme`.

---

## Development Setup

```bash
# Install dependencies
flutter pub get

# Generate all code (Riverpod providers, Freezed models, Isar schemas, JSON)
flutter pub run build_runner build --delete-conflicting-outputs

# Run on device/simulator
flutter run

# Run with specific device
flutter run -d <device-id>
```

Required: `google-services.json` (Android) and `GoogleService-Info.plist` (iOS/macOS) in their platform directories for Firebase. See `docs/SETUP.md`.

---

## Build Commands

```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS (requires macOS + Xcode)
flutter build ios --release

# macOS
flutter build macos --release

# Windows
flutter build windows --release

# Web
flutter build web --release

# Debug builds (any platform)
flutter build <platform> --debug
```

---

## Testing

```bash
# Unit + widget tests
flutter test

# Single test file
flutter test test/widget_test.dart

# With coverage
flutter test --coverage
```

---

## Common Development Tasks

**Add a new screen**:
1. Create `lib/features/<feature>/presentation/screens/<name>_screen.dart`.
2. Add a route entry in `lib/app/router.dart`.
3. Add the path string to `RouteConstants` if it is navigated to from multiple places.

**Add a new Riverpod provider**:
1. Create the provider file under `lib/features/<feature>/presentation/providers/`.
2. Annotate with `@riverpod` and add `part '<file>.g.dart';`.
3. Run `flutter pub run build_runner build --delete-conflicting-outputs`.

**Add a new RPC method**:
1. Add the in-memory implementation to `DeltaRpcClient` with `await _delay();`.
2. Add it to the production JSON-RPC path when wiring real subprocess.
3. Call via `ref.read(deltaRpcClientProvider).<method>()` inside a provider.

**Update completion tracking**: Edit `completion.md` — check off completed items and add a log entry to `.claude/logs/`.

**Isar schema change**: Edit `lib/shared/database/isar_schema.dart`, then run `build_runner build`. Isar migrations are not automatic — bump the schema version or call `clearAll()` during development.

**Theme change**: Edit `OmegaColors` or `OmegaTextStyles` only. Do not add inline colors or text styles anywhere else.

---

## Key External Dependencies

| Package | Role |
|---------|------|
| `flutter_riverpod` + `riverpod_annotation` | State management (code-gen providers) |
| `go_router` ^14.6.3 | Declarative navigation |
| `isar` ^3.1.0+1 | Local offline cache database |
| `firebase_core` + `firebase_messaging` | Push notifications |
| `flutter_local_notifications` | Local notification display |
| `freezed_annotation` + `json_annotation` | Immutable models + JSON serialization |
| `dio` | HTTP client (future remote RPC) |
| `flutter_secure_storage` | Credential storage |
| `mobile_scanner` + `qr_flutter` | QR scanning and display |
| `pointycastle` + `encrypt` | Supplementary crypto utilities |
| `record` + `just_audio` | Voice message record/playback |
| `image_picker` + `file_picker` | Media attach |
| `lottie` + `shimmer` | Loading animations |

Dev dependencies requiring `build_runner`: `riverpod_generator`, `freezed`, `json_serializable`, `isar_generator`.

---

## Important Patterns

- **No inline comments** unless the logic is genuinely non-obvious.
- **No raw color/text literals** in widgets — always use `OmegaColors.*` / `OmegaTextStyles.*`.
- **No direct `DeltaRpcClient` construction** — always use `ref.read(deltaRpcClientProvider)`.
- **Optimistic UI**: insert a temp message immediately on send; reconcile or revert based on RPC result.
- **Pagination**: `ChatMessages` loads 50 messages per page (`_pageSize = 50`); call `loadMore()` on scroll to end.
- **Draft persistence**: `OmegaDatabase.saveDraft` / `clearDraft` for per-chat drafts.
- **Error handling**: catch in providers, set `error` field on state; never let exceptions propagate to UI uncaught.
- **Generated files**: never edit `*.g.dart` or `*.freezed.dart` — always regenerate via `build_runner`.
