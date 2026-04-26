// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  // ── Text styles ────────────────────────────────────────────────────────
  static const TextStyle _base = TextStyle(
    fontFamily: 'Inter',
    color: AppColors.onBackground,
    letterSpacing: 0,
  );

  static TextStyle displayLarge  = _base.copyWith(fontFamily: 'PlusJakartaSans', fontSize: 32, fontWeight: FontWeight.w700, height: 1.2);
  static TextStyle displayMedium = _base.copyWith(fontFamily: 'PlusJakartaSans', fontSize: 26, fontWeight: FontWeight.w600, height: 1.25);
  static TextStyle headlineLarge = _base.copyWith(fontFamily: 'PlusJakartaSans', fontSize: 22, fontWeight: FontWeight.w600, height: 1.3);
  static TextStyle headlineMedium= _base.copyWith(fontFamily: 'PlusJakartaSans', fontSize: 18, fontWeight: FontWeight.w600, height: 1.35);
  static TextStyle headlineSmall = _base.copyWith(fontFamily: 'PlusJakartaSans', fontSize: 16, fontWeight: FontWeight.w600, height: 1.4);
  static TextStyle titleLarge    = _base.copyWith(fontSize: 16, fontWeight: FontWeight.w600, height: 1.4);
  static TextStyle titleMedium   = _base.copyWith(fontSize: 14, fontWeight: FontWeight.w500, height: 1.45);
  static TextStyle titleSmall    = _base.copyWith(fontSize: 13, fontWeight: FontWeight.w500, height: 1.5);
  static TextStyle bodyLarge     = _base.copyWith(fontSize: 16, fontWeight: FontWeight.w400, height: 1.6);
  static TextStyle bodyMedium    = _base.copyWith(fontSize: 14, fontWeight: FontWeight.w400, height: 1.6);
  static TextStyle bodySmall     = _base.copyWith(fontSize: 12, fontWeight: FontWeight.w400, height: 1.5);
  static TextStyle labelLarge    = _base.copyWith(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1);
  static TextStyle labelMedium   = _base.copyWith(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5);
  static TextStyle labelSmall    = _base.copyWith(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5);

  // ── Light Theme ────────────────────────────────────────────────────────
  static ThemeData get light {
    final ColorScheme colorScheme = const ColorScheme(
      brightness: Brightness.light,
      primary:            AppColors.primary,
      onPrimary:          AppColors.onPrimary,
      primaryContainer:   AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary:          AppColors.secondary,
      onSecondary:        AppColors.onSecondary,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.onSecondaryContainer,
      tertiary:           AppColors.tertiary,
      onTertiary:         AppColors.onTertiary,
      tertiaryContainer:  AppColors.tertiaryContainer,
      onTertiaryContainer:AppColors.onTertiaryContainer,
      error:              AppColors.error,
      onError:            AppColors.onError,
      errorContainer:     AppColors.errorContainer,
      onErrorContainer:   AppColors.onErrorContainer,
      surface:            AppColors.surface,
      onSurface:          AppColors.onSurface,
      surfaceContainerHighest: AppColors.surfaceContainerHighest,
      onSurfaceVariant:   AppColors.onSurfaceVariant,
      outline:            AppColors.outline,
      outlineVariant:     AppColors.outlineVariant,
      inverseSurface:     AppColors.inverseSurface,
      onInverseSurface:   AppColors.inverseOnSurface,
      inversePrimary:     AppColors.inversePrimary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Inter',
      textTheme: TextTheme(
        displayLarge:  displayLarge,
        displayMedium: displayMedium,
        headlineLarge: headlineLarge,
        headlineMedium:headlineMedium,
        headlineSmall: headlineSmall,
        titleLarge:    titleLarge,
        titleMedium:   titleMedium,
        titleSmall:    titleSmall,
        bodyLarge:     bodyLarge,
        bodyMedium:    bodyMedium,
        bodySmall:     bodySmall,
        labelLarge:    labelLarge,
        labelMedium:   labelMedium,
        labelSmall:    labelSmall,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor:  AppColors.background,
        foregroundColor:  AppColors.onBackground,
        elevation:        0,
        scrolledUnderElevation: 0,
        centerTitle:      true,
        titleTextStyle:   titleLarge.copyWith(fontFamily: 'PlusJakartaSans'),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor:           Colors.transparent,
          statusBarIconBrightness:  Brightness.dark,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor:  AppColors.primary,
          foregroundColor:  AppColors.onPrimary,
          minimumSize:      const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
          textStyle: labelLarge.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor:  AppColors.primary,
          minimumSize:      const Size(double.infinity, 56),
          side:             const BorderSide(color: AppColors.outline),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
          textStyle: labelLarge.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: labelLarge.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled:      true,
        fillColor:   AppColors.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle:     bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
        hintStyle:      bodyMedium.copyWith(color: AppColors.outline),
        errorStyle:     bodySmall.copyWith(color: AppColors.error),
        prefixIconColor: AppColors.onSurfaceVariant,
        suffixIconColor: AppColors.onSurfaceVariant,
      ),
      cardTheme: CardThemeData(
        color:     AppColors.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.outlineVariant, width: 0.5),
        ),
        margin: const EdgeInsets.all(0),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceContainerLowest,
        selectedItemColor:   AppColors.primary,
        unselectedItemColor: AppColors.onSurfaceVariant,
        showSelectedLabels:   true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceContainerLowest,
        indicatorColor:  AppColors.primaryFixed,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary);
          }
          return const IconThemeData(color: AppColors.onSurfaceVariant);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return labelSmall.copyWith(color: AppColors.primary);
          }
          return labelSmall.copyWith(color: AppColors.onSurfaceVariant);
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior:        SnackBarBehavior.floating,
        backgroundColor: AppColors.inverseSurface,
        contentTextStyle:bodyMedium.copyWith(color: AppColors.inverseOnSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: const DividerThemeData(
        color:     AppColors.outlineVariant,
        thickness: 0.5,
        space:     0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor:  AppColors.surfaceContainerLow,
        selectedColor:    AppColors.primaryFixed,
        labelStyle:       labelMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        side: const BorderSide(color: AppColors.outlineVariant),
      ),
    );
  }
}
