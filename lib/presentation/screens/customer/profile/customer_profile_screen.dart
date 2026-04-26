// lib/presentation/screens/customer/profile/customer_profile_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/services/image_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/common/farha_bottom_nav.dart';
import '../../../../routes/app_router.dart';

class CustomerProfileScreen extends ConsumerStatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  ConsumerState<CustomerProfileScreen> createState() =>
      _CustomerProfileScreenState();
}

class _CustomerProfileScreenState
    extends ConsumerState<CustomerProfileScreen> {
  bool _uploadingPhoto = false;

  @override
  Widget build(BuildContext context) {
    final l    = AppL10n.of(context);
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppColors.onBackground, size: 20),
                onPressed: () => context.pop(),
              )
            : null,
        title: Text(l.profile,
            style: AppTheme.titleLarge.copyWith(
                fontFamily: 'PlusJakartaSans')),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined,
                color: AppColors.onBackground),
            tooltip: l.settings,
            onPressed: () => context.push(Routes.customerSettings),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Avatar + name banner ──────────────────────────────
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20)),
              child: Column(children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    _Avatar(
                      photoUrl: user?.profilePhoto,
                      initials: AppFormatters.initials(user?.fullName ?? 'U'),
                      size: 72,
                      uploading: _uploadingPhoto,
                    ),
                    GestureDetector(
                      onTap: () => _showPhotoSourceSheet(context, l),
                      child: Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppColors.onPrimary, width: 2)),
                        child: const Icon(Icons.camera_alt_rounded,
                            color: AppColors.onPrimary, size: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(user?.fullName ?? '',
                    style: AppTheme.headlineMedium.copyWith(
                        color: AppColors.onPrimary,
                        fontFamily: 'PlusJakartaSans')),
                const SizedBox(height: 4),
                Text(user?.email ?? '',
                    style: AppTheme.bodySmall.copyWith(
                        color: AppColors.onPrimary.withValues(alpha: 0.8))),
              ]),
            ),

            const SizedBox(height: 20),

            // ── Account info ─────────────────────────────────────
            _SectionHeader(title: l.accountInfo),
            _InfoTile(
              icon: Icons.person_outline_rounded,
              label: l.firstName,
              value: user?.firstName ?? '—',
            ),
            _InfoTile(
              icon: Icons.person_outline_rounded,
              label: l.lastName,
              value: user?.lastName ?? '—',
            ),
            _InfoTile(
              icon: Icons.email_outlined,
              label: l.email,
              value: user?.email ?? '—',
            ),
            _InfoTile(
              icon: Icons.phone_outlined,
              label: l.phone,
              value: user?.phone ?? '—',
            ),

            // ── Edit profile button ───────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: OutlinedButton.icon(
                onPressed: () => context.push(Routes.editCustomerProfile),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text(l.editProfile),
              ),
            ),

            const SizedBox(height: 24),
            const Divider(indent: 16, endIndent: 16),
            const SizedBox(height: 8),

            // ── Quick links ──────────────────────────────────────
            _SectionHeader(title: 'Quick Access'),
            _NavTile(
              icon: Icons.straighten_rounded,
              label: l.savedMeasurements,
              onTap: () => context.push(Routes.savedMeasurements),
            ),
            _NavTile(
              icon: Icons.receipt_long_outlined,
              label: l.orderHistory,
              onTap: () => context.push(Routes.orderHistory),
            ),
            _NavTile(
              icon: Icons.settings_outlined,
              label: l.settings,
              onTap: () => context.push(Routes.customerSettings),
            ),
            _NavTile(
              icon: Icons.help_outline_rounded,
              label: l.helpSupport,
              onTap: () => context.push(Routes.helpSupport),
            ),

            const SizedBox(height: 8),
            const Divider(indent: 16, endIndent: 16),
            const SizedBox(height: 8),

            // ── Logout ───────────────────────────────────────────
            _NavTile(
              icon: Icons.logout_rounded,
              label: l.logout,
              iconColor: AppColors.error,
              textColor: AppColors.error,
              onTap: () => _confirmLogout(context, ref, l),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: const CustomerBottomNav(currentIndex: 4),
    );
  }

  // ── Photo source bottom sheet ────────────────────────────────────────────
  void _showPhotoSourceSheet(BuildContext context, AppL10n l) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Text(l.changePhoto,
                style: AppTheme.titleMedium.copyWith(
                    fontFamily: 'PlusJakartaSans')),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined,
                  color: AppColors.primary),
              title: Text(l.takePhoto),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.camera, l);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.primary),
              title: Text(l.chooseFromGallery),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.gallery, l);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel_outlined,
                  color: AppColors.onSurfaceVariant),
              title: Text(l.cancel),
              onTap: () => Navigator.pop(context),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Permission check + photo pick ────────────────────────────────────────
  Future<void> _pickPhoto(ImageSource source, AppL10n l) async {
    final permission = source == ImageSource.camera
        ? Permission.camera
        : Permission.photos;

    var status = await permission.status;

    if (status.isDenied) {
      status = await permission.request();
    }

    if (status.isPermanentlyDenied) {
      if (!mounted) return;
      _showPermissionDialog(
        context,
        l,
        body: source == ImageSource.camera
            ? l.permissionCameraBody
            : l.permissionGalleryBody,
      );
      return;
    }

    if (!status.isGranted) return;

    // Pick the image
    final imageService =
        ImageService(ref.read(apiClientProvider));
    final File? file = source == ImageSource.camera
        ? await imageService.pickFromCamera()
        : await imageService.pickFromGallery();

    if (file == null) return;

    setState(() => _uploadingPhoto = true);
    String? serverError;
    final photoUrl = await imageService.uploadProfilePhoto(
      file,
      onError: (msg) => serverError = msg,
    );
    setState(() => _uploadingPhoto = false);

    if (!mounted) return;
    if (photoUrl != null) {
      // Evict old cached image so the new one loads immediately
      final oldPhoto = ref.read(authProvider).user?.profilePhoto;
      final updatedUser =
          ref.read(authProvider).user?.copyWith(profilePhoto: photoUrl);
      if (updatedUser != null) {
        ref.read(authProvider.notifier).updateUser(updatedUser);
      }
      if (oldPhoto != null) {
        CachedNetworkImage.evictFromCache(oldPhoto); // fire-and-forget, no await
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.photoUpdated)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(serverError ?? l.photoFailed),
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  void _showPermissionDialog(BuildContext context, AppL10n l,
      {required String body}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l.permissionRequired),
        content: Text(body),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l.cancel)),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text(l.openSettings),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref, AppL10n l) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l.logoutConfirmTitle),
        content: Text(l.logoutConfirmBody),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l.cancel)),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authProvider.notifier).logout();
              if (!context.mounted) return;
              context.go(Routes.onboarding);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100))),
            child: Text(l.logout),
          ),
        ],
      ),
    );
  }
}

// ── Shared sub-widgets ────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String? photoUrl;
  final String  initials;
  final double  size;
  final bool    uploading;

  const _Avatar({
    required this.photoUrl,
    required this.initials,
    required this.size,
    this.uploading = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = size / 2;
    if (uploading) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.onPrimary.withValues(alpha: 0.2),
        child: const SizedBox(
          width: 28, height: 28,
          child: CircularProgressIndicator(
              strokeWidth: 2.5, color: AppColors.onPrimary),
        ),
      );
    }
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage:
            CachedNetworkImageProvider(photoUrl!),
        backgroundColor: AppColors.onPrimary.withValues(alpha: 0.2),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.onPrimary.withValues(alpha: 0.2),
      child: Text(initials,
          style: AppTheme.headlineMedium.copyWith(
              color: AppColors.onPrimary, fontFamily: 'PlusJakartaSans')),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
    child: Text(title,
        style: AppTheme.labelMedium.copyWith(
            color: AppColors.onSurfaceVariant,
            letterSpacing: 0.8)),
  );
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String   label, value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: AppColors.outlineVariant, width: 0.5)),
      child: Row(children: [
        Icon(icon, size: 18, color: AppColors.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(label,
                style: AppTheme.labelSmall.copyWith(
                    color: AppColors.onSurfaceVariant)),
            Text(value, style: AppTheme.bodyMedium),
          ]),
        ),
      ]),
    ),
  );
}

class _NavTile extends StatelessWidget {
  final IconData    icon;
  final String      label;
  final VoidCallback onTap;
  final Color?      iconColor;
  final Color?      textColor;

  const _NavTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon,
        color: iconColor ?? AppColors.onSurfaceVariant, size: 22),
    title: Text(label,
        style: AppTheme.bodyMedium.copyWith(
            color: textColor ?? AppColors.onSurface)),
    trailing: iconColor == null
        ? const Icon(Icons.chevron_right_rounded,
            color: AppColors.outline, size: 20)
        : null,
    onTap: onTap,
    contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
    minVerticalPadding: 0,
  );
}
