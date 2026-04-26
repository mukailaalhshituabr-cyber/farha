// lib/presentation/screens/customer/notifications/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/notification_model.dart';
import '../../../../routes/app_router.dart';
import '../../../providers/notification_provider.dart';
import '../../../widgets/common/farha_bottom_nav.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0, scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text('Notifications',
            style: AppTheme.titleLarge
                .copyWith(fontFamily: 'PlusJakartaSans')),
        actions: [
          if (state.unreadCount > 0)
            TextButton(
              onPressed: () =>
                  ref.read(notificationProvider.notifier).markAllRead(),
              child: Text('Mark all read',
                  style: AppTheme.labelSmall
                      .copyWith(color: AppColors.primary)),
            ),
        ],
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : state.items.isEmpty
              ? _EmptyState()
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () =>
                      ref.read(notificationProvider.notifier).load(),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: state.items.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 0, indent: 72),
                    itemBuilder: (_, i) => _NotificationTile(
                      notification: state.items[i],
                      onTap: () {
                        ref.read(notificationProvider.notifier)
                            .markRead(state.items[i].id);
                        _navigate(context, state.items[i]);
                      },
                    ),
                  ),
                ),
      bottomNavigationBar: const CustomerBottomNav(currentIndex: 0),
    );
  }
}

// ── Navigation helper ──────────────────────────────────────────────────────────

void _navigate(BuildContext context, NotificationModel n) {
  final id = n.referenceId;
  if (id == null || id.isEmpty) return;
  switch (n.type) {
    case 'order_status':
    case 'payment':
      context.push(Routes.orderDetail.replaceFirst(':id', id));
    case 'message':
      context.push(Routes.chatScreen.replaceFirst(':id', id));
  }
}

// ── Notification tile ──────────────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  const _NotificationTile({required this.notification, required this.onTap});

  IconData get _icon => switch (notification.type) {
    'order_status' => Icons.receipt_long_rounded,
    'message'      => Icons.chat_bubble_rounded,
    'payment'      => Icons.account_balance_wallet_rounded,
    'review'       => Icons.star_rounded,
    _              => Icons.notifications_rounded,
  };

  Color get _color => switch (notification.type) {
    'order_status' => AppColors.primary,
    'message'      => AppColors.secondary,
    'payment'      => AppColors.success,
    'review'       => AppColors.secondary,
    _              => AppColors.info,
  };

  @override
  Widget build(BuildContext context) => Container(
    color: notification.isRead
        ? null
        : AppColors.primaryFixed.withValues(alpha: 0.3),
    child: ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      onTap: onTap,
      leading: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(_icon, color: _color, size: 20),
      ),
      title: Text(notification.title,
          style: AppTheme.titleSmall.copyWith(
            fontWeight: notification.isRead
                ? FontWeight.w400 : FontWeight.w600,
          )),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(notification.body,
              style: AppTheme.bodySmall
                  .copyWith(color: AppColors.onSurfaceVariant),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(AppFormatters.relativeTime(notification.createdAt),
              style: AppTheme.labelSmall
                  .copyWith(color: AppColors.outline)),
        ],
      ),
      trailing: notification.isRead
          ? null
          : Container(
              width: 8, height: 8,
              decoration: const BoxDecoration(
                  color: AppColors.primary, shape: BoxShape.circle),
            ),
    ),
  );
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.notifications_none_rounded,
          color: AppColors.outline, size: 56),
      const SizedBox(height: 12),
      Text('No notifications yet',
          style: AppTheme.titleSmall
              .copyWith(color: AppColors.onSurfaceVariant)),
      const SizedBox(height: 4),
      Text("You're all caught up!",
          style: AppTheme.bodySmall.copyWith(color: AppColors.outline)),
    ]),
  );
}
