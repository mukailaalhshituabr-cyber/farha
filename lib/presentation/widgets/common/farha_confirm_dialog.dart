// lib/presentation/widgets/common/farha_confirm_dialog.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';

/// A consistent confirmation dialog used throughout the app.
///
/// Usage:
///   final confirmed = await FarhaConfirmDialog.show(context,
///     title: 'Delete profile?',
///     body:  'This cannot be undone.',
///     confirmLabel: 'Delete',
///     isDangerous: true,
///   );
///   if (confirmed) { ... }
class FarhaConfirmDialog extends StatelessWidget {
  final String title;
  final String body;
  final String confirmLabel;
  final String cancelLabel;
  final bool   isDangerous;

  const FarhaConfirmDialog({
    super.key,
    required this.title,
    required this.body,
    this.confirmLabel = 'Confirm',
    this.cancelLabel  = 'Cancel',
    this.isDangerous  = false,
  });

  /// Show the dialog. Returns `true` if the user pressed confirm.
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String body,
    String confirmLabel = 'Confirm',
    String cancelLabel  = 'Cancel',
    bool   isDangerous  = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => FarhaConfirmDialog(
        title:        title,
        body:         body,
        confirmLabel: confirmLabel,
        cancelLabel:  cancelLabel,
        isDangerous:  isDangerous,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
    contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
    actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
    title: Text(title,
        style: AppTheme.titleMedium.copyWith(fontFamily: 'PlusJakartaSans')),
    content: Text(body,
        style: AppTheme.bodyMedium
            .copyWith(color: AppColors.onSurfaceVariant)),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: Text(cancelLabel,
            style: AppTheme.labelLarge
                .copyWith(color: AppColors.onSurfaceVariant)),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, true),
        style: FilledButton.styleFrom(
          backgroundColor:
              isDangerous ? AppColors.error : AppColors.primary,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(confirmLabel,
            style: AppTheme.labelLarge
                .copyWith(color: Colors.white)),
      ),
    ],
  );
}
