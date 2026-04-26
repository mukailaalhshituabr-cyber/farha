// lib/core/constants/app_text_styles.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // ── Headline family (Plus Jakarta Sans) ───────────────────────────────
  static const TextStyle _headline = TextStyle(
    fontFamily: 'PlusJakartaSans',
    color:      AppColors.onBackground,
    height:     1.25,
  );

  static TextStyle displayLarge  = _headline.copyWith(fontSize: 32, fontWeight: FontWeight.w700);
  static TextStyle displayMedium = _headline.copyWith(fontSize: 26, fontWeight: FontWeight.w600);
  static TextStyle headlineLarge = _headline.copyWith(fontSize: 22, fontWeight: FontWeight.w600);
  static TextStyle headlineMedium= _headline.copyWith(fontSize: 18, fontWeight: FontWeight.w600);
  static TextStyle headlineSmall = _headline.copyWith(fontSize: 16, fontWeight: FontWeight.w600);

  // ── Body family (Inter) ───────────────────────────────────────────────
  static const TextStyle _body = TextStyle(
    fontFamily: 'Inter',
    color:      AppColors.onBackground,
    height:     1.6,
  );

  static TextStyle titleLarge  = _body.copyWith(fontSize: 16, fontWeight: FontWeight.w600);
  static TextStyle titleMedium = _body.copyWith(fontSize: 14, fontWeight: FontWeight.w500);
  static TextStyle titleSmall  = _body.copyWith(fontSize: 13, fontWeight: FontWeight.w500);
  static TextStyle bodyLarge   = _body.copyWith(fontSize: 16, fontWeight: FontWeight.w400);
  static TextStyle bodyMedium  = _body.copyWith(fontSize: 14, fontWeight: FontWeight.w400);
  static TextStyle bodySmall   = _body.copyWith(fontSize: 12, fontWeight: FontWeight.w400);
  static TextStyle labelLarge  = _body.copyWith(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1);
  static TextStyle labelMedium = _body.copyWith(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5);
  static TextStyle labelSmall  = _body.copyWith(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5);

  // ── Muted variants ────────────────────────────────────────────────────
  static TextStyle bodyMediumMuted  = bodyMedium.copyWith(color: AppColors.onSurfaceVariant);
  static TextStyle bodySmallMuted   = bodySmall.copyWith(color: AppColors.onSurfaceVariant);
  static TextStyle labelSmallMuted  = labelSmall.copyWith(color: AppColors.onSurfaceVariant);

  // ── Colored variants ──────────────────────────────────────────────────
  static TextStyle primaryLabel = labelLarge.copyWith(color: AppColors.primary);
  static TextStyle errorText    = bodySmall.copyWith(color: AppColors.error);
  static TextStyle successText  = bodySmall.copyWith(color: AppColors.success);
}
