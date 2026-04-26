// lib/presentation/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/farha_button.dart';
import '../../widgets/common/farha_snackbar.dart';
import '../../widgets/common/farha_text_field.dart';
import '../../../routes/app_router.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _isLoading = false;
  bool _googleLoading = false;
  bool _submitted = false;
  bool _googleInitialized = false;

  int _failedAttempts = 0;
  static const int _maxAttempts = 3;
  String? _inlineError;

  @override
  void initState() {
    super.initState();
    _initGoogleSignIn();
  }

  Future<void> _initGoogleSignIn() async {
    try {
      await GoogleSignIn.instance.initialize();
      if (mounted) setState(() => _googleInitialized = true);
    } catch (_) {
      // Initialize can fail on platforms without Google Play Services.
      // The button will remain disabled rather than crashing.
    }
  }

  @override
  void dispose() {
    _identifierCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  String? _validateIdentifier(String? v) {
    final l = AppL10n.of(context);
    if (v == null || v.trim().isEmpty) return l.emailPhoneRequired;
    final val = v.trim();
    // Supports multi-level TLDs: user@ashesi.edu.gh, user@company.co.uk, etc.
    final emailRegex = RegExp(r'^[\w.+\-]+@[a-zA-Z\d\-]+(\.[a-zA-Z\d\-]+)*\.[a-zA-Z]{2,}$');
    if (val.contains('@')) {
      if (!emailRegex.hasMatch(val)) return l.invalidEmail;
      return null;
    }
    final c = val.replaceAll(RegExp(r'[\s\-\(\)\.]'), '');
    // International: +CC..., CC..., 00CC...
    if (RegExp(r'^\+?[1-9]\d{6,14}$').hasMatch(c)) return null;
    if (RegExp(r'^00[1-9]\d{5,13}$').hasMatch(c)) return null;
    // Local format with leading 0 (e.g. 0543249743 for Ghana)
    if (RegExp(r'^0\d{7,11}$').hasMatch(c)) return null;
    return l.invalidPhone;
  }

  String? _validatePassword(String? v) {
    final l = AppL10n.of(context);
    if (v == null || v.isEmpty) return l.passwordRequired;
    if (v.length < 8) return l.passwordTooShort;
    if (!RegExp(r'[A-Z]').hasMatch(v)) return l.passwordNeedsUppercase;
    if (!RegExp(r'[a-z]').hasMatch(v)) return l.passwordNeedsLowercase;
    if (!RegExp(r'[0-9]').hasMatch(v)) return l.passwordNeedsNumber;
    if (!RegExp(r'[\W_]').hasMatch(v)) return l.passwordNeedsSpecial;
    return null;
  }

  Future<void> _login() async {
    final l = AppL10n.of(context);
    setState(() {
      _inlineError = null;
      _submitted = true;
    });
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final result = await ref.read(authProvider.notifier).login(
          identifier: _identifierCtrl.text.trim(),
          password: _passwordCtrl.text,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success && result.user != null) {
      _failedAttempts = 0;
      context.go(result.user!.userType == 'tailor'
          ? Routes.tailorDashboard
          : Routes.customerDashboard);
      return;
    }

    if (result.emailNotVerified) {
      setState(() => _inlineError = l.emailNotVerified);
      return;
    }

    if (result.isNetworkError) {
      setState(() => _inlineError = l.connectionError);
      return;
    }

    _failedAttempts++;
    final remaining = _maxAttempts - _failedAttempts;

    if (_failedAttempts >= _maxAttempts) {
      setState(() => _inlineError = l.attemptsExceeded);
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      _failedAttempts = 0;
      context.go(Routes.onboarding);
    } else {
      setState(() {
        _inlineError = remaining == 1
            ? l.wrongCredentials1
            : l.wrongCredentialsN(remaining);
      });
    }
  }

  // ── Google Sign-In ──────────────────────────────────────────────────────
  Future<void> _handleGoogleSignIn() async {
    final l = AppL10n.of(context);
    setState(() {
      _googleLoading = true;
      _inlineError = null;
    });

    try {
      // 1. Open Google account picker (throws GoogleSignInException on cancel)
      final account = await GoogleSignIn.instance.authenticate();

      // 2. Get ID token — synchronous getter in v7
      final idToken = account.authentication.idToken;

      if (idToken == null) {
        setState(() {
          _googleLoading = false;
          _inlineError = l.somethingWrong;
        });
        return;
      }

      // 3. Send token to our backend
      final result = await ref
          .read(authProvider.notifier)
          .signInWithGoogle(idToken: idToken);

      if (!mounted) return;
      setState(() => _googleLoading = false);

      if (result.success && result.user != null) {
        // Existing user → go to dashboard
        context.go(result.user!.userType == 'tailor'
            ? Routes.tailorDashboard
            : Routes.customerDashboard);
        return;
      }

      if (result.needsRegistration) {
        // New Google account — ask them to pick customer or tailor
        _showGoogleUserTypeSheet(account.email, idToken);
        return;
      }

      setState(() => _inlineError =
          result.message.isNotEmpty ? result.message : l.somethingWrong);
    } on GoogleSignInException catch (e) {
      if (!mounted) return;
      // canceled / interrupted = user closed the picker; no error shown
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        setState(() => _googleLoading = false);
        return;
      }
      setState(() {
        _googleLoading = false;
        _inlineError = 'Google Sign-In failed. Please use email/phone to log in, or check that Google Play Services is available.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _googleLoading = false;
        _inlineError = 'Google Sign-In is not available on this device. Please use your email and password.';
      });
    }
  }

  void _showGoogleUserTypeSheet(String email, String idToken) {
    final l = AppL10n.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 20),
          Text(l.iAm,
              style:
                  AppTheme.titleLarge.copyWith(fontFamily: 'PlusJakartaSans')),
          const SizedBox(height: 6),
          Text(l.chooseAccountType,
              style: AppTheme.bodyMedium
                  .copyWith(color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(
              child: _TypeCard(
                icon: Icons.shopping_bag_outlined,
                title: l.customer,
                subtitle: l.customerSubtitle,
                onTap: () {
                  Navigator.pop(ctx);
                  _completeGoogleRegistration(idToken, 'customer');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TypeCard(
                icon: Icons.content_cut_rounded,
                title: l.tailor,
                subtitle: l.tailorSubtitle,
                onTap: () {
                  Navigator.pop(ctx);
                  _completeGoogleRegistration(idToken, 'tailor');
                },
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Future<void> _completeGoogleRegistration(
      String idToken, String userType) async {
    final l = AppL10n.of(context);
    setState(() => _googleLoading = true);

    final result = await ref
        .read(authProvider.notifier)
        .signInWithGoogle(idToken: idToken, userType: userType);

    if (!mounted) return;
    setState(() => _googleLoading = false);

    if (result.success && result.user != null) {
      context.go(result.user!.userType == 'tailor'
          ? Routes.tailorDashboard
          : Routes.customerDashboard);
    } else {
      FarhaSnackbar.error(context,
          result.message.isNotEmpty ? result.message : l.somethingWrong);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            autovalidateMode: _submitted
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),

                // ── Logo ────────────────────────────────────────────
                Center(
                  child: Column(children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.primaryFixed,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(Icons.content_cut_rounded,
                          color: AppColors.primary, size: 36),
                    ),
                    const SizedBox(height: 14),
                    Text('FARHA',
                        style: AppTheme.headlineLarge.copyWith(
                            letterSpacing: 6, color: AppColors.primary)),
                    const SizedBox(height: 4),
                    Text(l.tagline,
                        style: AppTheme.bodySmall.copyWith(
                            color: AppColors.onSurfaceVariant,
                            letterSpacing: 1.5)),
                  ]),
                ),

                const SizedBox(height: 44),

                Text(l.welcomeBack,
                    style: AppTheme.displayMedium
                        .copyWith(color: AppColors.onBackground)),
                const SizedBox(height: 6),
                Text(l.signInToContinue,
                    style: AppTheme.bodyMedium
                        .copyWith(color: AppColors.onSurfaceVariant)),

                const SizedBox(height: 36),

                // ── Email / Phone ────────────────────────────────────
                FarhaTextField(
                  controller: _identifierCtrl,
                  label: l.emailOrPhone,
                  hint: l.emailOrPhoneHint,
                  prefixIcon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: _validateIdentifier,
                  onChanged: (_) => setState(() => _inlineError = null),
                ),

                const SizedBox(height: 16),

                // ── Password ─────────────────────────────────────────
                FarhaTextField(
                  controller: _passwordCtrl,
                  label: l.password,
                  hint: '••••••••',
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: _obscurePass,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _login(),
                  validator: _validatePassword,
                  onChanged: (_) => setState(() => _inlineError = null),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePass
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.onSurfaceVariant,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePass = !_obscurePass),
                  ),
                ),

                // ── Inline error box ─────────────────────────────────
                if (_inlineError != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 1),
                          child: Icon(Icons.error_outline_rounded,
                              color: AppColors.error, size: 18),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_inlineError!,
                              style: AppTheme.bodySmall.copyWith(
                                color: AppColors.onErrorContainer,
                                fontWeight: FontWeight.w500,
                              )),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── Attempt dots ─────────────────────────────────────
                if (_failedAttempts > 0 && _failedAttempts < _maxAttempts) ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_maxAttempts, (i) {
                      return Container(
                        width: 28,
                        height: 5,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: i < _failedAttempts
                              ? AppColors.error
                              : AppColors.outlineVariant,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                ],

                // ── Forgot password ──────────────────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push(Routes.forgotPassword),
                    child: Text(l.forgotPassword,
                        style: AppTheme.labelMedium
                            .copyWith(color: AppColors.primary)),
                  ),
                ),

                // ── Continue button ──────────────────────────────────
                FarhaButton(
                  label: l.continueLabel,
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _login,
                  icon: Icons.arrow_forward_rounded,
                ),

                const SizedBox(height: 28),

                Row(children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(l.orContinueWith,
                        style: AppTheme.bodySmall
                            .copyWith(color: AppColors.onSurfaceVariant)),
                  ),
                  const Expanded(child: Divider()),
                ]),
                const SizedBox(height: 16),

                OutlinedButton(
                  onPressed:
                      (_isLoading || _googleLoading || !_googleInitialized)
                          ? null
                          : _handleGoogleSignIn,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100)),
                    side: const BorderSide(color: AppColors.outlineVariant),
                    foregroundColor: AppColors.onBackground,
                  ),
                  child: _googleLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: AppColors.primary))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Google "G" logo colours
                            _GoogleIcon(),
                            const SizedBox(width: 10),
                            Text(l.continueWithGoogle,
                                style: AppTheme.labelLarge
                                    .copyWith(color: AppColors.onBackground)),
                          ],
                        ),
                ),

                const SizedBox(height: 40),

                Center(
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('${l.dontHaveAccount} ',
                        style: AppTheme.bodyMedium
                            .copyWith(color: AppColors.onSurfaceVariant)),
                    TextButton(
                      onPressed: () => context.push(Routes.chooseUserType),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(l.signUp,
                          style: AppTheme.labelLarge.copyWith(
                            color: AppColors.primary,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.primary,
                          )),
                    ),
                  ]),
                ),
                const SizedBox(height: 20),

                Center(
                  child: TextButton.icon(
                    onPressed: () => context.go(Routes.adminLogin),
                    icon: const Icon(Icons.lock_outline_rounded,
                        size: 14, color: AppColors.onSurfaceVariant),
                    label: Text('Admin Panel',
                        style: AppTheme.bodySmall
                            .copyWith(color: AppColors.onSurfaceVariant)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Google coloured "G" icon ──────────────────────────────────────────────────

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(painter: _GooglePainter()),
    );
  }
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    // Draw four coloured arcs like the Google G
    const sweeps = [
      [0.0, 1.571, Color(0xFF4285F4)], // blue  — right
      [1.571, 1.571, Color(0xFF34A853)], // green — bottom
      [3.142, 1.571, Color(0xFFFBBC05)], // yellow — left
      [4.712, 1.571, Color(0xFFEA4335)], // red   — top
    ];

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.28
      ..strokeCap = StrokeCap.butt;

    for (final s in sweeps) {
      paint.color = s[2] as Color;
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r * 0.72),
        s[0] as double,
        s[1] as double,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_GooglePainter _) => false;
}

// ── User-type card (shown in the Google new-account sheet) ────────────────────

class _TypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _TypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.outlineVariant, width: 0.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.primary, size: 32),
              const SizedBox(height: 10),
              Text(title,
                  style:
                      AppTheme.titleSmall.copyWith(fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: AppTheme.bodySmall
                      .copyWith(color: AppColors.onSurfaceVariant),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
}
