// lib/presentation/screens/admin/admin_shell.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/farha_snackbar.dart';
import '../../../routes/app_router.dart';

class AdminShell extends ConsumerWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  static const _navItems = [
    (icon: Icons.dashboard_rounded,      label: 'Dashboard',  route: Routes.adminDashboard),
    (icon: Icons.people_alt_rounded,     label: 'Users',      route: Routes.adminUsers),
    (icon: Icons.receipt_long_rounded,   label: 'Orders',     route: Routes.adminOrders),
    (icon: Icons.payments_rounded,       label: 'Payments',   route: Routes.adminPayments),
    (icon: Icons.account_balance_wallet_rounded, label: 'Payouts', route: Routes.adminPayouts),
    (icon: Icons.inventory_2_rounded,    label: 'Products',   route: Routes.adminProducts),
    (icon: Icons.campaign_rounded,       label: 'Broadcast',  route: Routes.adminBroadcast),
  ];

  int _currentIndex(String location) {
    for (int i = 0; i < _navItems.length; i++) {
      if (location.startsWith(_navItems[i].route)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location  = GoRouterState.of(context).matchedLocation;
    final authState = ref.watch(adminAuthProvider);

    // Redirect to admin login if not authenticated
    if (!authState.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => context.go(Routes.adminLogin));
      return const Scaffold(
        backgroundColor: Color(0xFF0F0707),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final current = _currentIndex(location);
    final admin   = authState.admin;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0707),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A0A0A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Icon(Icons.admin_panel_settings_rounded,
                color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Text('Farha Admin',
              style: AppTheme.titleMedium.copyWith(
                  color: Colors.white, fontFamily: 'PlusJakartaSans')),
        ]),
        actions: [
          if (admin != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Center(child: Text(admin.name,
                  style: AppTheme.labelSmall.copyWith(color: Colors.white60))),
            ),
          if (admin != null && admin.isSuperAdmin)
            IconButton(
              icon: const Icon(Icons.person_add_rounded, color: Colors.white70, size: 20),
              tooltip: 'Add admin',
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: const Color(0xFF1A0A0A),
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                builder: (_) => _AddAdminSheet(
                  onSuccess: () => FarhaSnackbar.success(
                      context, 'Admin account created successfully.'),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white70, size: 20),
            tooltip: 'Sign out',
            onPressed: () async {
              await ref.read(adminAuthProvider.notifier).logout();
              if (context.mounted) context.go(Routes.adminLogin);
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Row(
        children: [
          // Side navigation rail
          NavigationRail(
            backgroundColor: const Color(0xFF1A0A0A),
            selectedIndex: current,
            onDestinationSelected: (i) => context.go(_navItems[i].route),
            labelType: NavigationRailLabelType.all,
            selectedIconTheme: const IconThemeData(color: AppColors.primary),
            selectedLabelTextStyle: AppTheme.labelSmall.copyWith(
                color: AppColors.primary, fontWeight: FontWeight.w600),
            unselectedIconTheme: const IconThemeData(color: Colors.white38),
            unselectedLabelTextStyle: AppTheme.labelSmall.copyWith(
                color: Colors.white38),
            destinations: _navItems.map((item) =>
              NavigationRailDestination(
                icon: Icon(item.icon),
                label: Text(item.label),
              ),
            ).toList(),
          ),
          const VerticalDivider(width: 1, color: Color(0xFF2A1010)),
          // Main content
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ── Add Admin bottom sheet ─────────────────────────────────────────────────────
class _AddAdminSheet extends ConsumerStatefulWidget {
  final VoidCallback onSuccess;
  const _AddAdminSheet({required this.onSuccess});

  @override
  ConsumerState<_AddAdminSheet> createState() => _AddAdminSheetState();
}

class _AddAdminSheetState extends ConsumerState<_AddAdminSheet> {
  final _formKey   = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  String  _role        = 'moderator';
  bool    _obscure     = true;
  bool    _loading     = false;
  String? _serverError;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _serverError = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final res = await ref.read(apiClientProvider).post(
      ApiConstants.adminManage,
      data: {
        'name':     _nameCtrl.text.trim(),
        'email':    _emailCtrl.text.trim(),
        'password': _passCtrl.text,
        'role':     _role,
      },
    );

    if (!mounted) return;

    if (res.success) {
      Navigator.pop(context);
      widget.onSuccess();
    } else {
      setState(() {
        _loading     = false;
        _serverError = res.message.isNotEmpty ? res.message : 'Something went wrong.';
      });
    }
  }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Colors.white54),
    prefixIcon: Icon(icon, color: Colors.white38, size: 20),
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.06),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error)),
    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
    errorStyle: const TextStyle(color: AppColors.error),
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text('Add New Admin',
                style: AppTheme.titleLarge.copyWith(
                    color: Colors.white, fontFamily: 'PlusJakartaSans')),
            const SizedBox(height: 4),
            Text('The new admin can log in immediately with these credentials.',
                style: AppTheme.bodySmall.copyWith(color: Colors.white38)),
            const SizedBox(height: 24),

            // Name
            TextFormField(
              controller: _nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: _dec('Full name', Icons.person_outline_rounded),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 14),

            // Email
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: _dec('Email address', Icons.email_outlined),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email is required';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Password
            TextFormField(
              controller: _passCtrl,
              obscureText: _obscure,
              style: const TextStyle(color: Colors.white),
              decoration: _dec('Password', Icons.lock_outline_rounded).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                      _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: Colors.white38, size: 20),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password is required';
                if (v.length < 8) return 'At least 8 characters';
                if (!v.contains(RegExp(r'[A-Z]'))) return 'Add an uppercase letter';
                if (!v.contains(RegExp(r'[a-z]'))) return 'Add a lowercase letter';
                if (!v.contains(RegExp(r'[0-9]'))) return 'Add a number';
                if (!v.contains(RegExp(r'[\W_]'))) return 'Add a special character';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Role
            DropdownButtonFormField<String>(
              initialValue: _role,
              dropdownColor: const Color(0xFF2A1010),
              style: const TextStyle(color: Colors.white),
              decoration: _dec('Role', Icons.shield_outlined),
              items: const [
                DropdownMenuItem(value: 'moderator',  child: Text('Moderator')),
                DropdownMenuItem(value: 'super_admin', child: Text('Super Admin')),
              ],
              onChanged: (v) => setState(() => _role = v ?? 'moderator'),
            ),
            const SizedBox(height: 24),

            if (_serverError != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                ),
                child: Text(_serverError!,
                    style: AppTheme.bodySmall.copyWith(color: AppColors.error)),
              ),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _loading ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white))
                    : const Text('Create Admin Account'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
