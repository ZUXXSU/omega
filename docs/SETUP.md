# Omega — Developer Setup Guide

## Prerequisites

| Tool | Minimum Version | Notes |
|------|----------------|-------|
| Flutter | 3.x stable | `flutter --version` to check |
| Dart SDK | ^3.10.4 | Bundled with Flutter |
| Xcode | 15+ | iOS and macOS builds only |
| Android Studio / SDK | API 21+ target | Android builds |
| CocoaPods | latest | iOS/macOS dependency resolution |
| Node.js | not required | — |

Install Flutter: https://docs.flutter.dev/get-started/install

Verify setup:

```bash
flutter doctor -v
```

All items should show a checkmark before proceeding. The `flutter doctor` output will specify any missing platform SDKs.

---

## Clone and Initial Setup

```bash
git clone <repo-url> omega
cd omega
flutter pub get
```

After `pub get`, generated files (`*.g.dart`, `*.freezed.dart`) will be missing. Run code generation next.

---

## Code Generation

Omega uses three code generators that all run through `build_runner`:

| Generator | Annotation | Output |
|-----------|-----------|--------|
| `riverpod_generator` | `@riverpod` | `*.g.dart` (providers) |
| `freezed` | `@freezed` | `*.freezed.dart` + `*.g.dart` (models) |
| `isar_generator` | `@collection` | `*.g.dart` (Isar schemas) |
| `json_serializable` | `@JsonSerializable` | `*.g.dart` (JSON) |

Run all generators in one command:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

For continuous generation during active development:

```bash
flutter pub run build_runner watch --delete-conflicting-outputs
```

You must re-run `build_runner build` after:
- Adding or modifying any `@riverpod` provider
- Adding or modifying any `@freezed` model
- Adding or modifying any `@collection` Isar schema
- Adding or modifying any `@JsonSerializable` class

---

## Firebase Setup

Omega uses Firebase for push notifications (FCM). Firebase config files are not committed to the repository — each developer must obtain them from the Firebase console.

### Android

1. Go to Firebase Console → Project Settings → Android app (`com.omega.messenger`).
2. Download `google-services.json`.
3. Place it at:

```
android/app/google-services.json
```

### iOS and macOS

1. Go to Firebase Console → Project Settings → iOS app (`com.omega.messenger`).
2. Download `GoogleService-Info.plist`.
3. For **iOS**, place it at:

```
ios/Runner/GoogleService-Info.plist
```

4. For **macOS**, place it at:

```
macos/Runner/GoogleService-Info.plist
```

5. Open the Xcode project and add the plist to the Runner target if it is not already included.

The app calls `Firebase.initializeApp()` in `main.dart`. Without the config files, the app will crash at startup on physical devices/production builds. For simulator-only dev work, you can use `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` with mocked options if needed.

---

## Platform-Specific Setup

### Android

**Signing** (release builds):

1. Generate a keystore:

```bash
keytool -genkey -v -keystore omega-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias omega
```

2. Create `android/key.properties`:

```properties
storePassword=<password>
keyPassword=<password>
keyAlias=omega
storeFile=<absolute-path-to-omega-release.jks>
```

3. `android/app/build.gradle` already references `key.properties` for release signing. Verify the `signingConfigs` block is present.

**Minimum SDK**: API 21 (Android 5.0). Set in `android/app/build.gradle`.

**Permissions** (already declared in `AndroidManifest.xml`): `INTERNET`, `CAMERA`, `READ_EXTERNAL_STORAGE`, `WRITE_EXTERNAL_STORAGE`, `RECORD_AUDIO`, `VIBRATE`, `RECEIVE_BOOT_COMPLETED`, `USE_BIOMETRIC`.

### iOS

**Provisioning**:

1. Open `ios/Runner.xcworkspace` in Xcode.
2. Select Runner target → Signing & Capabilities.
3. Select your Team and provisioning profile.
4. Bundle ID must be `com.omega.messenger`.

**Required capabilities** (add in Xcode if missing):
- Push Notifications
- Background Modes: Remote notifications, Background fetch
- Keychain Sharing (for secure credential storage)

**CocoaPods**:

```bash
cd ios && pod install && cd ..
```

Run `pod install` after `flutter pub get` whenever iOS native dependencies change.

**Minimum iOS version**: 14.0. Set in `ios/Podfile`:

```ruby
platform :ios, '14.0'
```

### macOS

**Entitlements**: `macos/Runner/DebugProfile.entitlements` and `Release.entitlements` must include:

```xml
<key>com.apple.security.network.client</key>
<true/>
<key>com.apple.security.network.server</key>
<true/>
<key>com.apple.security.files.user-selected.read-write</key>
<true/>
<key>com.apple.security.device.microphone</key>
<true/>
<key>com.apple.security.device.camera</key>
<true/>
```

**CocoaPods**:

```bash
cd macos && pod install && cd ..
```

**Minimum macOS version**: 10.14.

### Windows

No additional setup beyond Flutter Windows toolchain. Build requires Visual Studio 2022 with the "Desktop development with C++" workload.

```bash
flutter build windows --release
```

### Web

No additional setup. Firebase for Web requires adding a `firebase-config.js` or equivalent to `web/index.html` — contact the project maintainer for the web Firebase config snippet.

```bash
flutter build web --release
```

---

## Environment Variables and Secrets

The following files are **not** committed to the repository:

| File | Purpose |
|------|---------|
| `android/app/google-services.json` | Firebase Android config |
| `ios/Runner/GoogleService-Info.plist` | Firebase iOS config |
| `macos/Runner/GoogleService-Info.plist` | Firebase macOS config |
| `android/key.properties` | Android signing credentials |

There are no `.env` files. Compile-time configuration (if any) uses `--dart-define` flags passed to the build command:

```bash
flutter build apk --dart-define=SOME_KEY=value
```

---

## Running on Each Platform

### Android

```bash
# List available devices
flutter devices

# Run debug
flutter run -d <android-device-id>

# Run release
flutter run -d <android-device-id> --release
```

### iOS (requires macOS)

```bash
# Open iOS simulator
open -a Simulator

# Run
flutter run -d <ios-simulator-id>

# On physical device (requires provisioning)
flutter run -d <device-udid>
```

### macOS

```bash
flutter run -d macos
```

### Windows

```bash
flutter run -d windows
```

### Web

```bash
flutter run -d chrome
# or
flutter run -d web-server --web-port 8080
```

---

## Verify Everything Works

After completing the steps above:

1. Run `flutter doctor -v` — all required items should pass.
2. Run `flutter pub run build_runner build --delete-conflicting-outputs` — should complete with no errors.
3. Run `flutter run -d <device>` — app should launch to the Welcome screen.
4. Check the debug console for `DeltaRpcClient started (dev mode)` — confirms the RPC layer initialized.
5. Navigate through the chat list — dev-mode seed data (Alice, Engineering Team, Bob) should appear.
