// lib/presentation/widgets/common/farha_bottom_nav.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/cart_provider.dart';
import '../../providers/chat_provider.dart';
import '../../../routes/app_router.dart';

// ── Customer bottom nav ───────────────────────────────────────────────────
class CustomerBottomNav extends ConsumerWidget {
  final int currentIndex;

  const CustomerBottomNav({super.key, required this.currentIndex});

  static const _routes = [
    Routes.customerDashboard,
    Routes.productListing,
    Routes.orderHistory,
    Routes.chatInbox,
    Routes.customerProfile,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(cartCountProvider);
    final chatUnread = ref.watch(conversationProvider).totalUnread;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(top: BorderSide(color: AppColors.outlineVariant, width: 0.5)),
      ),
      child: NavigationBar(
        backgroundColor:  AppColors.surfaceContainerLowest,
        selectedIndex:    currentIndex,
        indicatorColor:   AppColors.primaryFixed,
        onDestinationSelected: (i) => context.go(_routes[i]),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront_rounded),
            label: 'Shop',
          ),
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: _BadgeIcon(
              icon: Icons.chat_bubble_outline_rounded,
              count: chatUnread,
            ),
            selectedIcon: _BadgeIcon(
              icon: Icons.chat_bubble_rounded,
              count: chatUnread,
            ),
            label: 'Messages',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ── Tailor bottom nav ─────────────────────────────────────────────────────
class TailorBottomNav extends ConsumerWidget {
  final int currentIndex;

  const TailorBottomNav({super.key, required this.currentIndex});

  static const _routes = [
    Routes.tailorDashboard,
    Routes.tailorOrderManagement,
    Routes.tailorProductManagement,
    Routes.tailorChatInbox,
    Routes.tailorProfile,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatUnread = ref.watch(conversationProvider).totalUnread;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(top: BorderSide(color: AppColors.outlineVariant, width: 0.5)),
      ),
      child: NavigationBar(
        backgroundColor:  AppColors.surfaceContainerLowest,
        selectedIndex:    currentIndex,
        indicatorColor:   AppColors.primaryFixed,
        onDestinationSelected: (i) => context.go(_routes[i]),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.content_cut_outlined),
            selectedIcon: Icon(Icons.content_cut_rounded),
            label: 'Orders',
          ),
          const NavigationDestination(
            icon: Icon(Icons.dry_cleaning_outlined),
            selectedIcon: Icon(Icons.dry_cleaning_rounded),
            label: 'Products',
          ),
          NavigationDestination(
            icon: _BadgeIcon(icon: Icons.chat_bubble_outline_rounded, count: chatUnread),
            selectedIcon: _BadgeIcon(icon: Icons.chat_bubble_rounded, count: chatUnread),
            label: 'Messages',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ── Badge icon (for unread counts) ───────────────────────────────────────
class _BadgeIcon extends StatelessWidget {
  final IconData icon;
  final int      count;

  const _BadgeIcon({required this.icon, required this.count});

  @override
  Widget build(BuildContext context) {
    if (count == 0) return Icon(icon);
    return Badge(
      label: Text(count > 99 ? '99+' : '$count',
          style: AppTheme.labelSmall.copyWith(color: Colors.white, fontSize: 9)),
      backgroundColor: AppColors.error,
      child: Icon(icon),
    );
  }
}
