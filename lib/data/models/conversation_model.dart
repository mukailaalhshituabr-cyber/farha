// lib/data/models/conversation_model.dart

class ConversationModel {
  final String  id;
  final String  customerId;
  final String  customerName;
  final String? customerPhoto;
  final String  tailorId;
  final String  tailorName;
  final String  shopName;
  final String? tailorPhoto;
  final String? orderId;
  final String? orderRef;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int     unreadCount;  // count, not a UUID — stays int

  const ConversationModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    this.customerPhoto,
    required this.tailorId,
    required this.tailorName,
    required this.shopName,
    this.tailorPhoto,
    this.orderId,
    this.orderRef,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> j, {bool isCustomer = true}) =>
      ConversationModel(
        id:            j['id'].toString(),
        customerId:    j['customer_id'].toString(),
        customerName:  j['customer_name'] as String? ?? '',
        customerPhoto: j['customer_photo'] as String?,
        tailorId:      j['tailor_id'].toString(),
        tailorName:    j['tailor_name'] as String? ?? '',
        shopName:      j['shop_name'] as String? ?? '',
        tailorPhoto:   j['tailor_photo'] as String?,
        orderId:       j['order_id']?.toString(),
        orderRef:      j['order_ref'] as String?,
        lastMessage:   j['last_message'] as String?,
        lastMessageAt: j['last_message_at'] != null
            ? DateTime.tryParse(j['last_message_at'].toString()) : null,
        unreadCount: isCustomer
            ? (j['customer_unread'] as int? ?? 0)
            : (j['tailor_unread'] as int? ?? 0),
      );
}

// ─────────────────────────────────────────────────────────────────────────────

class MessageModel {
  final String  id;
  final String  conversationId;
  final String  senderId;
  final String? messageText;
  final String? imageUrl;
  final bool    isRead;
  final DateTime createdAt;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.messageText,
    this.imageUrl,
    required this.isRead,
    required this.createdAt,
  });

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
  bool get hasText  => messageText != null && messageText!.isNotEmpty;

  factory MessageModel.fromJson(Map<String, dynamic> j) => MessageModel(
    id:             j['id'].toString(),
    conversationId: j['conversation_id'].toString(),
    senderId:       j['sender_id'].toString(),
    messageText:    j['message_text'] as String?,
    imageUrl:       j['image_url'] as String?,
    isRead:         j['is_read'] == 1 || j['is_read'] == true,
    createdAt:      DateTime.parse(j['created_at'] as String),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

class NotificationModel {
  final String  id;
  final String  userId;
  final String  title;
  final String  body;
  final String  type;   // 'order_update'|'payment'|'message'|'review'|'system'
  final String? referenceId;
  final String? referenceType;
  final bool    isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.referenceId,
    this.referenceType,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> j) => NotificationModel(
    id:            j['id'].toString(),
    userId:        j['user_id'].toString(),
    title:         j['title'] as String,
    body:          j['body'] as String,
    type:          j['type'] as String,
    referenceId:   j['reference_id']?.toString(),
    referenceType: j['reference_type'] as String?,
    isRead:        j['is_read'] == 1 || j['is_read'] == true,
    createdAt:     DateTime.parse(j['created_at'] as String),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

class ReviewModel {
  final String  id;
  final String  orderId;
  final String  customerId;
  final String  customerName;
  final String? customerPhoto;
  final String  tailorId;
  final String? productId;
  final int     rating;    // 1–5, not a UUID — stays int
  final String? comment;
  final DateTime createdAt;

  const ReviewModel({
    required this.id,
    required this.orderId,
    required this.customerId,
    required this.customerName,
    this.customerPhoto,
    required this.tailorId,
    this.productId,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> j) => ReviewModel(
    id:            j['id'].toString(),
    orderId:       j['order_id'].toString(),
    customerId:    j['customer_id'].toString(),
    customerName:  j['customer_name'] as String? ?? '',
    customerPhoto: j['customer_photo'] as String?,
    tailorId:      j['tailor_id'].toString(),
    productId:     j['product_id']?.toString(),
    rating:        j['rating'] as int,
    comment:       j['comment'] as String?,
    createdAt:     DateTime.parse(j['created_at'] as String),
  );
}
