// lib/presentation/screens/admin/admin_users_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/farha_snackbar.dart';
import 'admin_shell.dart';

final _usersProvider = FutureProvider.family<Map<String, dynamic>, String>(
  (ref, type) async {
    final api = ref.watch(apiClientProvider);
    final res = await api.get(ApiConstants.adminUsers,
        params: {'type': type, 'limit': 50});
    if (!res.success) throw Exception(res.message);
    return res.data as Map<String, dynamic>;
  },
);

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});
  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) {
        setState(() => _filter = ['all', 'tailor', 'customer'][_tabs.index]);
      }
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _toggleSuspend(Map<String, dynamic> user) async {
    final isActive = user['is_active'] as bool? ?? true;
    final action   = isActive ? 'suspend' : 'unsuspend';
    final res = await ref.read(apiClientProvider)
        .post(ApiConstants.adminUsers, data: {'user_id': user['id'], 'action': action});
    if (!mounted) return;
    if (res.success) {
      FarhaSnackbar.success(context, isActive ? 'User suspended.' : 'User unsuspended.');
      ref.invalidate(_usersProvider(_filter));
    } else {
      FarhaSnackbar.error(context, res.message);
    }
  }

  Future<void> _tailorAction(String tailorId, String action) async {
    final res = await ref.read(apiClientProvider)
        .post(ApiConstants.adminTailorApprove, data: {'tailor_id': tailorId, 'action': action});
    if (!mounted) return;
    if (res.success) {
      FarhaSnackbar.success(context, res.message);
      ref.invalidate(_usersProvider(_filter));
    } else {
      FarhaSnackbar.error(context, res.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(_usersProvider(_filter));

    return AdminShell(
      child: Column(children: [
        Container(
          color: const Color(0xFF1A0A0A),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('User Management',
                style: AppTheme.headlineMedium.copyWith(
                    color: Colors.white, fontFamily: 'PlusJakartaSans')),
            const SizedBox(height: 12),
            TabBar(
              controller: _tabs,
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.white38,
              indicatorColor: AppColors.primary,
              tabs: const [Tab(text: 'All'), Tab(text: 'Tailors'), Tab(text: 'Customers')],
            ),
          ]),
        ),
        Expanded(
          child: usersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error:   (e, _) => Center(child: Text(e.toString(),
                style: const TextStyle(color: Colors.white54))),
            data: (data) {
              final users = (data['users'] as List?)?.cast<Map<String, dynamic>>() ?? [];
              if (users.isEmpty) {
                return const Center(child: Text('No users found.',
                    style: TextStyle(color: Colors.white38)));
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: users.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _UserTile(
                  user: users[i],
                  onToggleSuspend: () => _toggleSuspend(users[i]),
                  onTailorAction: _tailorAction,
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _UserTile extends StatelessWidget {
  final Map<String, dynamic>       user;
  final VoidCallback               onToggleSuspend;
  final void Function(String, String) onTailorAction;

  const _UserTile({
    required this.user,
    required this.onToggleSuspend,
    required this.onTailorAction,
  });

  @override
  Widget build(BuildContext context) {
    final isActive     = user['is_active']     as bool?   ?? true;
    final userType     = user['user_type']     as String? ?? 'customer';
    final tailorStatus = user['tailor_status'] as String?;
    final tailorId     = user['id']            as String? ?? '';
    final isPending    = tailorStatus == 'pending';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E0C0C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPending
              ? Colors.orange.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withValues(alpha: 0.2),
            backgroundImage: (user['profile_photo'] as String?)?.isNotEmpty == true
                ? NetworkImage(user['profile_photo'] as String) : null,
            child: (user['profile_photo'] as String?)?.isNotEmpty != true
                ? Text((user['first_name'] as String? ?? 'U')[0],
                    style: const TextStyle(color: AppColors.primary))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('${user['first_name']} ${user['last_name']}',
                  style: AppTheme.bodyMedium.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w600)),
              const SizedBox(width: 6),
              _Badge(userType, userType == 'tailor'
                  ? const Color(0xFF7B5EA7) : const Color(0xFF4A90E2)),
              if (!isActive) ...[const SizedBox(width: 4), _Badge('suspended', AppColors.error)],
              if (isPending)  ...[const SizedBox(width: 4), _Badge('pending', Colors.orange)],
            ]),
            Text(user['email'] as String? ?? '',
                style: AppTheme.bodySmall.copyWith(color: Colors.white54)),
          ])),
          PopupMenuButton<String>(
            color: const Color(0xFF2A1010),
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white38),
            onSelected: (action) {
              if (action == 'toggle')  onToggleSuspend();
              if (action == 'approve') onTailorAction(tailorId, 'approve');
              if (action == 'reject')  onTailorAction(tailorId, 'reject');
              if (action == 'feature') onTailorAction(tailorId, 'feature');
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'toggle',
                  child: Text(isActive ? 'Suspend' : 'Unsuspend',
                      style: TextStyle(color: isActive ? AppColors.error : Colors.green))),
              if (userType == 'tailor' && isPending) ...[
                const PopupMenuItem(value: 'approve',
                    child: Text('Approve Tailor', style: TextStyle(color: Colors.green))),
                const PopupMenuItem(value: 'reject',
                    child: Text('Reject Tailor', style: TextStyle(color: AppColors.error))),
              ],
              if (userType == 'tailor' && !isPending)
                const PopupMenuItem(value: 'feature',
                    child: Text('Toggle Featured', style: TextStyle(color: Colors.amber))),
            ],
          ),
        ]),
        if (userType == 'tailor' && user['shop_name'] != null) ...[
          const SizedBox(height: 6),
          Text('🏪 ${user['shop_name']}  ·  ⭐ ${user['rating'] ?? 0}  ·  ${user['total_orders'] ?? 0} orders',
              style: AppTheme.labelSmall.copyWith(color: Colors.white38)),
        ],
      ]),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color  color;
  const _Badge(this.text, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(text, style: AppTheme.labelSmall.copyWith(color: color, fontSize: 10)),
  );
}
