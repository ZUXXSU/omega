import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/network/delta_rpc_client.dart';
import '../../../../shared/models/message.dart';
import '../../../../core/utils/logger.dart';

part 'chat_provider.g.dart';

@immutable
class ChatMessagesState {
  final List<Message> messages;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final int? replyToMessageId;
  final String? replyToText;
  final bool isTyping;

  const ChatMessagesState({
    this.messages = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
    this.replyToMessageId,
    this.replyToText,
    this.isTyping = false,
  });

  ChatMessagesState copyWith({
    List<Message>? messages,
    bool? isLoading,
    bool? hasMore,
    String? error,
    int? replyToMessageId,
    String? replyToText,
    bool clearReply = false,
    bool? isTyping,
  }) =>
      ChatMessagesState(
        messages: messages ?? this.messages,
        isLoading: isLoading ?? this.isLoading,
        hasMore: hasMore ?? this.hasMore,
        error: error,
        replyToMessageId: clearReply ? null : (replyToMessageId ?? this.replyToMessageId),
        replyToText: clearReply ? null : (replyToText ?? this.replyToText),
        isTyping: isTyping ?? this.isTyping,
      );
}

@riverpod
class ChatMessages extends _$ChatMessages {
  static const _pageSize = 50;

  @override
  ChatMessagesState build(int chatId) {
    _loadMessages();
    return const ChatMessagesState(isLoading: true);
  }

  Future<void> _loadMessages() async {
    try {
      final rpc = ref.read(deltaRpcClientProvider);
      await rpc.marknoticedChat(chatId);
      final raw = await rpc.getMessages(chatId: chatId, limit: _pageSize);
      final messages = raw.map(_mapMessage).toList();
      state = state.copyWith(
        messages: messages,
        isLoading: false,
        hasMore: raw.length >= _pageSize,
      );
    } catch (e, st) {
      AppLogger.e('Load messages failed', e, st);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading) return;
    try {
      final rpc = ref.read(deltaRpcClientProvider);
      final raw = await rpc.getMessages(
        chatId: chatId,
        offset: state.messages.length,
        limit: _pageSize,
      );
      final more = raw.map(_mapMessage).toList();
      state = state.copyWith(
        messages: [...state.messages, ...more],
        hasMore: raw.length >= _pageSize,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> sendText(String text) async {
    if (text.trim().isEmpty) return;
    final rpc = ref.read(deltaRpcClientProvider);
    final tempId = -DateTime.now().millisecondsSinceEpoch;
    final tempMsg = Message(
      id: tempId,
      chatId: chatId,
      fromContactId: 0,
      type: MessageType.text,
      state: MessageState.pending,
      text: text,
      timestamp: DateTime.now(),
      isOutgoing: true,
      quotedMessageId: state.replyToMessageId,
      quotedText: state.replyToText,
    );
    state = state.copyWith(
      messages: [tempMsg, ...state.messages],
      clearReply: true,
    );
    try {
      final id = await rpc.sendTextMessage(
        chatId: chatId,
        text: text,
        quotedMessageId: state.replyToMessageId,
      );
      final updated = state.messages.map((m) {
        if (m.id == tempId) return m.copyWith(id: id, state: MessageState.sent);
        return m;
      }).toList();
      state = state.copyWith(messages: updated);
    } catch (e) {
      final failed = state.messages.map((m) {
        if (m.id == tempId) return m.copyWith(state: MessageState.failed);
        return m;
      }).toList();
      state = state.copyWith(messages: failed, error: e.toString());
    }
  }

  Future<void> sendFile({
    required String filePath,
    required String mimeType,
    String? caption,
  }) async {
    final rpc = ref.read(deltaRpcClientProvider);
    final type = _mimeToType(mimeType);
    final tempId = -DateTime.now().millisecondsSinceEpoch;
    final tempMsg = Message(
      id: tempId,
      chatId: chatId,
      fromContactId: 0,
      type: type,
      state: MessageState.pending,
      filePath: filePath,
      fileMimeType: mimeType,
      text: caption,
      timestamp: DateTime.now(),
      isOutgoing: true,
    );
    state = state.copyWith(messages: [tempMsg, ...state.messages]);
    try {
      final id = await rpc.sendFileMessage(
        chatId: chatId,
        filePath: filePath,
        mimeType: mimeType,
        caption: caption,
      );
      final updated = state.messages.map((m) {
        if (m.id == tempId) return m.copyWith(id: id, state: MessageState.sent);
        return m;
      }).toList();
      state = state.copyWith(messages: updated);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void setReply(int messageId, String text) {
    state = state.copyWith(replyToMessageId: messageId, replyToText: text);
  }

  void clearReply() {
    state = state.copyWith(clearReply: true);
  }

  Future<void> deleteMessage(int messageId) async {
    await ref.read(deltaRpcClientProvider).deleteMessage(messageId);
    state = state.copyWith(
      messages: state.messages.where((m) => m.id != messageId).toList(),
    );
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _loadMessages();
  }

  Message _mapMessage(Map<String, dynamic> d) => Message(
    id: (d['id'] as num?)?.toInt() ?? 0,
    chatId: (d['chat_id'] as num?)?.toInt() ?? chatId,
    fromContactId: (d['from'] as num?)?.toInt() ?? 0,
    type: _mapType(d['type'] as int? ?? 10),
    state: _mapState(d['state'] as int? ?? 0),
    text: d['text'] as String?,
    filePath: d['file'] as String?,
    fileMimeType: d['mime'] as String?,
    fileName: d['file_name'] as String?,
    fileBytes: (d['file_bytes'] as num?)?.toInt(),
    durationMs: (d['duration'] as num?)?.toInt(),
    timestamp: DateTime.fromMillisecondsSinceEpoch((d['ts'] as int? ?? 0) * 1000),
    isOutgoing: d['is_outgoing'] as bool? ?? false,
    isForwarded: d['is_forwarded'] as bool? ?? false,
    isInfo: d['is_info'] as bool? ?? false,
    showPadlock: d['show_padlock'] as bool? ?? false,
    quotedMessageId: (d['quoted_message_id'] as num?)?.toInt(),
    quotedText: d['quoted_text'] as String?,
  );

  MessageType _mapType(int t) => switch (t) {
    20 => MessageType.image,
    21 => MessageType.video,
    23 => MessageType.gif,
    40 => MessageType.audio,
    41 => MessageType.voice,
    60 => MessageType.file,
    80 => MessageType.location,
    _ => MessageType.text,
  };

  MessageState _mapState(int s) => switch (s) {
    1 => MessageState.sent,
    2 => MessageState.delivered,
    3 => MessageState.read,
    4 => MessageState.failed,
    _ => MessageState.pending,
  };

  MessageType _mimeToType(String mime) {
    if (mime.startsWith('image/')) return MessageType.image;
    if (mime.startsWith('video/')) return MessageType.video;
    if (mime.startsWith('audio/')) return MessageType.audio;
    return MessageType.file;
  }
}
