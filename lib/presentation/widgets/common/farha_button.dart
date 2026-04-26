// lib/presentation/widgets/common/farha_button.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';

class FarhaButton extends StatelessWidget {
  final String   label;
  final VoidCallback? onPressed;
  final bool     isLoading;
  final IconData? icon;
  final bool     isOutlined;

  const FarhaButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading  = false,
    this.icon,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox(width: 22, height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
        : Row(mainAxisSize: MainAxisSize.min, children: [
            Text(label, style: AppTheme.labelLarge.copyWith(
              fontSize: 16, fontWeight: FontWeight.w600,
              color: isOutlined ? AppColors.primary : AppColors.onPrimary,
            )),
            if (icon != null) ...[
              const SizedBox(width: 8),
              Icon(icon, size: 20,
                color: isOutlined ? AppColors.primary : AppColors.onPrimary),
            ],
          ]);

    if (isOutlined) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        child: child,
      );
    }

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: child,
    );
  }
}
