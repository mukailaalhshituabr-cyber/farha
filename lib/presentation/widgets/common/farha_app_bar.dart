// lib/presentation/widgets/common/farha_app_bar.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';

class FarhaAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String?       title;
  final Widget?       titleWidget;
  final List<Widget>? actions;
  final Widget?       leading;
  final bool          showBack;
  final Color?        backgroundColor;
  final VoidCallback? onBack;

  const FarhaAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.showBack       = true,
    this.backgroundColor,
    this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor ?? AppColors.background,
      elevation:       0,
      scrolledUnderElevation: 0,
      centerTitle:     true,
      leading: leading ?? (showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back_rounded,
                  color: AppColors.onBackground),
              onPressed: onBack ?? () => Navigator.of(context).pop(),
            )
          : null),
      automaticallyImplyLeading: showBack,
      title: titleWidget ??
          (title != null
              ? Text(title!,
                  style: AppTheme.titleLarge.copyWith(
                    fontFamily: 'PlusJakartaSans',
                    color: AppColors.onBackground,
                  ))
              : null),
      actions: actions,
    );
  }
}
