// lib/presentation/providers/chat_provider.dart
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/models/conversation_model.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/services/notification_service.dart';
import 'auth_provider.dart';
import 'order_provider.dart' show chatRepositoryProvider;

// ── Conversations ─────────────────────────────────────────────────────────
class ConversationState {
  final List<ConversationModel> items;
  final bool    isLoading;
  final String? error;
  final int     totalUnread;

  const ConversationState({
    this.items       = const [],
    this.isLoading   = false,
    this.error,
    this.totalUnread = 0,
  });
}

class ConversationNotifier extends StateNotifier<ConversationState> {
  final ChatRepository _repo;
  final bool           _isCustomer;

  ConversationNotifier(this._repo, {required bool isCustomer})
      : _isCustomer = isCustomer,
        super(const ConversationState()) {
    load();
  }

  Future<void> load() async {
    state = const ConversationState(isLoading: true);
    final result = await _repo.getConversations(isCustomer: _isCustomer);
    if (!result.success) {
      state = ConversationState(error: result.error);
      return;
    }
    final unread = result.items.fold<int>(0, (s, c) => s + c.unreadCount);
    state = ConversationState(items: result.items, totalUnread: unread);
  }

  void refresh() => load();
}

final conversationProvider =
    StateNotifierProvider<ConversationNotifier, ConversationState>((ref) {
  final user = ref.watch(authProvider).user;
  return ConversationNotifier(
    ref.watch(chatRepositoryProvider),
    isCustomer: user?.isCustomer ?? true,
  );
});

// ── Messages for one conversation ─────────────────────────────────────────
class MessageState {
  final List<MessageModel> messages;
  final bool    isLoading;
  final bool    isSending;
  final bool    hasMore;
  final String? error;
  final int     page;

  const MessageState({
    this.messages  = const [],
    this.isLoading = false,
    this.isSending = false,
    this.hasMore   = true,
    this.error,
    this.page      = 1,
  });

  MessageState copyWith({
    List<MessageModel>? messages, bool? isLoading,
    bool? isSending, bool? hasMore, String? error, int? page,
  }) => MessageState(
    messages:  messages  ?? this.messages,
    isLoading: isLoading ?? this.isLoading,
    isSending: isSending ?? this.isSending,
    hasMore:   hasMore   ?? this.hasMore,
    error:     error,
    page:      page      ?? this.page,
  );
}

class MessageNotifier extends StateNotifier<MessageState> {
  final ChatRepository _repo;
  final String         _conversationId;
  final String         _currentUserId;
  int                  _lastKnownCount = -1; // -1 = initial load, no notification

  MessageNotifier(this._repo, this._conversationId, this._currentUserId)
      : super(const MessageState()) {
    load();
    _repo.markRead(_conversationId);
  }

  Future<void> load({bool refresh = false}) async {
    if (state.isLoading && !refresh) return;
    final page = refresh ? 1 : state.page;
    state = state.copyWith(isLoading: true, page: page);

    final result = await _repo.getMessages(_conversationId, page: page);
    if (!result.success) {
      state = state.copyWith(isLoading: false, error: result.error);
      return;
    }

    final msgs = refresh
        ? result.items
        : [...result.items, ...state.messages];

    // Notify when a poll detects NEW messages from the other user
    if (refresh && _lastKnownCount >= 0 && msgs.length > _lastKnownCount) {
      final newest = msgs.last;
      if (newest.senderId != _currentUserId) {
        HapticFeedback.mediumImpact();
        NotificationService.showMessage(
          title: 'New message',
          body:  newest.messageText ?? '📷 Image',
        );
      }
    }
    _lastKnownCount = msgs.length;

    state = state.copyWith(
      messages:  msgs,
      hasMore:   result.hasMore,
      isLoading: false,
      page:      page + 1,
    );
  }

  // Returns null on success, or the server error message on failure.
  Future<String?> sendMessage({String? text, String? imageUrl}) async {
    if ((text == null || text.isEmpty) && imageUrl == null) return null;

    // Optimistic insert — show the message immediately before the API replies
    final optimistic = MessageModel(
      id:             '_pending_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: _conversationId,
      senderId:       _currentUserId,
      messageText:    text,
      imageUrl:       imageUrl,
      isRead:         false,
      createdAt:      DateTime.now(),
    );
    state = state.copyWith(
      messages:  [...state.messages, optimistic],
      isSending: true,
    );

    final res = await _repo.sendMessage(
      conversationId: _conversationId,
      text:           text,
      imageUrl:       imageUrl,
    );

    if (res.success) {
      // Server returns the confirmed message — swap optimistic for the real one
      // without an extra network round-trip, avoiding the poll-timer race.
      MessageModel? confirmed;
      try {
        final msgJson = (res.data as Map<String, dynamic>?)?['message']
            as Map<String, dynamic>?;
        if (msgJson != null) confirmed = MessageModel.fromJson(msgJson);
      } catch (_) {}

      if (confirmed != null) {
        state = state.copyWith(
          messages: state.messages
              .map((m) => m.id == optimistic.id ? confirmed! : m)
              .toList(),
          isSending: false,
        );
      } else {
        // Fallback if server omitted the message object
        await load(refresh: true);
        state = state.copyWith(isSending: false);
      }
      return null; // success
    } else {
      // Remove the optimistic message; caller (_send) shows a snackbar
      state = state.copyWith(
        messages:  state.messages.where((m) => m.id != optimistic.id).toList(),
        isSending: false,
      );
      return res.message.isNotEmpty ? res.message : 'Send failed (status ${res.statusCode}).';
    }
  }

  void refresh() => load(refresh: true);
}

final messageProvider =
    StateNotifierProvider.family<MessageNotifier, MessageState, String>(
        (ref, conversationId) {
  final userId = ref.watch(authProvider).user?.id ?? '';
  return MessageNotifier(
    ref.watch(chatRepositoryProvider),
    conversationId,
    userId,
  );
});

// ── Notification badge ────────────────────────────────────────────────────
final notificationCountProvider = StateProvider<int>((ref) => 0);
