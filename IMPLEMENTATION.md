# Omega — Enterprise Flutter Implementation

## Architecture Decision

Single Flutter codebase targeting: Android, iOS, Windows, macOS, Web

### Stack
- **Flutter** — UI framework
- **Riverpod** — State management (enterprise-grade DI)
- **go_router** — Navigation
- **Hive / Isar** — Local persistence
- **deltachat-rpc-server** — Core messaging engine (Rust, via FFI)
- **flutter_rust_bridge** — Dart ↔ Rust FFI
- **firebase_messaging** — Push notifications
- **flutter_secure_storage** — Keychain/Keystore credential storage

### Branding
- App name: **Omega**
- Package: `com.omega.messenger`
- All "Delta Chat" references → "Omega"

### Platform Targets
| Platform | Build Target | Notes |
|----------|-------------|-------|
| Android | `flutter build apk` / `aab` | Min SDK 21 |
| iOS | `flutter build ios` | Min iOS 14 |
| macOS | `flutter build macos` | macOS 12+ |
| Windows | `flutter build windows` | Win 10+ |
| Web | `flutter build web` | PWA enabled |

## Agent Assignment
- **agent-desktop**: Extracts Electron/web features → Flutter Windows/macOS/Web
- **agent-android**: Extracts Android features → Flutter Android
- **agent-ios**: Extracts iOS features → Flutter iOS
- **agent-pages**: Extracts docs/web content → Flutter Web + onboarding

## Log Files
- `.claude/logs/desktop.md`
- `.claude/logs/android.md`
- `.claude/logs/ios.md`
- `.claude/logs/pages.md`
