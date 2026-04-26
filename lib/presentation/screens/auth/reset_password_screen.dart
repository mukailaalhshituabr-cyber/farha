// lib/presentation/screens/auth/reset_password_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/farha_button.dart';
import '../../widgets/common/farha_text_field.dart';
import '../../widgets/common/farha_snackbar.dart';
import '../../../routes/app_router.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String resetToken;
  final String email;
  const ResetPasswordScreen({super.key, required this.resetToken, required this.email});
  @override
  ConsumerState<ResetPasswordScreen> createState() => _State();
}

class _State extends ConsumerState<ResetPasswordScreen> {
  final _formKey       = GlobalKey<FormState>();
  final _passwordCtrl  = TextEditingController();
  final _confirmCtrl   = TextEditingController();
  bool  _obscurePwd    = true;
  bool  _obscureConf   = true;
  bool  _isLoading     = false;
  double _strength     = 0;

  @override
  void dispose() { _passwordCtrl.dispose(); _confirmCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final res = await ref.read(authRepositoryProvider).resetPassword(
      resetToken:           widget.resetToken,
      password:             _passwordCtrl.text,
      passwordConfirmation: _confirmCtrl.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res.success) {
      FarhaSnackbar.success(context, 'Password reset successfully! Please log in.');
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      // Clear all auth routes and go to login
      while (context.canPop()) {
        context.pop();
      }
      context.go(Routes.login);
    } else {
      FarhaSnackbar.error(context, res.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 24),
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primaryFixed,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.lock_open_rounded,
                    color: AppColors.primary, size: 32),
              ),
              const SizedBox(height: 24),
              Text('Set New Password', style: AppTheme.displayMedium),
              const SizedBox(height: 8),
              Text('Create a strong password for ${widget.email}',
                style: AppTheme.bodyMedium.copyWith(color: AppColors.onSurfaceVariant)),
              const SizedBox(height: 32),

              FarhaTextField(
                controller: _passwordCtrl, label: 'New Password', hint: '••••••••',
                prefixIcon: Icons.lock_outline_rounded, obscureText: _obscurePwd,
                textInputAction: TextInputAction.next,
                onChanged: (v) => setState(() => _strength = AppValidators.passwordStrength(v)),
                validator: (v) => AppValidators.required('Password')(v) ?? AppValidators.strongPassword()(v),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePwd ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: AppColors.onSurfaceVariant),
                  onPressed: () => setState(() => _obscurePwd = !_obscurePwd),
                ),
              ),
              PasswordStrengthIndicator(strength: _strength),
              const SizedBox(height: 16),

              FarhaTextField(
                controller: _confirmCtrl, label: 'Confirm New Password', hint: '••••••••',
                prefixIcon: Icons.verified_user_outlined, obscureText: _obscureConf,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                validator: AppValidators.matchPassword(() => _passwordCtrl.text),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConf ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: AppColors.onSurfaceVariant),
                  onPressed: () => setState(() => _obscureConf = !_obscureConf),
                ),
              ),
              const SizedBox(height: 12),

              // Password rules reminder
              _PasswordRule(text: 'At least 8 characters',          met: _passwordCtrl.text.length >= 8),
              _PasswordRule(text: 'One uppercase letter (A-Z)',      met: RegExp(r'[A-Z]').hasMatch(_passwordCtrl.text)),
              _PasswordRule(text: 'One lowercase letter (a-z)',      met: RegExp(r'[a-z]').hasMatch(_passwordCtrl.text)),
              _PasswordRule(text: 'One number (0-9)',                met: RegExp(r'[0-9]').hasMatch(_passwordCtrl.text)),
              _PasswordRule(text: 'One special character (!@#\$...)', met: RegExp(r'[\W_]').hasMatch(_passwordCtrl.text)),
              const SizedBox(height: 28),

              FarhaButton(
                label: 'Reset Password',
                isLoading: _isLoading,
                onPressed: _submit,
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _PasswordRule extends StatelessWidget {
  final String text;
  final bool   met;
  const _PasswordRule({required this.text, required this.met});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Icon(met ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 16,
            color: met ? AppColors.success : AppColors.outline),
        const SizedBox(width: 8),
        Text(text, style: AppTheme.bodySmall.copyWith(
          color: met ? AppColors.success : AppColors.onSurfaceVariant,
        )),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Email Verification Pending Screen
// lib/presentation/screens/auth/email_verification_pending_screen.dart
// ─────────────────────────────────────────────────────────────────────────────

class EmailVerificationPendingScreen extends ConsumerStatefulWidget {
  final String email;
  const EmailVerificationPendingScreen({super.key, required this.email});
  @override
  ConsumerState<EmailVerificationPendingScreen> createState() => _PendingState();
}

class _PendingState extends ConsumerState<EmailVerificationPendingScreen> {
  bool _isResending = false;
  int  _resendCooldown = 0;
  Timer? _timer;

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  void _startCooldown() {
    setState(() => _resendCooldown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendCooldown > 0) {
        setState(() => _resendCooldown--);
      } else {
        t.cancel();
      }
    });
  }

  Future<void> _resend() async {
    setState(() => _isResending = true);
    final res = await ref.read(authRepositoryProvider)
        .resendVerification(widget.email);
    if (!mounted) return;
    setState(() => _isResending = false);
    if (res.success) {
      FarhaSnackbar.success(context, 'Verification email resent!');
      _startCooldown();
    } else {
      FarhaSnackbar.error(context, res.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primaryFixed,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mark_email_unread_outlined,
                    color: AppColors.primary, size: 48),
              ),
              const SizedBox(height: 32),
              Text('Check Your Email',
                style: AppTheme.displayMedium, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: AppTheme.bodyLarge.copyWith(
                      color: AppColors.onSurfaceVariant, height: 1.7),
                  children: [
                    const TextSpan(text: 'We sent a verification link to\n'),
                    TextSpan(text: widget.email,
                      style: AppTheme.bodyLarge.copyWith(
                        color: AppColors.onBackground, fontWeight: FontWeight.w600)),
                    const TextSpan(text: '\n\nClick the link to verify your account and log in.'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: Row(children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppColors.onSurfaceVariant, size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Text(
                    'The link expires in 24 hours. Check your spam folder if you don\'t see it.',
                    style: AppTheme.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
                  )),
                ]),
              ),
              const SizedBox(height: 40),

              FarhaButton(
                label:     'Go to Login',
                onPressed: () => context.go(Routes.login),
              ),
              const SizedBox(height: 16),

              _isResending
                  ? const CircularProgressIndicator()
                  : OutlinedButton.icon(
                      onPressed: _resendCooldown == 0 ? _resend : null,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: Text(_resendCooldown > 0
                          ? 'Resend in ${_resendCooldown}s' : 'Resend Email'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
