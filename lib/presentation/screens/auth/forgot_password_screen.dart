// lib/presentation/screens/auth/forgot_password_screen.dart
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

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  ConsumerState<ForgotPasswordScreen> createState() => _State();
}

class _State extends ConsumerState<ForgotPasswordScreen> {
  final _formKey  = GlobalKey<FormState>();
  final _emailCtrl= TextEditingController();
  bool  _isLoading= false;

  @override
  void dispose() { _emailCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final res = await ref.read(authRepositoryProvider)
        .forgotPassword(_emailCtrl.text.trim());

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res.success) {
      context.push(Routes.otpVerification,
          extra: {'email': _emailCtrl.text.trim()});
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
                child: const Icon(Icons.lock_reset_rounded,
                    color: AppColors.primary, size: 32),
              ),
              const SizedBox(height: 24),
              Text('Forgot Password?', style: AppTheme.displayMedium),
              const SizedBox(height: 8),
              Text(
                'Enter your registered email and we\'ll send you a 6-digit reset code.',
                style: AppTheme.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 32),
              FarhaTextField(
                controller:   _emailCtrl,
                label:        'Email Address',
                hint:         'you@example.com',
                prefixIcon:   Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                validator: (v) =>
                  AppValidators.required('Email')(v) ??
                  AppValidators.email()(v),
              ),
              const SizedBox(height: 24),
              FarhaButton(
                label:     'Send Reset Code',
                isLoading: _isLoading,
                onPressed: _submit,
                icon:      Icons.send_rounded,
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
