// lib/presentation/screens/auth/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../../routes/app_router.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _currentPage = 0;
  final _pageController = PageController();

  Future<void> _finish() async {
    await ref.read(localStorageProvider).setOnboarded();
    if (!mounted) return;
    context.go(Routes.chooseUserType);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final currentLocale = ref.watch(localeProvider);
    final selectedLanguage = currentLocale.languageCode;

    final pages = [
      (title: l.onboardingTitle1, subtitle: l.onboardingSubtitle1, icon: Icons.content_cut_rounded),
      (title: l.onboardingTitle2, subtitle: l.onboardingSubtitle2, icon: Icons.straighten_rounded),
      (title: l.onboardingTitle3, subtitle: l.onboardingSubtitle3, icon: Icons.track_changes_rounded),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Language switcher ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.primaryFixed,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.content_cut_rounded,
                            color: AppColors.primary, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Text('Farha', style: AppTheme.titleLarge.copyWith(
                          fontFamily: 'PlusJakartaSans', color: AppColors.primary)),
                    ],
                  ),
                  // Language toggle — changes the whole app locale instantly
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: AppColors.outlineVariant),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: ['en', 'fr'].map((lang) => GestureDetector(
                        onTap: () => ref.read(localeProvider.notifier).setLanguage(lang),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: selectedLanguage == lang
                                ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(lang.toUpperCase(),
                            style: AppTheme.labelMedium.copyWith(
                              color: selectedLanguage == lang
                                  ? AppColors.onPrimary : AppColors.onSurfaceVariant,
                            )),
                        ),
                      )).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // ── Page view ─────────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) {
                  final page = pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 180, height: 180,
                          decoration: BoxDecoration(
                            color: AppColors.primaryFixed,
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: Icon(page.icon, size: 80, color: AppColors.primary),
                        ),
                        const SizedBox(height: 48),
                        Text(page.title,
                          textAlign: TextAlign.center,
                          style: AppTheme.displayMedium.copyWith(
                              color: AppColors.onBackground)),
                        const SizedBox(height: 16),
                        Text(page.subtitle,
                          textAlign: TextAlign.center,
                          style: AppTheme.bodyLarge.copyWith(
                              color: AppColors.onSurfaceVariant, height: 1.7)),
                      ],
                    ),
                  );
                },
              ),
            ),

            // ── Dots + buttons ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  // Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(pages.length, (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width:  _currentPage == i ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == i
                            ? AppColors.primary : AppColors.outlineVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )),
                  ),
                  const SizedBox(height: 32),
                  // Sign Up
                  ElevatedButton.icon(
                    onPressed: () => context.push(Routes.chooseUserType),
                    icon: const Icon(Icons.person_add_outlined, size: 20),
                    label: Text(l.signUp),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Login
                  OutlinedButton.icon(
                    onPressed: () => context.push(Routes.login),
                    icon: const Icon(Icons.login_rounded, size: 20),
                    label: Text(l.login),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Guest
                  TextButton(
                    onPressed: _finish,
                    child: Text(l.continueAsGuest,
                      style: AppTheme.bodyMedium.copyWith(
                          color: AppColors.onSurfaceVariant)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
