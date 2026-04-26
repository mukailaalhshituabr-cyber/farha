// lib/presentation/widgets/common/farha_snackbar.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';

class FarhaSnackbar {
  static void _show(
      BuildContext context,
      String message, {
        Color?    color,
        IconData? icon,
        Duration  duration = const Duration(seconds: 4),
      }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Row(children: [
          Icon(icon ?? Icons.info_outline_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTheme.bodyMedium.copyWith(color: Colors.white),
            ),
          ),
        ]),
        backgroundColor: color ?? AppColors.inverseSurface,
        behavior:        SnackBarBehavior.floating,
        duration:        duration,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
  }

  static void error(BuildContext ctx, String msg, {Duration duration = const Duration(seconds: 4)}) =>
      _show(ctx, msg, color: AppColors.error,   icon: Icons.error_outline_rounded, duration: duration);

  static void success(BuildContext ctx, String msg) =>
      _show(ctx, msg, color: AppColors.success, icon: Icons.check_circle_outline_rounded);

  static void info(BuildContext ctx, String msg) =>
      _show(ctx, msg, color: AppColors.inverseSurface, icon: Icons.info_outline_rounded);

  static void warning(BuildContext ctx, String msg) =>
      _show(ctx, msg, color: const Color(0xFFB45309), icon: Icons.warning_amber_rounded);
}

// ── Password strength indicator ───────────────────────────────────────────
class PasswordStrengthIndicator extends StatelessWidget {
  final double strength;
  const PasswordStrengthIndicator({super.key, required this.strength});

  String get _label {
    if (strength == 0)  return '';
    if (strength < 0.4) return 'Weak — add uppercase, numbers and symbols';
    if (strength < 0.7) return 'Medium — add more variety';
    if (strength < 0.9) return 'Strong';
    return 'Very strong';
  }

  Color get _color {
    if (strength < 0.4) return AppColors.error;
    if (strength < 0.7) return const Color(0xFFB45309);
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    if (strength == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value:           strength,
            backgroundColor: AppColors.outlineVariant,
            valueColor:      AlwaysStoppedAnimation<Color>(_color),
            minHeight:       4,
          ),
        ),
        const SizedBox(height: 4),
        Text(_label, style: AppTheme.labelSmall.copyWith(color: _color)),
      ]),
    );
  }
}
