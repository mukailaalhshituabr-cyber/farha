// lib/data/repositories/chat_repository.dart
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/conversation_model.dart';

class ChatRepository {
  final ApiClient _api;
  const ChatRepository(this._api);

  Future<ConversationListResult> getConversations({bool isCustomer = true}) async {
    final res = await _api.get(ApiConstants.conversations);
    if (!res.success) return ConversationListResult.error(res.message);
    final data = res.data as Map<String, dynamic>;
    final items = (data['conversations'] as List<dynamic>? ?? [])
        .map((e) => ConversationModel.fromJson(
              e as Map<String, dynamic>,
              isCustomer: isCustomer,
            ))
        .toList();
    return ConversationListResult.success(items);
  }

  Future<MessageListResult> getMessages(String conversationId, {int page = 1}) async {
    final res = await _api.get(ApiConstants.messages,
        params: {'conversation_id': conversationId, 'page': page});
    if (!res.success) return MessageListResult.error(res.message);
    final data  = res.data as Map<String, dynamic>;
    final items = (data['messages'] as List<dynamic>? ?? [])
        .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return MessageListResult.success(
      items:   items,
      hasMore: data['has_more'] as bool? ?? false,
    );
  }

  Future<ApiResponse> sendMessage({
    required String conversationId,
    String?      text,
    String?      imageUrl,
  }) =>
      _api.post(ApiConstants.messages, data: {
        'conversation_id': conversationId,
        if (text != null)     'message_text': text,
        if (imageUrl != null) 'image_url':    imageUrl,
      });

  Future<ApiResponse> markRead(String conversationId) =>
      _api.put(ApiConstants.markRead,
          data: {'conversation_id': conversationId});
}

class ConversationListResult {
  final bool                    success;
  final List<ConversationModel> items;
  final String                  error;

  const ConversationListResult._({required this.success, this.items = const [], this.error = ''});

  factory ConversationListResult.success(List<ConversationModel> items) =>
      ConversationListResult._(success: true, items: items);
  factory ConversationListResult.error(String msg) =>
      ConversationListResult._(success: false, error: msg);
}

class MessageListResult {
  final bool              success;
  final List<MessageModel> items;
  final bool              hasMore;
  final String            error;

  const MessageListResult._({required this.success, this.items = const [], this.hasMore = false, this.error = ''});

  factory MessageListResult.success({required List<MessageModel> items, bool hasMore = false}) =>
      MessageListResult._(success: true, items: items, hasMore: hasMore);
  factory MessageListResult.error(String msg) =>
      MessageListResult._(success: false, error: msg);
}
