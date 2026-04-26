// lib/data/services/permission_service.dart
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Which device capability we are requesting.
enum AppPermission { camera, gallery, location }

/// Centralised permission helper.
///
/// Calling [PermissionService.request] will:
///   1. Return immediately if already granted.
///   2. Show an in-app rationale dialog (customisable) before the OS dialog.
///   3. Redirect to system Settings when permanently denied.
class PermissionService {
  PermissionService._();

  // ── Public entry point ─────────────────────────────────────────────────────

  /// Request [permission].  Returns `true` when the permission is granted.
  static Future<bool> request(
    BuildContext context,
    AppPermission permission, {
    String? rationaleTitle,
    String? rationaleBody,
  }) async {
    final perm = _toSystemPermission(permission);
    final status = await perm.status;

    // Already granted / limited (iOS photos)
    if (status.isGranted || status.isLimited) return true;

    // Permanently denied — direct user to settings
    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        await _showSettingsDialog(context, permission);
      }
      return false;
    }

    // Show rationale before asking the OS
    if (!context.mounted) return false;
    final proceed = await _showRationaleDialog(
      context, permission,
      title: rationaleTitle,
      body:  rationaleBody,
    );
    if (!proceed) return false;

    // Request from OS
    final next = await perm.request();
    if (next.isGranted || next.isLimited) return true;

    if (next.isPermanentlyDenied && context.mounted) {
      await _showSettingsDialog(context, permission);
    }
    return false;
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  static Permission _toSystemPermission(AppPermission p) => switch (p) {
    AppPermission.camera   => Permission.camera,
    AppPermission.gallery  => Permission.photos,
    AppPermission.location => Permission.locationWhenInUse,
  };

  static Future<bool> _showRationaleDialog(
    BuildContext context,
    AppPermission permission, {
    String? title,
    String? body,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        title: Row(children: [
          Icon(_permissionIcon(permission),
              color: AppColors.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title ?? _defaultTitle(permission),
              style: AppTheme.titleMedium
                  .copyWith(fontFamily: 'PlusJakartaSans'),
            ),
          ),
        ]),
        content: Text(
          body ?? _defaultBody(permission),
          style: AppTheme.bodyMedium
              .copyWith(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Not Now',
                style: AppTheme.labelLarge
                    .copyWith(color: AppColors.onSurfaceVariant)),
          ),
          // For location we clarify it will be while-using only
          if (permission == AppPermission.location)
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Allow While Using App',
                  style: AppTheme.labelLarge
                      .copyWith(color: AppColors.primary)),
            )
          else
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Allow',
                  style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
    return result ?? false;
  }

  static Future<void> _showSettingsDialog(
    BuildContext context,
    AppPermission permission,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        title: Text('${_permissionName(permission)} Access Needed',
            style: AppTheme.titleMedium
                .copyWith(fontFamily: 'PlusJakartaSans')),
        content: Text(
          '${_permissionName(permission)} permission was denied. '
          'Please open Settings and enable it to continue.',
          style: AppTheme.bodyMedium
              .copyWith(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: AppTheme.labelLarge
                    .copyWith(color: AppColors.onSurfaceVariant)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Open Settings',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  static String _defaultTitle(AppPermission p) => switch (p) {
    AppPermission.camera   => 'Camera Access',
    AppPermission.gallery  => 'Photo Library Access',
    AppPermission.location => 'Location Access',
  };

  static String _defaultBody(AppPermission p) => switch (p) {
    AppPermission.camera =>
      'Farha needs camera access to take your profile or product photo.',
    AppPermission.gallery =>
      'Farha needs access to your photo library to choose images.',
    AppPermission.location =>
      'Farha uses your location to show tailors near you. '
      'Your location is only used while the app is open.',
  };

  static String _permissionName(AppPermission p) => switch (p) {
    AppPermission.camera   => 'Camera',
    AppPermission.gallery  => 'Photo Library',
    AppPermission.location => 'Location',
  };

  static IconData _permissionIcon(AppPermission p) => switch (p) {
    AppPermission.camera   => Icons.camera_alt_outlined,
    AppPermission.gallery  => Icons.photo_library_outlined,
    AppPermission.location => Icons.location_on_outlined,
  };
}
