// lib/presentation/screens/auth/otp_verification_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/farha_button.dart';
import '../../widgets/common/farha_snackbar.dart';
import '../../../routes/app_router.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String email;
  const OtpVerificationScreen({super.key, required this.email});
  @override
  ConsumerState<OtpVerificationScreen> createState() => _State();
}

class _State extends ConsumerState<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _isResending = false;
  String _otp = '';

  // Countdown timer
  late Timer _timer;
  int _secondsLeft = 15 * 60; // 15 minutes

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        t.cancel();
      }
    });
  }

  String get _timerText {
    final m = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _timer.cancel();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_otp.length != 6) {
      FarhaSnackbar.error(context, 'Please enter the 6-digit code.');
      return;
    }
    setState(() => _isLoading = true);

    final res = await ref
        .read(authRepositoryProvider)
        .verifyOtp(email: widget.email, otp: _otp);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res.success) {
      final resetToken = res.data?['reset_token'] as String?;
      context.push(Routes.resetPassword, extra: {
        'reset_token': resetToken ?? '',
        'email': widget.email,
      });
    } else {
      FarhaSnackbar.error(context, res.message);
    }
  }

  Future<void> _resend() async {
    setState(() {
      _isResending = true;
      _otpController.clear();
      _otp = '';
    });

    final res =
        await ref.read(authRepositoryProvider).forgotPassword(widget.email);

    if (!mounted) return;
    setState(() {
      _isResending = false;
      _secondsLeft = 15 * 60;
    });
    _timer.cancel();
    _startTimer();

    if (res.success) {
      FarhaSnackbar.success(
          context, 'A new code has been sent to ${widget.email}');
    } else {
      FarhaSnackbar.error(context, res.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final maskedEmail =
        widget.email.replaceRange(3, widget.email.indexOf('@'), '***');

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
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 24),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primaryFixed,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.mark_email_read_outlined,
                  color: AppColors.primary, size: 32),
            ),
            const SizedBox(height: 24),
            Text('Enter Reset Code', style: AppTheme.displayMedium),
            const SizedBox(height: 8),
            RichText(
                text: TextSpan(
              style: AppTheme.bodyMedium
                  .copyWith(color: AppColors.onSurfaceVariant),
              children: [
                const TextSpan(text: 'We sent a 6-digit code to '),
                TextSpan(
                    text: maskedEmail,
                    style: AppTheme.bodyMedium.copyWith(
                        color: AppColors.onBackground,
                        fontWeight: FontWeight.w600)),
              ],
            )),
            const SizedBox(height: 40),

            // ── OTP input ─────────────────────────────────────────────
            PinCodeTextField(
              appContext: context,
              length: 6,
              controller: _otpController,
              keyboardType: TextInputType.number,
              animationType: AnimationType.fade,
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(12),
                fieldHeight: 56,
                fieldWidth: 48,
                activeFillColor: AppColors.surfaceContainerLowest,
                inactiveFillColor: AppColors.surfaceContainerLow,
                selectedFillColor: AppColors.primaryFixed,
                activeColor: AppColors.primary,
                inactiveColor: AppColors.outlineVariant,
                selectedColor: AppColors.primary,
              ),
              enableActiveFill: true,
              onChanged: (v) => setState(() => _otp = v),
              onCompleted: (v) {
                setState(() => _otp = v);
                _verify();
              },
            ),

            // ── Timer ─────────────────────────────────────────────────
            Center(
              child: _secondsLeft > 0
                  ? RichText(
                      text: TextSpan(
                      style: AppTheme.bodyMedium
                          .copyWith(color: AppColors.onSurfaceVariant),
                      children: [
                        const TextSpan(text: 'Code expires in '),
                        TextSpan(
                            text: _timerText,
                            style: AppTheme.bodyMedium.copyWith(
                              color: _secondsLeft < 60
                                  ? AppColors.error
                                  : AppColors.primary,
                              fontWeight: FontWeight.w600,
                            )),
                      ],
                    ))
                  : Text('Code expired',
                      style:
                          AppTheme.bodyMedium.copyWith(color: AppColors.error)),
            ),
            const SizedBox(height: 32),

            // ── Verify button ─────────────────────────────────────────
            FarhaButton(
              label: 'Verify Code',
              isLoading: _isLoading,
              onPressed: _otp.length == 6 ? _verify : null,
            ),
            const SizedBox(height: 20),

            // ── Resend ────────────────────────────────────────────────
            Center(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text("Didn't receive it? ",
                    style: AppTheme.bodyMedium
                        .copyWith(color: AppColors.onSurfaceVariant)),
                _isResending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : TextButton(
                        onPressed: _secondsLeft == 0 ? _resend : null,
                        child: Text('Resend',
                            style: AppTheme.labelLarge.copyWith(
                              color: _secondsLeft == 0
                                  ? AppColors.primary
                                  : AppColors.outline,
                            )),
                      ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class AnimationType {
  static const fade = AnimationType._('fade');
  final String name;
  const AnimationType._(this.name);
}

class PinTheme {
  final PinCodeFieldShape shape;
  final BorderRadius borderRadius;
  final double fieldHeight;
  final double fieldWidth;
  final Color activeFillColor;
  final Color inactiveFillColor;
  final Color selectedFillColor;
  final Color activeColor;
  final Color inactiveColor;
  final Color selectedColor;

  const PinTheme({
    required this.shape,
    required this.borderRadius,
    required this.fieldHeight,
    required this.fieldWidth,
    required this.activeFillColor,
    required this.inactiveFillColor,
    required this.selectedFillColor,
    required this.activeColor,
    required this.inactiveColor,
    required this.selectedColor,
  });
}

class PinCodeFieldShape {
  static const box = PinCodeFieldShape._('box');
  final String name;
  const PinCodeFieldShape._(this.name);
}

class PinCodeTextField extends StatelessWidget {
  final BuildContext appContext;
  final int length;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final AnimationType animationType;
  final PinTheme pinTheme;
  final bool enableActiveFill;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onCompleted;

  const PinCodeTextField({
    super.key,
    required this.appContext,
    required this.length,
    required this.controller,
    required this.keyboardType,
    required this.animationType,
    required this.pinTheme,
    required this.enableActiveFill,
    required this.onChanged,
    required this.onCompleted,
  });

  @override
  Widget build(BuildContext context) {
    // This is a placeholder for the actual PinCodeTextField from the package.
    // In a real implementation, you would use the widget provided by the package.
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Enter OTP',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
