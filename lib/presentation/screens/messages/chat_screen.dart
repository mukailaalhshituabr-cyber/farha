// lib/presentation/screens/messages/chat_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/conversation_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final ConversationModel? conversation; // passed as extra for header info

  const ChatScreen({
    super.key,
    required this.conversationId,
    this.conversation,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _textCtrl   = TextEditingController();
  final _scrollCtrl = ScrollController();
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (mounted) {
        ref.read(messageProvider(widget.conversationId).notifier).refresh();
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      if (animated) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
      }
    });
  }

  Future<void> _send() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    _textCtrl.clear();
    final error = await ref
        .read(messageProvider(widget.conversationId).notifier)
        .sendMessage(text: text);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Send failed: $error'),
          backgroundColor: const Color(0xFFB3261E),
          duration: const Duration(seconds: 6),
        ),
      );
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final l       = AppL10n.of(context);
    final user    = ref.watch(authProvider).user;
    final isTailor = user?.isTailor ?? false;
    final msgState = ref.watch(messageProvider(widget.conversationId));
    final conv     = widget.conversation;

    // Derive header title from conversation
    final headerName = conv == null
        ? ''
        : isTailor
            ? conv.customerName
            : conv.shopName.isNotEmpty
                ? conv.shopName
                : conv.tailorName;
    final headerPhoto = conv == null
        ? null
        : isTailor
            ? conv.customerPhoto
            : conv.tailorPhoto;

    // Auto-scroll when messages load
    if (!msgState.isLoading && msgState.messages.isNotEmpty) {
      _scrollToBottom(animated: false);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 40,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.onBackground, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(children: [
          _SmallAvatar(photoUrl: headerPhoto, name: headerName),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              headerName,
              style: AppTheme.titleMedium
                  .copyWith(fontFamily: 'PlusJakartaSans'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: AppColors.onBackground, size: 22),
            onPressed: () => ref
                .read(messageProvider(widget.conversationId).notifier)
                .refresh(),
          ),
        ],
      ),
      body: Column(children: [
        // ── Message list ───────────────────────────────────────────
        Expanded(child: _buildMessageList(context, l, msgState, user?.id ?? '')),

        // ── Input bar ──────────────────────────────────────────────
        _InputBar(
          controller: _textCtrl,
          isSending:  msgState.isSending,
          onSend:     _send,
          hint:       l.messages,
        ),
      ]),
    );
  }

  Widget _buildMessageList(
    BuildContext context,
    AppL10n l,
    MessageState state,
    String currentUserId,
  ) {
    if (state.isLoading && state.messages.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (state.error != null && state.messages.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.wifi_off_rounded,
              color: AppColors.outline, size: 48),
          const SizedBox(height: 12),
          Text(l.somethingWrong,
              style: AppTheme.bodyMedium
                  .copyWith(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => ref
                .read(messageProvider(widget.conversationId).notifier)
                .refresh(),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: Text(l.retry),
          ),
        ]),
      );
    }

    if (state.messages.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.chat_bubble_outline_rounded,
              color: AppColors.outline, size: 48),
          const SizedBox(height: 12),
          Text('Start the conversation',
              style: AppTheme.bodyMedium
                  .copyWith(color: AppColors.onSurfaceVariant)),
        ]),
      );
    }

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      itemCount: state.messages.length,
      itemBuilder: (_, i) {
        final msg    = state.messages[i];
        final isMe   = msg.senderId == currentUserId;
        final showDate = i == 0 ||
            !_sameDay(state.messages[i - 1].createdAt, msg.createdAt);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showDate) _DateChip(date: msg.createdAt),
            _MessageBubble(
              text:    msg.messageText,
              imageUrl: msg.imageUrl,
              isMe:    isMe,
              time:    msg.createdAt,
            ),
          ],
        );
      },
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ── Message bubble ───────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final String?  text;
  final String?  imageUrl;
  final bool     isMe;
  final DateTime time;

  const _MessageBubble({
    required this.text,
    required this.imageUrl,
    required this.isMe,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor  = isMe ? AppColors.primary : AppColors.surfaceContainerLow;
    final txtColor = isMe ? Colors.white : AppColors.onSurface;
    final timeColor = isMe
        ? Colors.white.withValues(alpha: 0.7)
        : AppColors.onSurfaceVariant;
    final align  = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final radius = isMe
        ? const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(4),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(18),
          );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment: align,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72,
            ),
            child: Container(
              decoration: BoxDecoration(
                  color: bgColor, borderRadius: radius),
              padding: imageUrl != null && (text == null || text!.isEmpty)
                  ? EdgeInsets.zero
                  : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (imageUrl != null && imageUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: text != null && text!.isNotEmpty
                          ? const BorderRadius.vertical(
                              top: Radius.circular(14))
                          : radius,
                      child: CachedNetworkImage(
                        imageUrl: imageUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (_, __) => const SizedBox(
                            height: 160,
                            child: Center(
                                child: CircularProgressIndicator(
                                    strokeWidth: 2))),
                        errorWidget: (_, __, ___) => const SizedBox(
                          height: 100,
                          child: Center(
                              child: Icon(Icons.broken_image_outlined,
                                  color: AppColors.outline)),
                        ),
                      ),
                    ),
                  if (text != null && text!.isNotEmpty)
                    Padding(
                      padding: imageUrl != null && imageUrl!.isNotEmpty
                          ? const EdgeInsets.fromLTRB(14, 8, 14, 10)
                          : EdgeInsets.zero,
                      child: Text(text!,
                          style: AppTheme.bodyMedium
                              .copyWith(color: txtColor)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _formatTime(time),
            style: AppTheme.labelSmall
                .copyWith(color: timeColor, fontSize: 10),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ── Date chip ─────────────────────────────────────────────────────────────────

class _DateChip extends StatelessWidget {
  final DateTime date;
  const _DateChip({required this.date});

  @override
  Widget build(BuildContext context) {
    final now  = DateTime.now();
    final diff = DateTime(now.year, now.month, now.day)
        .difference(DateTime(date.year, date.month, date.day))
        .inDays;
    final label = diff == 0
        ? 'Today'
        : diff == 1
            ? 'Yesterday'
            : '${date.day}/${date.month}/${date.year}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(label,
              style: AppTheme.labelSmall
                  .copyWith(color: AppColors.onSurfaceVariant)),
        ),
        const Expanded(child: Divider()),
      ]),
    );
  }
}

// ── Input bar ─────────────────────────────────────────────────────────────────

class _InputBar extends StatefulWidget {
  final TextEditingController controller;
  final bool          isSending;
  final VoidCallback  onSend;
  final String        hint;

  const _InputBar({
    required this.controller,
    required this.isSending,
    required this.onSend,
    required this.hint,
  });

  @override
  State<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<_InputBar> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChange);
  }

  void _onTextChange() {
    final has = widget.controller.text.trim().isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          12, 8, 12, MediaQuery.of(context).padding.bottom + 8),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(
            top: BorderSide(color: AppColors.outlineVariant, width: 0.5)),
      ),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: widget.controller,
            maxLines: 5,
            minLines: 1,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: AppTheme.bodyMedium
                  .copyWith(color: AppColors.onSurfaceVariant),
              filled: true,
              fillColor: AppColors.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
            ),
            onSubmitted: (_) => widget.onSend(),
          ),
        ),
        const SizedBox(width: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: widget.isSending
              ? const SizedBox(
                  key: ValueKey('loading'),
                  width: 44,
                  height: 44,
                  child: Center(
                      child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: AppColors.primary),
                  )),
                )
              : IconButton(
                  key: const ValueKey('send'),
                  onPressed: _hasText ? widget.onSend : null,
                  icon: Icon(Icons.send_rounded,
                      color: _hasText
                          ? AppColors.primary
                          : AppColors.outline),
                  style: IconButton.styleFrom(
                    backgroundColor: _hasText
                        ? AppColors.primaryFixed
                        : AppColors.surfaceContainerLow,
                    fixedSize: const Size(44, 44),
                  ),
                ),
        ),
      ]),
    );
  }
}

// ── Small avatar for AppBar ───────────────────────────────────────────────────

class _SmallAvatar extends StatelessWidget {
  final String? photoUrl;
  final String  name;
  const _SmallAvatar({required this.photoUrl, required this.name});

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isNotEmpty
        ? name.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join()
        : '?';
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 18,
        backgroundColor: AppColors.primaryFixed,
        backgroundImage: CachedNetworkImageProvider(photoUrl!),
      );
    }
    return CircleAvatar(
      radius: 18,
      backgroundColor: AppColors.primaryFixed,
      child: Text(
        initials.toUpperCase(),
        style: AppTheme.labelSmall.copyWith(
            color: AppColors.primary, fontWeight: FontWeight.w700),
      ),
    );
  }
}
