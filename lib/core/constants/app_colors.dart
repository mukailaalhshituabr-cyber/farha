// lib/core/constants/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Primary (deep bordeaux) ─────────────────────────────────────────────
  static const Color primary           = Color(0xFF74262B);
  static const Color primaryContainer  = Color(0xFF923D41);
  static const Color onPrimary         = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer= Color(0xFFFFBFBF);
  static const Color primaryFixed      = Color(0xFFFFDAD9);
  static const Color primaryFixedDim   = Color(0xFFFFB3B3);
  static const Color inversePrimary    = Color(0xFFFFB3B3);

  // ── Secondary (warm amber/gold) ─────────────────────────────────────────
  static const Color secondary            = Color(0xFF7C5813);
  static const Color secondaryContainer   = Color(0xFFFECC7D);
  static const Color onSecondary          = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF795510);

  // ── Tertiary (deeper burgundy) ──────────────────────────────────────────
  static const Color tertiary            = Color(0xFF692F34);
  static const Color tertiaryContainer   = Color(0xFF85464A);
  static const Color onTertiary          = Color(0xFFFFFFFF);
  static const Color onTertiaryContainer = Color(0xFFFFC0C2);

  // ── Surface / Background ────────────────────────────────────────────────
  static const Color background              = Color(0xFFFFF8F6);
  static const Color surface                 = Color(0xFFFFF8F6);
  static const Color surfaceBright           = Color(0xFFFFF8F6);
  static const Color surfaceDim              = Color(0xFFF8D2C4);
  static const Color surfaceContainerLowest  = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow     = Color(0xFFFFF1EC);
  static const Color surfaceContainer        = Color(0xFFFFE9E2);
  static const Color surfaceContainerHigh    = Color(0xFFFFE2D8);
  static const Color surfaceContainerHighest = Color(0xFFFFDBCE);
  static const Color surfaceVariant          = Color(0xFFFFDBCE);
  static const Color inverseSurface          = Color(0xFF422B22);
  static const Color inverseOnSurface        = Color(0xFFFFEDE7);

  // ── On-Surface ──────────────────────────────────────────────────────────
  static const Color onBackground      = Color(0xFF2A170F);
  static const Color onSurface         = Color(0xFF2A170F);
  static const Color onSurfaceVariant  = Color(0xFF554242);
  static const Color outline           = Color(0xFF887272);
  static const Color outlineVariant    = Color(0xFFDAC0C0);

  // ── Error ───────────────────────────────────────────────────────────────
  static const Color error            = Color(0xFFBA1A1A);
  static const Color errorContainer   = Color(0xFFFFDAD6);
  static const Color onError          = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF93000A);

  // ── Semantic helpers ────────────────────────────────────────────────────
  static const Color success     = Color(0xFF1E6F3E);
  static const Color successLight= Color(0xFFE8F5ED);
  static const Color warning     = Color(0xFFB45309);
  static const Color warningLight= Color(0xFFFEF3C7);
  static const Color info        = Color(0xFF1D4ED8);
  static const Color infoLight   = Color(0xFFEFF6FF);

  // ── Status colors for order stages ──────────────────────────────────────
  static const Color statusPending   = Color(0xFFB45309);   // amber
  static const Color statusCutting   = Color(0xFF1D4ED8);   // blue
  static const Color statusSewing    = Color(0xFF7C3AED);   // purple
  static const Color statusReady     = Color(0xFF059669);   // green
  static const Color statusDelivered = Color(0xFF1E6F3E);   // dark green
  static const Color statusCancelled = Color(0xFFBA1A1A);   // red

  // ── Shimmer (loading skeletons) ─────────────────────────────────────────
  static const Color shimmerBase     = Color(0xFFFFE9E2);
  static const Color shimmerHighlight= Color(0xFFFFF8F6);
}
