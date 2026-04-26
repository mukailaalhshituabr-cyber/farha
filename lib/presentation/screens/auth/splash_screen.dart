// lib/presentation/screens/auth/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../../routes/app_router.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double>    _fadeAnim;
  late final Animation<double>    _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fadeAnim   = CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeOut));
    _scaleAnim  = Tween(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack)),
    );
    _controller.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;

    final storage  = ref.read(localStorageProvider);
    final onboarded = await storage.hasOnboarded();
    final loggedIn  = await storage.isLoggedIn();

    if (!mounted) return;

    if (loggedIn) {
      // Auth provider will redirect to correct dashboard
      final authState = ref.read(authProvider);
      if (authState.user?.userType == 'tailor') {
        context.go(Routes.tailorDashboard);
      } else {
        context.go(Routes.customerDashboard);
      }
    } else if (!onboarded) {
      context.go(Routes.onboarding);
    } else {
      context.go(Routes.login);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo mark
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.onPrimary.withValues(alpha:0.15),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Center(
                    child: Icon(Icons.content_cut_rounded,
                        color: AppColors.onPrimary, size: 40),
                  ),
                ),
                const SizedBox(height: 20),
                Text('FARHA',
                  style: AppTheme.displayMedium.copyWith(
                    color: AppColors.onPrimary,
                    letterSpacing: 8,
                    fontFamily: 'PlusJakartaSans',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text('The Digital Atelier',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppColors.onPrimary.withValues(alpha:0.75),
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
