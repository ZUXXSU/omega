import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/network/delta_rpc_client.dart';
import '../../../../shared/models/chat.dart';
import '../../../../core/utils/logger.dart';

part 'chat_list_provider.g.dart';

@immutable
class ChatListState {
  final List<Chat> chats;
  final List<Chat> archivedChats;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final int totalUnread;

  const ChatListState({
    this.chats = const [],
    this.archivedChats = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.totalUnread = 0,
  });

  ChatListState copyWith({
    List<Chat>? chats,
    List<Chat>? archivedChats,
    bool? isLoading,
    String? error,
    String? searchQuery,
    int? totalUnread,
  }) =>
      ChatListState(
        chats: chats ?? this.chats,
        archivedChats: archivedChats ?? this.archivedChats,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        searchQuery: searchQuery ?? this.searchQuery,
        totalUnread: totalUnread ?? this.totalUnread,
      );
}

@riverpod
class ChatList extends _$ChatList {
  @override
  ChatListState build() {
    _load();
    return const ChatListState(isLoading: true);
  }

  Future<void> _load() async {
    try {
      final rpc = ref.read(deltaRpcClientProvider);
      final chatIds = await rpc.getChatListIds();
      final archivedIds = await rpc.getChatListIds(archivedOnly: true);

      final chats = await Future.wait(chatIds.map((id) => rpc.getChatInfo(id)));
      final archived = await Future.wait(archivedIds.map((id) => rpc.getChatInfo(id)));

      final chatList = chats.map(_mapChat).toList();
      final archivedList = archived.map(_mapChat).toList();
      final totalUnread = chatList.fold<int>(0, (sum, c) => sum + c.unreadCount);

      state = state.copyWith(
        chats: chatList,
        archivedChats: archivedList,
        isLoading: false,
        totalUnread: totalUnread,
      );
    } catch (e, st) {
      AppLogger.e('ChatList load failed', e, st);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _load();
  }

  Future<void> search(String query) async {
    state = state.copyWith(searchQuery: query, isLoading: true);
    try {
      final rpc = ref.read(deltaRpcClientProvider);
      final chatIds = await rpc.getChatListIds(query: query.isEmpty ? null : query);
      final chats = await Future.wait(chatIds.map((id) => rpc.getChatInfo(id)));
      state = state.copyWith(
        chats: chats.map(_mapChat).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> pinChat(int chatId) async {
    await ref.read(deltaRpcClientProvider).setChatVisibility(chatId, 2);
    await refresh();
  }

  Future<void> unpinChat(int chatId) async {
    await ref.read(deltaRpcClientProvider).setChatVisibility(chatId, 1);
    await refresh();
  }

  Future<void> archiveChat(int chatId) async {
    await ref.read(deltaRpcClientProvider).setChatVisibility(chatId, 0);
    await refresh();
  }

  Future<void> unarchiveChat(int chatId) async {
    await ref.read(deltaRpcClientProvider).setChatVisibility(chatId, 1);
    await refresh();
  }

  Future<void> muteChat(int chatId, int durationSeconds) async {
    await ref.read(deltaRpcClientProvider).setChatMuteDuration(chatId, durationSeconds);
    await refresh();
  }

  Future<void> unmuteChat(int chatId) async {
    await ref.read(deltaRpcClientProvider).setChatMuteDuration(chatId, 0);
    await refresh();
  }

  Future<void> markRead(int chatId) async {
    await ref.read(deltaRpcClientProvider).marknoticedChat(chatId);
    await refresh();
  }

  Future<void> deleteChat(int chatId) async {
    await ref.read(deltaRpcClientProvider).deleteChat(chatId);
    await refresh();
  }

  Chat _mapChat(Map<String, dynamic> data) {
    final ts = data['last_message_time'] as int?;
    return Chat(
      id: (data['id'] as num?)?.toInt() ?? 0,
      name: data['name'] as String? ?? '',
      type: _mapChatType(data['type'] as int? ?? 100),
      visibility: _mapVisibility(data['visibility'] as int? ?? 1),
      lastMessage: data['last_message'] as String?,
      lastMessageTime: ts != null ? DateTime.fromMillisecondsSinceEpoch(ts * 1000) : null,
      unreadCount: (data['unread'] as num?)?.toInt() ?? 0,
      isMuted: data['muted'] as bool? ?? false,
      isVerified: data['is_verified'] as bool? ?? false,
      memberIds: List<int>.from(data['contact_ids'] as List? ?? []),
    );
  }

  ChatType _mapChatType(int type) {
    return switch (type) {
      100 => ChatType.single,
      120 => ChatType.group,
      160 => ChatType.broadcast,
      _ => ChatType.single,
    };
  }

  ChatVisibility _mapVisibility(int v) {
    return switch (v) {
      0 => ChatVisibility.archived,
      2 => ChatVisibility.pinned,
      _ => ChatVisibility.normal,
    };
  }
}

@riverpod
int totalUnreadCount(TotalUnreadCountRef ref) {
  return ref.watch(chatListProvider).totalUnread;
}
