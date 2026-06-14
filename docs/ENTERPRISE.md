# Omega — Enterprise Deployment Guide

## Overview

Omega supports enterprise deployment through:
- MDM/EMM policy enforcement (iOS MDM, Android AppConfig)
- QR-code provisioning for zero-touch account setup
- Single-account lock mode
- Audit log and compliance reporting
- Firebase Cloud Messaging for enterprise push relay
- Admin policy screen for IT administrators

Enterprise features are located in `lib/features/enterprise/`.

---

## MDM Configuration

### iOS — Apple MDM

Omega reads managed configuration from the `com.apple.configuration.managed` plist key, which Apple MDM pushes to enrolled devices. Configure policy in your MDM server (Jamf Pro, Mosyle, Kandji, etc.) using a Custom App Configuration profile.

Example MDM profile payload (XML):

```xml
<dict>
  <key>addr</key>
  <string>employee@company.com</string>

  <key>mail_server</key>
  <string>imap.company.com</string>

  <key>send_server</key>
  <string>smtp.company.com</string>

  <key>mail_security</key>
  <integer>3</integer>

  <key>only_one_account</key>
  <true/>

  <key>require_biometric</key>
  <true/>

  <key>screen_security</key>
  <true/>

  <key>auto_delete_days</key>
  <integer>90</integer>

  <key>disable_backup</key>
  <true/>
</dict>
```

Deploy this via your MDM as a Managed App Configuration for the `com.omega.messenger` app bundle.

### Android — EMM / AppConfig

Omega reads managed configuration from Android's `RestrictionsManager` (AppConfig standard). Configure in your EMM console (VMware Workspace ONE, Microsoft Intune, Google Workspace, etc.) using the Managed Configuration schema.

Example AppConfig JSON (upload to EMM console):

```json
{
  "kind": "androidenterprise#managedConfiguration",
  "productId": "app:com.omega.messenger",
  "managedProperty": [
    {"key": "addr", "valueString": "employee@company.com"},
    {"key": "mail_server", "valueString": "imap.company.com"},
    {"key": "send_server", "valueString": "smtp.company.com"},
    {"key": "mail_security", "valueInteger": 3},
    {"key": "only_one_account", "valueBool": true},
    {"key": "require_biometric", "valueBool": true},
    {"key": "screen_security", "valueBool": true},
    {"key": "auto_delete_days", "valueInteger": 90},
    {"key": "disable_backup", "valueBool": true}
  ]
}
```

---

## Available Policy Keys

### Account Policies

| Key | Type | Description |
|-----|------|-------------|
| `addr` | string | Pre-fills and locks the account email address. User cannot change it. |
| `mail_server` | string | Locks the IMAP server hostname. |
| `mail_port` | integer | Locks the IMAP port (default: 993). |
| `send_server` | string | Locks the SMTP server hostname. |
| `send_port` | integer | Locks the SMTP port (default: 465). |
| `mail_security` | integer | TLS policy: 0=Auto, 1=No TLS, 2=STARTTLS, 3=TLS |
| `send_security` | integer | SMTP TLS policy (same values as `mail_security`) |
| `mail_user` | string | Override IMAP login username if different from email. |
| `send_user` | string | Override SMTP login username if different from email. |

### Feature Restrictions

| Key | Type | Description |
|-----|------|-------------|
| `show_emails` | integer | 0=Only Omega messages (default), 1=Accepted contacts, 2=All emails |
| `media_quality` | integer | 0=Auto, 1=Compressed, 2=Original quality for sent images/video |
| `only_one_account` | bool | Prevents users from adding additional email accounts |
| `disable_backup` | bool | Prevents users from exporting account backups |
| `download_limit` | integer | Max auto-download size in bytes (default: 26214400 = 25 MB) |
| `provisioning_url` | string | Auto-configure account from a chatmail/DeltaChat invite URL on first launch |

### Security Policies

| Key | Type | Description |
|-----|------|-------------|
| `require_biometric` | bool | Forces biometric authentication every time the app foregrounds |
| `screen_security` | bool | Disables screenshots and app-switcher preview (`FLAG_SECURE` on Android, `ignoresScreenshots` on iOS) |
| `auto_delete_days` | integer | Enforces message auto-delete after N days on device. 0=disabled |
| `auto_delete_server_days` | integer | Enforces server-side message deletion after N days. 0=disabled |
| `read_receipts` | bool | Force-enables or disables read receipt delivery |
| `bcc_self` | bool | Force BCC-self for all sent messages (compliance copy) |

### Policy Enforcement Notes

- Enforced policies are displayed with a blue "ENFORCED" badge in `AdminPolicyScreen`.
- Keys not present in the MDM payload show "NOT SET" and fall back to user defaults.
- The app reads MDM config on each cold start and on foreground (for policies that can change remotely).
- Attempting to change a locked setting from the UI has no effect; the provider re-reads from MDM on next load.

---

## QR Provisioning Flow

QR provisioning allows zero-touch account setup for new employees.

### Administrator Steps

1. Generate a provisioning QR code from your company's DeltaChat/chatmail instance:
   - This produces a `dcaccount:` or `https://i.delta.chat/...` URL encoding the IMAP/SMTP credentials or a chatmail token.
2. Optionally, set the `provisioning_url` MDM key to the same URL string for fully automatic provisioning on first launch (no QR scan needed).
3. Distribute the QR code (printed, in an email, on an onboarding card).

### Employee Steps (manual QR)

1. Open Omega → tap "Scan QR Code" on the Welcome screen.
2. Point camera at the provisioning QR code.
3. The app calls `DeltaRpcClient.checkQr(qr)`.
   - Response `type: qr_account` → auto-configures an account from the embedded URL.
4. Account is configured and the user lands on the chat list.

### QR Scan Modes

| Mode | URL Param | Purpose |
|------|-----------|---------|
| `contact` | `?mode=contact` (default) | Verify a contact's fingerprint |
| `group` | `?mode=group` | Join a verified group via invite QR |
| `account` | `?mode=account` | Provision a new account (chatmail / dcaccount: URL) |
| `backup` | `?mode=backup` | Restore from a backup QR |

The scanner route is `/qr?mode=<mode>`. Navigate to it with:

```dart
context.push('/qr?mode=account');
```

---

## Audit Log

### What is Logged

The audit log records policy and compliance events. Current event categories:

| Category | Events |
|----------|--------|
| Account | Account created, account removed, account configured via QR |
| Auth | Login success, login failure, biometric lock triggered, logout |
| Policy | MDM policy loaded, policy key changed, enforced setting overridden by user |
| Data | Backup export attempted, backup export blocked (policy), message auto-delete executed |
| Security | Screenshot blocked, screen security toggled |

### Log Entry Format

Each audit log entry is a JSON object:

```json
{
  "ts": "2026-06-14T10:23:45Z",
  "level": "INFO",
  "category": "AUTH",
  "event": "login_success",
  "account_id": 1,
  "addr": "employee@company.com",
  "device_id": "uuid-v4",
  "platform": "android",
  "policy_managed": true,
  "detail": {}
}
```

| Field | Type | Description |
|-------|------|-------------|
| `ts` | ISO 8601 string | UTC timestamp of the event |
| `level` | string | INFO, WARN, ERROR |
| `category` | string | AUTH, ACCOUNT, POLICY, DATA, SECURITY |
| `event` | string | Snake_case event identifier |
| `account_id` | integer | Omega account ID (nullable) |
| `addr` | string | Account email address (nullable) |
| `device_id` | string | Stable device UUID (generated at first launch) |
| `platform` | string | android, ios, macos, windows, web |
| `policy_managed` | bool | Whether device is under MDM at time of event |
| `detail` | object | Event-specific additional data |

### Exporting the Audit Log

From `AdminPolicyScreen` → "Export Audit Log" button:
- Exports as a newline-delimited JSON file (`.ndjson`).
- File name format: `omega-audit-<device_id>-<YYYYMMDD>.ndjson`
- The export button opens the system share sheet (iOS/Android) or save dialog (macOS/Windows).

For server-side collection, your MDM push relay can also forward log entries in real time via a configured webhook URL (set via `audit_log_webhook` MDM key — planned feature).

---

## Compliance Report

`AdminPolicyScreen` → "Compliance Status" opens the compliance report view.

### Report Fields

| Field | Description |
|-------|-------------|
| `report_ts` | Timestamp when the report was generated |
| `device_id` | Stable device UUID |
| `platform` | android, ios, macos, windows, web |
| `app_version` | Omega version string |
| `is_managed` | Whether MDM policy is currently active |
| `policies_enforced` | Array of key names that are currently enforced |
| `policies_not_set` | Array of key names present in schema but not enforced |
| `biometric_lock` | bool — is biometric lock active |
| `screen_security` | bool — is screen security active |
| `auto_delete_days` | integer — current retention policy (0=off) |
| `last_policy_load_ts` | When MDM policy was last successfully read |
| `account_count` | Number of configured accounts (1 if only_one_account enforced) |

Export format: JSON. The report is signed with the device key in planned enterprise builds.

---

## Single-Account Mode Setup

Single-account mode prevents users from adding more than one email account. Enable via MDM:

```
only_one_account = true
```

Effect:
- The "Add Account" button in `MultiAccountScreen` is disabled and shows an MDM lock icon.
- The account switcher shows only the managed account.
- Attempting to add an account programmatically returns an error.

If the user already has multiple accounts when the policy is pushed, existing accounts remain but no new ones can be added. To enforce single-account at enrollment, use `provisioning_url` combined with `only_one_account` and provision on a factory-reset device.

---

## Firebase Cloud Messaging (Enterprise Push)

### Architecture

```
DeltaChat mail server
    │  detects new message for device
    ▼
Push relay service (your server)
    │  receives webhook from deltachat-rpc-server
    ▼
Firebase Cloud Messaging
    │  delivers to device
    ▼
NotificationService (Omega)
    │  shows local notification
    ▼
User taps → opens chat
```

### Setup Steps

1. Create a Firebase project at https://console.firebase.google.com.
2. Enable Cloud Messaging.
3. Add Android app (`com.omega.messenger`) and iOS app (`com.omega.messenger`).
4. Download config files (see `docs/SETUP.md`).
5. Deploy a push relay service that:
   - Accepts webhooks from `deltachat-rpc-server` when new mail arrives.
   - Looks up the target device's FCM token (stored on your user directory).
   - Sends a data-only FCM message to that token.

### FCM Notification Channels (Android)

| Channel ID | Name | Importance | Usage |
|-----------|------|-----------|-------|
| `omega_chats` | Chat Messages | High | New messages from chats |
| `omega_calls` | Calls | Max | Incoming calls (future) |

### FCM Token Management

The FCM token is retrieved at startup via `NotificationService.getFcmToken()`. Your push relay must store a mapping of `{account_email → fcm_token}` and update it whenever the token refreshes. Token refresh is handled by `FirebaseMessaging.instance.onTokenRefresh` — add a listener in `NotificationService._setupFCM()` to push updated tokens to your relay.

### Enterprise FCM Payload

The push relay should send a data-only FCM payload (no `notification` block, to allow background processing):

```json
{
  "to": "<device-fcm-token>",
  "data": {
    "type": "new_message",
    "chatId": "42",
    "accountId": "1"
  }
}
```

On receipt, `NotificationService._handleForegroundMessage` / `_handleBackgroundMessage` triggers the local notification display.

---

## Security Recommendations for Enterprise Deployments

1. **Always enforce `mail_security: 3` (TLS)** — never allow unencrypted SMTP/IMAP.
2. **Enable `require_biometric`** for devices that handle sensitive communications.
3. **Enable `screen_security`** to prevent data leakage via screenshots or app switcher.
4. **Set `auto_delete_days`** per your organization's data retention policy.
5. **Set `disable_backup`** if your compliance requirements prohibit local data export.
6. **Use Verified Groups** (`verified=true` on group create) for sensitive team channels — requires all members to have verified key fingerprints.
7. **Rotate FCM tokens** — build your push relay to handle token refresh events to avoid missed notifications.
8. **Audit log retention** — collect logs centrally from enrolled devices. Local logs should be considered ephemeral.
9. **Zero-touch enrollment** — use `provisioning_url` + `addr` MDM keys combined with device enrollment to ensure accounts are pre-configured before the user first opens the app.
10. **Network isolation** — deploy a company IMAP/SMTP server behind your corporate VPN. Set `mail_server` and `send_server` to internal hostnames. Omega will only communicate with those servers.
