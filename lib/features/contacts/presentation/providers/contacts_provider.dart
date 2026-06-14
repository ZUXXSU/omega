import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/network/delta_rpc_client.dart';
import '../../../../shared/models/contact.dart';
import '../../../../core/utils/logger.dart';

part 'contacts_provider.g.dart';

@immutable
class ContactsState {
  final List<Contact> contacts;
  final List<Contact> blockedContacts;
  final bool isLoading;
  final String? error;
  final String searchQuery;

  const ContactsState({
    this.contacts = const [],
    this.blockedContacts = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
  });

  ContactsState copyWith({
    List<Contact>? contacts,
    List<Contact>? blockedContacts,
    bool? isLoading,
    String? error,
    String? searchQuery,
  }) =>
      ContactsState(
        contacts: contacts ?? this.contacts,
        blockedContacts: blockedContacts ?? this.blockedContacts,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        searchQuery: searchQuery ?? this.searchQuery,
      );
}

@riverpod
class Contacts extends _$Contacts {
  @override
  ContactsState build() {
    _load();
    return const ContactsState(isLoading: true);
  }

  Future<void> _load() async {
    try {
      final rpc = ref.read(deltaRpcClientProvider);
      final ids = await rpc.getContacts();
      final blockedIds = await rpc.getContacts(blockedOnly: true);
      final contacts = await Future.wait(ids.map((id) => rpc.getContactInfo(id)));
      final blocked = await Future.wait(blockedIds.map((id) => rpc.getContactInfo(id)));
      state = state.copyWith(
        contacts: contacts.map(_mapContact).toList(),
        blockedContacts: blocked.map(_mapContact).toList(),
        isLoading: false,
      );
    } catch (e, st) {
      AppLogger.e('Contacts load failed', e, st);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> search(String query) async {
    state = state.copyWith(searchQuery: query, isLoading: true);
    try {
      final rpc = ref.read(deltaRpcClientProvider);
      final ids = await rpc.getContacts(query: query.isEmpty ? null : query);
      final contacts = await Future.wait(ids.map((id) => rpc.getContactInfo(id)));
      state = state.copyWith(
        contacts: contacts.map(_mapContact).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<int> addContact(String email, {String? name}) async {
    final rpc = ref.read(deltaRpcClientProvider);
    final id = await rpc.createContact(addr: email, name: name);
    await _load();
    return id;
  }

  Future<void> blockContact(int contactId) async {
    await ref.read(deltaRpcClientProvider).blockContact(contactId);
    await _load();
  }

  Future<void> unblockContact(int contactId) async {
    await ref.read(deltaRpcClientProvider).unblockContact(contactId);
    await _load();
  }

  Future<void> deleteContact(int contactId) async {
    await ref.read(deltaRpcClientProvider).deleteContact(contactId);
    state = state.copyWith(
      contacts: state.contacts.where((c) => c.id != contactId).toList(),
    );
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _load();
  }

  Contact _mapContact(Map<String, dynamic> d) => Contact(
    id: (d['id'] as num?)?.toInt() ?? 0,
    email: d['addr'] as String? ?? '',
    displayName: d['display_name'] as String? ?? d['addr'] as String? ?? '',
    profileImagePath: d['profile_image'] as String?,
    statusMessage: d['status'] as String?,
    isVerified: d['is_verified'] as bool? ?? false,
    isBlocked: d['blocked'] as bool? ?? false,
    isBot: d['is_bot'] as bool? ?? false,
    color: d['color'] as String?,
  );
}

@riverpod
Future<Contact?> contactById(ContactByIdRef ref, int contactId) async {
  final rpc = ref.read(deltaRpcClientProvider);
  final data = await rpc.getContactInfo(contactId);
  if (data.isEmpty) return null;
  return Contact(
    id: (data['id'] as num?)?.toInt() ?? contactId,
    email: data['addr'] as String? ?? '',
    displayName: data['display_name'] as String? ?? '',
    isVerified: data['is_verified'] as bool? ?? false,
  );
}
