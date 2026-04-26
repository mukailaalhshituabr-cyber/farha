// lib/presentation/providers/notification_provider.dart
import 'package:flutter_riverpod/legacy.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../data/models/notification_model.dart';
import 'auth_provider.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class NotificationState {
  final List<NotificationModel> items;
  final int    unreadCount;
  final bool   isLoading;
  final String? error;

  const NotificationState({
    this.items       = const [],
    this.unreadCount = 0,
    this.isLoading   = false,
    this.error,
  });

  NotificationState copyWith({
    List<NotificationModel>? items,
    int?    unreadCount,
    bool?   isLoading,
    String? error,
  }) => NotificationState(
    items:       items       ?? this.items,
    unreadCount: unreadCount ?? this.unreadCount,
    isLoading:   isLoading   ?? this.isLoading,
    error:       error,
  );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class NotificationNotifier extends StateNotifier<NotificationState> {
  final ApiClient _api;

  NotificationNotifier(this._api) : super(const NotificationState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    final res = await _api.get(ApiConstants.notificationList);
    if (!res.success) {
      state = state.copyWith(isLoading: false, error: res.message);
      return;
    }
    final data  = res.data as Map<String, dynamic>;
    final items = (data['notifications'] as List<dynamic>? ?? [])
        .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
        .toList();
    state = NotificationState(
      items:       items,
      unreadCount: (data['unread_count'] as num?)?.toInt() ?? 0,
    );
  }

  Future<void> markRead(String notificationId) async {
    state = state.copyWith(
      items: state.items.map((n) => n.id == notificationId
          ? _asRead(n) : n).toList(),
      unreadCount: (state.unreadCount - 1).clamp(0, state.unreadCount),
    );
    await _api.put(ApiConstants.notificationMarkRead,
        data: {'notification_id': notificationId});
  }

  Future<void> markAllRead() async {
    state = state.copyWith(
      items: state.items.map(_asRead).toList(),
      unreadCount: 0,
    );
    await _api.put(ApiConstants.notificationMarkRead, data: {});
  }

  void refresh() => load();

  NotificationModel _asRead(NotificationModel n) => NotificationModel(
    id:          n.id,
    title:       n.title,
    body:        n.body,
    type:        n.type,
    referenceId: n.referenceId,
    isRead:      true,
    createdAt:   n.createdAt,
  );
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>(
        (ref) => NotificationNotifier(ref.watch(apiClientProvider)));
