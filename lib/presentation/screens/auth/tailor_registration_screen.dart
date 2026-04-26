// lib/presentation/screens/auth/tailor_registration_screen.dart
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

class TailorRegistrationScreen extends ConsumerStatefulWidget {
  const TailorRegistrationScreen({super.key});
  @override
  ConsumerState<TailorRegistrationScreen> createState() => _State();
}

class _State extends ConsumerState<TailorRegistrationScreen> {
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();

  // Step 1 — Basics
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl  = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _phoneCtrl     = TextEditingController();
  final _passwordCtrl  = TextEditingController();
  final _confirmCtrl   = TextEditingController();
  String _gender       = '';
  String _language     = 'en';
  bool   _obscurePwd   = true;
  bool   _obscureConf  = true;
  double _pwdStrength  = 0;

  // Step 2 — Business
  final _shopNameCtrl     = TextEditingController();
  final _shopLocationCtrl = TextEditingController();
  final _bioCtrl          = TextEditingController();
  int    _yearsExp        = 0;
  String _expLevel        = '';
  bool   _termsAccepted   = false;

  int  _currentStep = 0;
  bool _isLoading   = false;

  static const _expLevels = [
    ('apprentice',   '1 – 3 Years (Apprentice)'),
    ('intermediate', '3 – 7 Years (Intermediate)'),
    ('master',       '7 – 15 Years (Master Tailor)'),
    ('grandmaster',  '15+ Years (Grandmaster)'),
  ];

  @override
  void dispose() {
    for (final c in [_firstNameCtrl,_lastNameCtrl,_emailCtrl,_phoneCtrl,
                     _passwordCtrl,_confirmCtrl,_shopNameCtrl,
                     _shopLocationCtrl,_bioCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey2.currentState!.validate()) return;
    if (_expLevel.isEmpty) {
      FarhaSnackbar.error(context, 'Please select your experience level.'); return;
    }
    if (!_termsAccepted) {
      FarhaSnackbar.error(context, 'Please accept the Terms of Service.'); return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final repo = ref.read(authRepositoryProvider);
    final res  = await repo.registerTailor(
      firstName: _firstNameCtrl.text.trim(),
      lastName:  _lastNameCtrl.text.trim(),      email:                _emailCtrl.text.trim(),
      phone:                _phoneCtrl.text.trim(),
      gender:               _gender,
      password:             _passwordCtrl.text,
      passwordConfirmation: _confirmCtrl.text,
      language:             _language,
      shopName:             _shopNameCtrl.text.trim(),
      shopLocation:         _shopLocationCtrl.text.trim(),
      yearsExperience:      _yearsExp,
      experienceLevel:      _expLevel,
      bio:                  _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
      termsAccepted:        true,
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
          icon: Icon(_currentStep == 0
              ? Icons.close_rounded : Icons.arrow_back_rounded),
          onPressed: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            } else {
              context.pop();
            }
          },
        ),
        title: _StepIndicator(current: _currentStep, total: 2,
            labels: const ['Basics', 'Business', 'Verify']),
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _currentStep,
          children: [_buildStep1(), _buildStep2()],
        ),
      ),
    );
  }

  // ── Step 1: Basic info ──────────────────────────────────────────────────
  Widget _buildStep1() {
    return Form(
      key: _formKey1,
      child: ListView(padding: const EdgeInsets.symmetric(horizontal: 24), children: [
        const SizedBox(height: 16),
        Text('Create Tailor Account', style: AppTheme.headlineLarge),
        const SizedBox(height: 4),
        Text('Step 1: Your personal details',
          style: AppTheme.bodyMedium.copyWith(color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 28),

        Row(children: [
          Expanded(child: FarhaTextField(
            controller: _firstNameCtrl, label: 'First Name',
            prefixIcon: Icons.person_outline_rounded,
            textInputAction: TextInputAction.next,
            validator: (v) => AppValidators.required('First name')(v) ?? AppValidators.minLength(2,'First name')(v),
          )),
          const SizedBox(width: 12),
          Expanded(child: FarhaTextField(
            controller: _lastNameCtrl, label: 'Last Name',
            textInputAction: TextInputAction.next,
            validator: (v) => AppValidators.required('Last name')(v) ?? AppValidators.minLength(2,'Last name')(v),
          )),
        ]),
        const SizedBox(height: 16),

        FarhaTextField(
          controller: _emailCtrl, label: 'Email Address',
          hint: 'tailor@example.com', prefixIcon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next,
          validator: (v) => AppValidators.required('Email')(v) ?? AppValidators.email()(v),
        ),
        const SizedBox(height: 16),

        FarhaTextField(
          controller: _phoneCtrl, label: 'Phone Number', hint: '+1234567890',
          prefixIcon: Icons.call_outlined, keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          validator: (v) => AppValidators.required('Phone number')(v) ?? AppValidators.phone()(v),
        ),
        const SizedBox(height: 16),

        FarhaDropdown<String>(
          value: _gender.isEmpty ? null : _gender, label: 'Gender',
          prefixIcon: Icons.wc_rounded,
          items: const [
            DropdownMenuItem(value: 'female',           child: Text('Female')),
            DropdownMenuItem(value: 'male',             child: Text('Male')),
            DropdownMenuItem(value: 'other',            child: Text('Other')),
            DropdownMenuItem(value: 'prefer_not_to_say',child: Text('Prefer not to say')),
          ],
          onChanged: (v) => setState(() => _gender = v ?? ''),
          validator: (v) => (v == null || v.isEmpty) ? 'Please select your gender.' : null,
        ),
        const SizedBox(height: 16),

        FarhaDropdown<String>(
          value: _language, label: 'Preferred Language',
          prefixIcon: Icons.language_rounded,
          items: const [
            DropdownMenuItem(value: 'en', child: Text('English')),
            DropdownMenuItem(value: 'fr', child: Text('Français')),
          ],
          onChanged: (v) => setState(() => _language = v ?? 'en'),
        ),
        const SizedBox(height: 16),

        FarhaTextField(
          controller: _passwordCtrl, label: 'Password', hint: '••••••••',
          prefixIcon: Icons.lock_outline_rounded, obscureText: _obscurePwd,
          textInputAction: TextInputAction.next,
          onChanged: (v) => setState(() => _pwdStrength = AppValidators.passwordStrength(v)),
          validator: (v) => AppValidators.required('Password')(v) ?? AppValidators.strongPassword()(v),
          suffixIcon: IconButton(
            icon: Icon(_obscurePwd ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: AppColors.onSurfaceVariant),
            onPressed: () => setState(() => _obscurePwd = !_obscurePwd),
          ),
        ),
        PasswordStrengthIndicator(strength: _pwdStrength),
        const SizedBox(height: 16),

        FarhaTextField(
          controller: _confirmCtrl, label: 'Confirm Password', hint: '••••••••',
          prefixIcon: Icons.verified_user_outlined, obscureText: _obscureConf,
          textInputAction: TextInputAction.done,
          validator: AppValidators.matchPassword(() => _passwordCtrl.text),
          suffixIcon: IconButton(
            icon: Icon(_obscureConf ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: AppColors.onSurfaceVariant),
            onPressed: () => setState(() => _obscureConf = !_obscureConf),
          ),
        ),
        const SizedBox(height: 28),

        ElevatedButton.icon(
          onPressed: () {
            if (_formKey1.currentState!.validate() && _gender.isNotEmpty) {
              setState(() => _currentStep = 1);
            } else if (_gender.isEmpty) {
              FarhaSnackbar.error(context, 'Please select your gender.');
            }
          },
          icon:  const Icon(Icons.arrow_forward_rounded, size: 20),
          label: const Text('Next: Business Details'),
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))),
        ),
        const SizedBox(height: 32),
      ]),
    );
  }

  // ── Step 2: Business info ───────────────────────────────────────────────
  Widget _buildStep2() {
    return Form(
      key: _formKey2,
      child: ListView(padding: const EdgeInsets.symmetric(horizontal: 24), children: [
        const SizedBox(height: 16),
        Text('Step 2: Your Professional Presence', style: AppTheme.headlineLarge),
        const SizedBox(height: 4),
        Text('Define your atelier for customers',
          style: AppTheme.bodyMedium.copyWith(color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 28),

        FarhaTextField(
          controller: _shopNameCtrl, label: 'Shop / Business Name',
          prefixIcon: Icons.storefront_outlined, textInputAction: TextInputAction.next,
          validator: (v) => AppValidators.required('Shop name')(v) ?? AppValidators.minLength(2,'Shop name')(v),
        ),
        const SizedBox(height: 16),

        FarhaTextField(
          controller: _shopLocationCtrl, label: 'Shop Location',
          hint: 'e.g. Lagos Island, Nigeria',
          prefixIcon: Icons.location_on_outlined, textInputAction: TextInputAction.next,
          validator: AppValidators.required('Shop location'),
        ),
        const SizedBox(height: 16),

        FarhaDropdown<String>(
          value: _expLevel.isEmpty ? null : _expLevel,
          label: 'Years of Experience',
          prefixIcon: Icons.history_edu_rounded,
          items: _expLevels.map((e) => DropdownMenuItem(value: e.$1, child: Text(e.$2))).toList(),
          onChanged: (v) {
            setState(() {
              _expLevel = v ?? '';
              _yearsExp = switch(v) {
                'apprentice'   => 2,
                'intermediate' => 5,
                'master'       => 10,
                'grandmaster'  => 16,
                _              => 0,
              };
            });
          },
          validator: (v) => (v == null || v.isEmpty) ? 'Please select your experience level.' : null,
        ),
        const SizedBox(height: 16),

        FarhaTextField(
          controller: _bioCtrl, label: 'About Your Work (optional)',
          hint: 'Describe your specialty, style, heritage...',
          prefixIcon: Icons.info_outline_rounded,
          maxLines: 3, textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: 20),

        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Checkbox(
            value: _termsAccepted,
            onChanged: (v) => setState(() => _termsAccepted = v ?? false),
            activeColor: AppColors.primary,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Wrap(children: [
                Text('I agree to the ', style: AppTheme.bodySmall),
                GestureDetector(
                  onTap: () {},
                  child: Text('Terms of Service',
                    style: AppTheme.bodySmall.copyWith(
                        color: AppColors.primary, decoration: TextDecoration.underline)),
                ),
                Text(' and ', style: AppTheme.bodySmall),
                GestureDetector(
                  onTap: () {},
                  child: Text('Privacy Policy',
                    style: AppTheme.bodySmall.copyWith(
                        color: AppColors.primary, decoration: TextDecoration.underline)),
                ),
                Text('.', style: AppTheme.bodySmall),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 24),

        FarhaButton(
          label: 'Create Tailor Account',
          isLoading: _isLoading,
          onPressed: _submit,
          icon: Icons.arrow_forward_rounded,
        ),
        const SizedBox(height: 16),

        Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text('Already have an account? ',
            style: AppTheme.bodyMedium.copyWith(color: AppColors.onSurfaceVariant)),
          TextButton(
            onPressed: () => context.push(Routes.login),
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4), minimumSize: Size.zero),
            child: Text('Log In', style: AppTheme.labelLarge.copyWith(color: AppColors.primary)),
          ),
        ])),
        const SizedBox(height: 32),
      ]),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int current, total;
  final List<String> labels;
  const _StepIndicator({required this.current, required this.total, required this.labels});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      for (int i = 0; i <= total; i++) ...[
        Column(mainAxisSize: MainAxisSize.min, children: [
          Text(labels[i],
            style: AppTheme.labelSmall.copyWith(
              color: i <= current ? AppColors.primary : AppColors.onSurfaceVariant,
              fontWeight: i == current ? FontWeight.w600 : FontWeight.w400,
            )),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 24, height: 4,
            decoration: BoxDecoration(
              color: i <= current ? AppColors.primary : AppColors.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ]),
        if (i < total) const SizedBox(width: 8),
      ],
    ]);
  }
}
