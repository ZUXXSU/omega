import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/network/delta_rpc_client.dart';
import '../../../../shared/models/account.dart';
import '../../../../shared/services/storage_service.dart';
import '../../../../core/utils/logger.dart';

part 'auth_provider.g.dart';

enum AuthStatus { unknown, unauthenticated, configuring, authenticated, error }

@immutable
class AuthState {
  final AuthStatus status;
  final Account? account;
  final String? errorMessage;
  final bool isLoading;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.account,
    this.errorMessage,
    this.isLoading = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    Account? account,
    String? errorMessage,
    bool? isLoading,
  }) =>
      AuthState(
        status: status ?? this.status,
        account: account ?? this.account,
        errorMessage: errorMessage,
        isLoading: isLoading ?? this.isLoading,
      );
}

@riverpod
class Auth extends _$Auth {
  @override
  AuthState build() {
    _checkInitialState();
    return const AuthState(status: AuthStatus.unknown);
  }

  Future<void> _checkInitialState() async {
    final rpc = ref.read(deltaRpcClientProvider);
    try {
      final accountIds = await rpc.getAllAccountIds();
      if (accountIds.isEmpty || !StorageService.isAccountConfigured) {
        state = const AuthState(status: AuthStatus.unauthenticated);
        return;
      }
      final info = await rpc.getAccountInfo(accountIds.first);
      final account = _mapAccount(info);
      await rpc.selectAccount(accountIds.first);
      await rpc.startIo(accountIds.first);
      state = AuthState(status: AuthStatus.authenticated, account: account);
    } catch (e, st) {
      AppLogger.e('Auth check failed', e, st);
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> loginWithCredentials({
    required String email,
    required String password,
    String? mailServer,
    int? mailPort,
    String? sendServer,
    int? sendPort,
  }) async {
    state = state.copyWith(isLoading: true, status: AuthStatus.configuring);
    try {
      final rpc = ref.read(deltaRpcClientProvider);
      final accountId = await rpc.addAccount();
      await rpc.configureAccount(
        accountId: accountId,
        addr: email,
        password: password,
        mailServer: mailServer,
        mailPort: mailPort,
        sendServer: sendServer,
        sendPort: sendPort,
      );
      await rpc.selectAccount(accountId);
      await rpc.startIo(accountId);
      await StorageService.setAccountConfigured();

      final info = await rpc.getAccountInfo(accountId);
      state = AuthState(
        status: AuthStatus.authenticated,
        account: _mapAccount(info),
      );
    } catch (e, st) {
      AppLogger.e('Login failed', e, st);
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Login failed: ${e.toString()}',
        isLoading: false,
      );
    }
  }

  Future<void> loginWithQr(String qrCode) async {
    state = state.copyWith(isLoading: true, status: AuthStatus.configuring);
    try {
      final rpc = ref.read(deltaRpcClientProvider);
      final result = await rpc.checkQr(qr: qrCode);
      if (result['type'] == 'qr_account') {
        // Auto-provision via chatmail
        final accountId = await rpc.addAccount();
        await rpc.selectAccount(accountId);
        await rpc.startIo(accountId);
        await StorageService.setAccountConfigured();
        final info = await rpc.getAccountInfo(accountId);
        state = AuthState(status: AuthStatus.authenticated, account: _mapAccount(info));
      } else {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'Invalid QR code for account creation',
          isLoading: false,
        );
      }
    } catch (e, st) {
      AppLogger.e('QR login failed', e, st);
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    try {
      await StorageService.clear();
      state = const AuthState(status: AuthStatus.unauthenticated);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Account _mapAccount(Map<String, dynamic> info) => Account(
    id: (info['id'] as num?)?.toInt() ?? 0,
    email: info['addr'] as String? ?? '',
    displayName: info['display_name'] as String? ?? '',
    isConfigured: info['configured'] as bool? ?? false,
  );
}

@riverpod
Account? currentAccount(CurrentAccountRef ref) {
  return ref.watch(authProvider).account;
}

@riverpod
bool isAuthenticated(IsAuthenticatedRef ref) {
  return ref.watch(authProvider).status == AuthStatus.authenticated;
}
