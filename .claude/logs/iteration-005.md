# Loop Iteration 005 — Bottom Nav, Global Search, Provider Wiring

**Date:** 2026-06-14
**Context:** Running while 6-parallel-CLI workflow (w6tpwzgol) is active
**Implemented:** Features NOT covered by parallel CLIs — no file conflicts

## What Was Done

### StatefulShellRoute Bottom Navigation
**`lib/app/router.dart`** — Full rewrite:
- Replaced `ShellRoute` with `StatefulShellRoute.indexedStack`
- 4 persistent branches: Chats (/chats), Contacts (/contacts), QR (/qr), Settings (/settings)
- Chat branch nests: `/:chatId` → `/search` (in-chat search)
- Group create nested under chats: `/chats/group/create`
- Full-screen overlays outside shell: QR scanner, media viewer, global search, message search

**`lib/app/shell_scaffold.dart`** — New file:
- `ShellScaffold(shell)` wraps `StatefulNavigationShell`
- `NavigationBar` with 4 destinations (Material3)
- Unread badge on Chats tab — reads `totalUnreadCountProvider` live
- Double-tap branch tab → pops to root of that branch (`initialLocation: true`)
- Dark/light theme aware

### Global Search Screen (`lib/features/search/presentation/screens/global_search_screen.dart`)
- TabBar with 4 tabs: All / Chats / Contacts / Messages (with live counts)
- Debounced search (triggers ≥2 chars)
- Searches RPC for chats (getChatListIds), contacts (getContacts), messages (getMessages across top chats)
- Results: `_ChatResult`, `_ContactResult`, `_MessageResult` typed models
- "All" tab shows top 3 chats + 3 contacts + 5 messages with section headers
- Message results: highlighted match text (yellow bg, bold)
- Tap → navigate to correct route
- Empty states: hint screen, no-results screen

### Contact Request Banner (`lib/features/chat/widgets/contact_request_banner.dart`)
- `ContactRequestBanner`: warning-colored banner with sender info
- 3 action buttons: Accept (green), Block (red), Delete (grey)
- `EncryptionActiveBanner`: dismissable green "E2E encrypted" info banner

### Chat List Screen — Provider Wired + UX Fixes
- `_ChatListBody` reads `chatListProvider` (real data, not mock)
- `RefreshIndicator` for pull-to-refresh
- Error state with Retry button
- Empty state: "No chats yet · tap +"
- Mock data removed
- `_ChatOptions` upgraded to `ConsumerWidget`:
  - Pin/Unpin → `notifier.pinChat/unpinChat`
  - Mute/Unmute → `notifier.muteChat/unmuteChat`
  - Archive → `notifier.archiveChat`
  - Mark as read → `notifier.markRead`
  - Delete → `notifier.deleteChat`
- FAB → contacts (for new chat)
- Search button → `/search` (global search)
- Menu: New Group → `/chats/group/create`, QR → `/qr-display`

### Route Constants — Extended
Added: globalSearch, starredMessages, appLock, compliance, provisioning, adminPolicy, multiAccount

## Files Created/Modified: 6

## Parallel Workflow Status
Workflow `w6tpwzgol` still running (6 CLIs building 20+ files simultaneously).
This iteration built non-overlapping features.
