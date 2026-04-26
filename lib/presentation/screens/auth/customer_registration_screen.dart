// lib/presentation/screens/auth/customer_registration_screen.dart
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

class CustomerRegistrationScreen extends ConsumerStatefulWidget {
  const CustomerRegistrationScreen({super.key});

  @override
  ConsumerState<CustomerRegistrationScreen> createState() => _State();
}

class _State extends ConsumerState<CustomerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  String _gender = '';
  String _language = 'en';
  bool _obscurePwd = true;
  bool _obscureConfirm = true;
  bool _termsAccepted = false;
  bool _isLoading = false;
  double _passwordStrength = 0;

  @override
  void dispose() {
    for (final c in [
      _firstNameCtrl,
      _lastNameCtrl,
      _emailCtrl,
      _phoneCtrl,
      _passwordCtrl,
      _confirmCtrl
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_gender.isEmpty) {
      FarhaSnackbar.error(context, 'Please select your gender.');
      return;
    }
    if (!_termsAccepted) {
      FarhaSnackbar.error(
          context, 'Please accept the Terms of Service and Privacy Policy.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final repo = ref.read(authRepositoryProvider);
    final res = await repo.registerCustomer(
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      gender: _gender,
      password: _passwordCtrl.text,
      passwordConfirmation: _confirmCtrl.text,
      language: _language,
      termsAccepted: true,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res.success) {
      context.push(Routes.emailVerificationPending,
          extra: {'email': _emailCtrl.text.trim()});
    } else if (res.isValidationErr) {
      final errors = res.errors as Map?;
      FarhaSnackbar.error(context, errors?.values.first ?? res.message);
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
        title: Column(children: [
          Text('Step 02',
              style: AppTheme.labelSmall
                  .copyWith(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 2),
          Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                  3,
                  (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: i <= 1 ? 20 : 8,
                        height: 4,
                        decoration: BoxDecoration(
                          color: i <= 1
                              ? AppColors.primary
                              : AppColors.outlineVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ))),
        ]),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              const SizedBox(height: 8),
              // ── Header ───────────────────────────────────────────────
              Row(children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryFixed,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.content_cut_rounded,
                      color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('FARHA',
                      style: AppTheme.titleLarge.copyWith(
                        fontFamily: 'PlusJakartaSans',
                        color: AppColors.primary,
                        letterSpacing: 4,
                      )),
                  Text('Create Customer Account',
                      style: AppTheme.labelSmall
                          .copyWith(color: AppColors.onSurfaceVariant)),
                ]),
              ]),
              const SizedBox(height: 32),

              // ── Name row ─────────────────────────────────────────────
              Row(children: [
                Expanded(
                    child: FarhaTextField(
                  controller: _firstNameCtrl,
                  label: 'First Name',
                  prefixIcon: Icons.person_outline_rounded,
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      AppValidators.required('First name')(v) ??
                      AppValidators.minLength(2, 'First name')(v),
                )),
                const SizedBox(width: 12),
                Expanded(
                    child: FarhaTextField(
                  controller: _lastNameCtrl,
                  label: 'Last Name',
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      AppValidators.required('Last name')(v) ??
                      AppValidators.minLength(2, 'Last name')(v),
                )),
              ]),
              const SizedBox(height: 16),

              // ── Email ─────────────────────────────────────────────────
              FarhaTextField(
                controller: _emailCtrl,
                label: 'Email Address',
                hint: 'you@example.com',
                prefixIcon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    AppValidators.required('Email')(v) ??
                    AppValidators.email()(v),
              ),
              const SizedBox(height: 16),

              // ── Phone ─────────────────────────────────────────────────
              FarhaTextField(
                controller: _phoneCtrl,
                label: 'Phone Number',
                hint: '+1234567890',
                prefixIcon: Icons.call_outlined,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    AppValidators.required('Phone number')(v) ??
                    AppValidators.phone()(v),
              ),
              const SizedBox(height: 16),

              // ── Gender ────────────────────────────────────────────────
              FarhaDropdown<String>(
                value: _gender.isEmpty ? null : _gender,
                label: 'Gender',
                prefixIcon: Icons.wc_rounded,
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Male')),
                  DropdownMenuItem(value: 'female', child: Text('Female')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                  DropdownMenuItem(
                      value: 'prefer_not_to_say',
                      child: Text('Prefer not to say')),
                ],
                onChanged: (v) => setState(() => _gender = v ?? ''),
                validator: (v) => (v == null || v.isEmpty)
                    ? 'Please select your gender.'
                    : null,
              ),
              const SizedBox(height: 16),

              // ── Password ──────────────────────────────────────────────
              FarhaTextField(
                controller: _passwordCtrl,
                label: 'Password',
                hint: '••••••••',
                prefixIcon: Icons.lock_outline_rounded,
                obscureText: _obscurePwd,
                textInputAction: TextInputAction.next,
                onChanged: (v) => setState(() =>
                    _passwordStrength = AppValidators.passwordStrength(v)),
                validator: (v) =>
                    AppValidators.required('Password')(v) ??
                    AppValidators.strongPassword()(v),
                suffixIcon: IconButton(
                  icon: Icon(
                      _obscurePwd
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.onSurfaceVariant),
                  onPressed: () => setState(() => _obscurePwd = !_obscurePwd),
                ),
              ),
              PasswordStrengthIndicator(strength: _passwordStrength),
              const SizedBox(height: 16),

              // ── Confirm password ──────────────────────────────────────
              FarhaTextField(
                controller: _confirmCtrl,
                label: 'Confirm Password',
                hint: '••••••••',
                prefixIcon: Icons.verified_user_outlined,
                obscureText: _obscureConfirm,
                textInputAction: TextInputAction.done,
                validator:
                    AppValidators.matchPassword(() => _passwordCtrl.text),
                suffixIcon: IconButton(
                  icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.onSurfaceVariant),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              const SizedBox(height: 16),

              // ── Language ──────────────────────────────────────────────
              FarhaDropdown<String>(
                value: _language,
                label: 'Preferred Language',
                prefixIcon: Icons.language_rounded,
                items: const [
                  DropdownMenuItem(value: 'en', child: Text('English')),
                  DropdownMenuItem(value: 'fr', child: Text('Français')),
                ],
                onChanged: (v) => setState(() => _language = v ?? 'en'),
              ),
              const SizedBox(height: 20),

              // ── Terms ─────────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _termsAccepted,
                    onChanged: (v) =>
                        setState(() => _termsAccepted = v ?? false),
                    activeColor: AppColors.primary,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Wrap(children: [
                        Text('I agree to the ', style: AppTheme.bodySmall),
                        GestureDetector(
                          onTap: () => _showPolicy(context, 'Terms of Service', _termsText),
                          child: Text('Terms of Service',
                              style: AppTheme.bodySmall.copyWith(
                                  color: AppColors.primary,
                                  decoration: TextDecoration.underline)),
                        ),
                        Text(' and ', style: AppTheme.bodySmall),
                        GestureDetector(
                          onTap: () => _showPolicy(context, 'Privacy Policy', _privacyText),
                          child: Text('Privacy Policy',
                              style: AppTheme.bodySmall.copyWith(
                                  color: AppColors.primary,
                                  decoration: TextDecoration.underline)),
                        ),
                        Text('.', style: AppTheme.bodySmall),
                      ]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              FarhaButton(
                label: 'Sign Up',
                isLoading: _isLoading,
                onPressed: _submit,
                icon: Icons.arrow_forward_rounded,
              ),
              const SizedBox(height: 16),

              Center(
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('Already have an account? ',
                      style: AppTheme.bodyMedium
                          .copyWith(color: AppColors.onSurfaceVariant)),
                  TextButton(
                    onPressed: () => context.push(Routes.login),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      minimumSize: Size.zero,
                    ),
                    child: Text('Login here',
                        style: AppTheme.labelLarge
                            .copyWith(color: AppColors.primary)),
                  ),
                ]),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _showPolicy(BuildContext context, String title, String body) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (_, ctrl) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Text(title, style: AppTheme.titleLarge.copyWith(fontFamily: 'PlusJakartaSans')),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                controller: ctrl,
                child: Text(body,
                    style: AppTheme.bodyMedium.copyWith(
                        color: AppColors.onSurfaceVariant, height: 1.6)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  static const _termsText = '''
By creating a Farha account, you agree to the following terms:

1. Eligibility
You must be at least 18 years old to use Farha. By registering, you confirm that the information you provide is accurate and complete.

2. Account Responsibility
You are responsible for maintaining the confidentiality of your account credentials. You agree to notify us immediately of any unauthorised use of your account.

3. Use of the Platform
Farha is a marketplace connecting customers with African fashion tailors. You agree to use the platform only for lawful purposes and in accordance with these terms.

4. Orders and Payments
All orders placed through Farha are subject to acceptance by the tailor. Prices are displayed in the currency shown. Payment is required to confirm an order.

5. Cancellations and Refunds
You may cancel an order before production begins. Refund eligibility depends on the order status at the time of cancellation and is at the discretion of the tailor and Farha.

6. Intellectual Property
All content on Farha, including logos, designs, and text, is the property of Farha or its licensors and may not be reproduced without permission.

7. Limitation of Liability
Farha is not liable for any indirect, incidental, or consequential damages arising from the use of the platform.

8. Changes to Terms
Farha reserves the right to update these terms at any time. Continued use of the platform constitutes acceptance of the revised terms.

Last updated: January 2025
''';

  static const _privacyText = '''
Farha is committed to protecting your personal information. This policy explains how we collect, use, and safeguard your data.

1. Information We Collect
We collect information you provide when registering (name, email, phone number), as well as usage data and measurement profiles you voluntarily save.

2. How We Use Your Information
Your information is used to process orders, facilitate communication between customers and tailors, and improve the Farha experience.

3. Sharing Your Information
We do not sell your personal data. We share information with tailors only as necessary to fulfil your orders, and with service providers who help us operate the platform.

4. Data Security
We use industry-standard encryption and security practices to protect your data. However, no transmission over the internet is completely secure.

5. Measurement Data
Any body measurements you save are stored securely and are only shared with tailors you choose to order from.

6. Your Rights
You have the right to access, correct, or delete your personal data at any time by contacting us through the app.

7. Cookies
Farha may use cookies and similar technologies to improve your experience on the platform.

8. Contact
For privacy-related questions, contact us at privacy@farha-app.com.

Last updated: January 2025
''';
}
