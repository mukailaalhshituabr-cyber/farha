// lib/presentation/screens/messages/chat_inbox_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/conversation_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/common/farha_bottom_nav.dart';

class ChatInboxScreen extends ConsumerWidget {
  const ChatInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l       = AppL10n.of(context);
    final user    = ref.watch(authProvider).user;
    final isTailor = user?.isTailor ?? false;
    final state   = ref.watch(conversationProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(l.messages,
            style: AppTheme.titleLarge.copyWith(fontFamily: 'PlusJakartaSans')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: AppColors.onBackground, size: 22),
            onPressed: () =>
                ref.read(conversationProvider.notifier).refresh(),
          ),
        ],
      ),
      body: _buildBody(context, ref, l, state, user?.id ?? '', isTailor),
      bottomNavigationBar: isTailor
          ? const TailorBottomNav(currentIndex: 3)
          : const CustomerBottomNav(currentIndex: 3),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    AppL10n l,
    ConversationState state,
    String currentUserId,
    bool isTailor,
  ) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (state.error != null && state.items.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.wifi_off_rounded,
              color: AppColors.outline, size: 48),
          const SizedBox(height: 12),
          Text(l.somethingWrong,
              style: AppTheme.titleSmall
                  .copyWith(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () =>
                ref.read(conversationProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: Text(l.retry),
          ),
        ]),
      );
    }

    if (state.items.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.chat_bubble_outline_rounded,
              color: AppColors.outline, size: 56),
          const SizedBox(height: 16),
          Text(l.messages,
              style: AppTheme.titleMedium
                  .copyWith(color: AppColors.onSurface)),
          const SizedBox(height: 6),
          Text(l.noResults,
              style: AppTheme.bodyMedium
                  .copyWith(color: AppColors.onSurfaceVariant)),
        ]),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async =>
          ref.read(conversationProvider.notifier).refresh(),
      child: ListView.separated(
        itemCount: state.items.length,
        separatorBuilder: (_, __) =>
            const Divider(indent: 72, endIndent: 16, height: 1),
        itemBuilder: (context, i) {
          final conv = state.items[i];
          return _ConversationTile(
            conversation: conv,
            currentUserId: currentUserId,
            isTailor: isTailor,
            onTap: () {
              final route = isTailor
                  ? '/tailor/chat/${conv.id}'
                  : '/customer/chat/${conv.id}';
              context.push(route, extra: conv);
            },
          );
        },
      ),
    );
  }
}

// ── Single conversation row ──────────────────────────────────────────────────

class _ConversationTile extends StatelessWidget {
  final ConversationModel conversation;
  final String       currentUserId;
  final bool         isTailor;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.currentUserId,
    required this.isTailor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Customer sees tailor's info; tailor sees customer's info
    final displayName = isTailor
        ? conversation.customerName
        : conversation.shopName.isNotEmpty
            ? conversation.shopName
            : conversation.tailorName;
    final photoUrl = isTailor
        ? conversation.customerPhoto
        : conversation.tailorPhoto;
    final hasUnread = conversation.unreadCount > 0;

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      onTap: onTap,
      leading: _Avatar(photoUrl: photoUrl, name: displayName),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              displayName,
              style: AppTheme.titleSmall.copyWith(
                fontWeight:
                    hasUnread ? FontWeight.w700 : FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (conversation.lastMessageAt != null) ...[
            const SizedBox(width: 8),
            Text(
              _formatTime(conversation.lastMessageAt!),
              style: AppTheme.labelSmall.copyWith(
                color: hasUnread
                    ? AppColors.primary
                    : AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              conversation.lastMessage ?? '...',
              style: AppTheme.bodySmall.copyWith(
                color: hasUnread
                    ? AppColors.onSurface
                    : AppColors.onSurfaceVariant,
                fontWeight: hasUnread
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (hasUnread) ...[
            const SizedBox(width: 8),
            Container(
              constraints: const BoxConstraints(minWidth: 20),
              height: 20,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Center(
                child: Text(
                  conversation.unreadCount > 99
                      ? '99+'
                      : '${conversation.unreadCount}',
                  style: AppTheme.labelSmall.copyWith(
                      color: Colors.white, fontSize: 10),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now  = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7)  return _weekday(dt.weekday);
    return '${dt.day}/${dt.month}';
  }

  String _weekday(int w) => const [
    '', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
  ][w];
}

// ── Avatar widget ─────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String? photoUrl;
  final String  name;

  const _Avatar({required this.photoUrl, required this.name});

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isNotEmpty
        ? name.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join()
        : '?';

    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 26,
        backgroundColor: AppColors.primaryFixed,
        backgroundImage: CachedNetworkImageProvider(photoUrl!),
      );
    }
    return CircleAvatar(
      radius: 26,
      backgroundColor: AppColors.primaryFixed,
      child: Text(
        initials.toUpperCase(),
        style: AppTheme.titleSmall.copyWith(
            color: AppColors.primary, fontWeight: FontWeight.w700),
      ),
    );
  }
}
