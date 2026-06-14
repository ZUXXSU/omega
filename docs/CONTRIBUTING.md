# Omega — Contribution Guide

## Branch Naming

| Prefix | Use for |
|--------|---------|
| `feature/` | New user-facing features |
| `fix/` | Bug fixes |
| `enterprise/` | Enterprise / MDM / policy features |
| `docs/` | Documentation changes only |
| `refactor/` | Code restructuring without behavior change |
| `chore/` | Build system, dependency updates |

Examples: `feature/disappearing-messages`, `fix/chat-scroll-position`, `enterprise/audit-log-export`.

---

## Pull Request Requirements

Every PR must:

1. **Update `completion.md`** — check off any items that are now done; add new checklist items if your work is partial.
2. **Add a log entry** to `.claude/logs/` — create a new iteration file (e.g. `iteration-004.md`) or append to the current phase log. Include: what was built, what was changed, any decisions made.
3. Pass `flutter analyze` with no errors.
4. Pass `flutter test` with no failures.

PR title format: `[feature|fix|enterprise|docs|chore]: short description`

Example: `feature: disappearing messages timer UI`

---

## Code Style

- **No comments** unless the logic is genuinely non-obvious. Self-documenting names are preferred over explanatory comments.
- **No inline colors or text styles** — always use `OmegaColors.*` and `OmegaTextStyles.*`.
- **No magic numbers** — use `AppConstants.*` for message types, chat types, pagination sizes, and media limits.
- **No direct `DeltaRpcClient` instantiation** — always use `ref.read(deltaRpcClientProvider)`.
- **Immutable state** — provider state classes use `copyWith`. Never mutate state in place.
- **`const` constructors** where possible on widgets.
- Follow the existing pattern in the file you are editing. Consistency with neighbors is preferred over strict stylistic preference.

Run the linter before committing:

```bash
flutter analyze
```

The project uses `flutter_lints` and `riverpod_lint` via `custom_lint`. Fix all warnings, not just errors.

---

## Adding New Screens

1. Determine which feature the screen belongs to. If none fits, create a new feature directory.

2. Create the file:

```
lib/features/<feature>/presentation/screens/<name>_screen.dart
```

3. Add a path constant to `lib/core/constants/route_constants.dart` if the route will be navigated to from multiple places.

4. Add a `GoRoute` entry in `lib/app/router.dart`:

```dart
GoRoute(
  path: RouteConstants.myNewRoute,
  builder: (context, state) => const MyNewScreen(),
),
```

5. If the screen requires a path parameter:

```dart
GoRoute(
  path: '/example/:itemId',
  builder: (context, state) {
    final itemId = int.parse(state.pathParameters['itemId']!);
    return MyNewScreen(itemId: itemId);
  },
),
```

6. Navigate to it using `context.go(...)` or `context.push(...)` from `go_router`.

---

## Adding New Providers

1. Create the provider file:

```
lib/features/<feature>/presentation/providers/<name>_provider.dart
```

2. Add the required imports and `part` declaration:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/network/delta_rpc_client.dart';

part '<name>_provider.g.dart';
```

3. Write the provider using `@riverpod`:

```dart
@immutable
class MyFeatureState {
  final bool isLoading;
  final String? error;
  // ...fields

  const MyFeatureState({this.isLoading = false, this.error});

  MyFeatureState copyWith({bool? isLoading, String? error}) =>
      MyFeatureState(isLoading: isLoading ?? this.isLoading, error: error);
}

@riverpod
class MyFeature extends _$MyFeature {
  @override
  MyFeatureState build() {
    _load();
    return const MyFeatureState(isLoading: true);
  }

  Future<void> _load() async {
    try {
      final rpc = ref.read(deltaRpcClientProvider);
      // ... call rpc methods
      state = state.copyWith(isLoading: false);
    } catch (e, st) {
      AppLogger.e('MyFeature load failed', e, st);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
```

4. Run code generation:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

5. Consume in a widget with `ref.watch(myFeatureProvider)`.

For parameterized (family) providers, add a parameter to `build`:

```dart
@override
MyFeatureState build(int itemId) { ... }
// consumed as: ref.watch(myFeatureProvider(42))
```

---

## Adding New RPC Methods

New RPC methods must be added in two places: the dev-mode in-memory implementation and (when wiring production) the real JSON-RPC call.

### Step 1 — Add to DeltaRpcClient (dev-mode)

Open `lib/core/network/delta_rpc_client.dart` and add the method in the appropriate section (account, chat list, message, contact, etc.):

```dart
Future<Map<String, dynamic>> getMyNewResource(int resourceId) async {
  await _delay();  // always include the 80ms simulated delay
  return _myMap[resourceId] ?? {};
}
```

If the method modifies state, update the relevant in-memory map and ensure `getChatListIds` sorting logic remains consistent.

### Step 2 — Add production implementation (when ready)

The production path sends a JSON-RPC 2.0 request over stdio:

```dart
Future<Map<String, dynamic>> getMyNewResource(int resourceId) async {
  final result = await _call('get_my_new_resource', {'id': resourceId});
  return result as Map<String, dynamic>;
}
```

`_call` is the internal method that writes to the subprocess stdin and awaits the response on stdout. It is not yet implemented in the dev build — that scaffolding will be added when production subprocess wiring begins.

### Step 3 — Use from a provider

```dart
final rpc = ref.read(deltaRpcClientProvider);
final data = await rpc.getMyNewResource(id);
```

Never construct `DeltaRpcClient` directly. Always go through `deltaRpcClientProvider`.

---

## Adding New Isar Collections

1. Open `lib/shared/database/isar_schema.dart`.
2. Add the collection class:

```dart
@collection
class IsarMyModel {
  Id id = Isar.autoIncrement;

  @Index()
  late int accountId;

  @Index(composite: [CompositeIndex('myModelId')])
  late int myModelId;

  late String name;
  DateTime? cachedAt;
}
```

3. Register the schema in `OmegaDatabase._open()`:

```dart
return Isar.open(
  [
    IsarAccountSchema,
    IsarChatSchema,
    IsarMessageSchema,
    IsarContactSchema,
    IsarDraftSchema,
    IsarMyModelSchema,  // add here
  ],
  directory: dir.path,
  name: 'omega',
);
```

4. Run `build_runner build`. Isar generates the schema class automatically.

**Schema version**: Isar 3.x does not support automatic migrations. During development, call `OmegaDatabase.clearAll()` after schema changes. For production upgrades, plan explicit migration logic.

---

## Adding New Freezed Models

1. Create the model file in `lib/shared/models/` or `lib/features/<feature>/`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'my_model.freezed.dart';
part 'my_model.g.dart';

@freezed
class MyModel with _$MyModel {
  const factory MyModel({
    required int id,
    required String name,
    @Default(false) bool isActive,
  }) = _MyModel;

  factory MyModel.fromJson(Map<String, dynamic> json) =>
      _$MyModelFromJson(json);
}
```

2. Run `flutter pub run build_runner build --delete-conflicting-outputs`.

3. Generated files `my_model.freezed.dart` and `my_model.g.dart` must not be edited manually.

---

## Testing

Place tests in `test/`. Mirror the `lib/` directory structure:

```
test/
  features/
    chat/
      chat_provider_test.dart
  core/
    delta_rpc_client_test.dart
```

For provider tests, use `ProviderContainer` from `flutter_riverpod`:

```dart
final container = ProviderContainer(
  overrides: [
    deltaRpcClientProvider.overrideWithValue(MockDeltaRpcClient()),
  ],
);
addTearDown(container.dispose);
```

Run tests:

```bash
flutter test
flutter test test/features/chat/chat_provider_test.dart
```

---

## Before Opening a PR Checklist

- [ ] `flutter analyze` — no errors or warnings
- [ ] `flutter test` — all tests pass
- [ ] `completion.md` updated
- [ ] Log entry added to `.claude/logs/`
- [ ] No inline color literals or text styles
- [ ] No raw magic numbers (use `AppConstants`)
- [ ] Generated files (`*.g.dart`, `*.freezed.dart`) committed
- [ ] PR description explains the "why", not just the "what"
