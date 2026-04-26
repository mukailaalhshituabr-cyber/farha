// lib/data/models/notification_model.dart

class NotificationModel {
  final String  id;
  final String  title;
  final String  body;
  final String  type;         // 'order_status' | 'message' | 'payment' | 'general'
  final String? referenceId;
  final bool    isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.referenceId,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> j) => NotificationModel(
    id:          j['id'].toString(),
    title:       j['title'] as String? ?? '',
    body:        j['body'] as String? ?? '',
    type:        j['type'] as String? ?? 'general',
    referenceId: j['reference_id']?.toString(),
    isRead:      j['is_read'] == true || j['is_read'] == 1,
    createdAt:   DateTime.tryParse(j['created_at'] as String? ?? '') ?? DateTime.now(),
  );
}
