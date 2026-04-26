// lib/presentation/screens/auth/choose_user_type_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../routes/app_router.dart';

class ChooseUserTypeScreen extends StatefulWidget {
  const ChooseUserTypeScreen({super.key});

  @override
  State<ChooseUserTypeScreen> createState() => _ChooseUserTypeScreenState();
}

class _ChooseUserTypeScreenState extends State<ChooseUserTypeScreen> {
  String? _selected; // 'customer' | 'tailor'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        title: Column(
          children: [
            Text('Step 01', style: AppTheme.labelSmall.copyWith(
                color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width:  i == 0 ? 20 : 8, height: 4,
                decoration: BoxDecoration(
                  color: i == 0 ? AppColors.primary : AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              )),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              Text('I am a...', style: AppTheme.displayMedium),
              const SizedBox(height: 8),
              Text(
                'Choose the account type that best fits your journey in the atelier.',
                style: AppTheme.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 40),

              // ── Customer card ──────────────────────────────────────────
              _TypeCard(
                type:        'customer',
                selected:    _selected == 'customer',
                icon:        Icons.shopping_bag_outlined,
                title:       'Customer',
                subtitle:    'I want to order clothes',
                onTap:       () => setState(() => _selected = 'customer'),
              ),
              const SizedBox(height: 16),

              // ── Tailor card ────────────────────────────────────────────
              _TypeCard(
                type:        'tailor',
                selected:    _selected == 'tailor',
                icon:        Icons.content_cut_rounded,
                title:       'Tailor',
                subtitle:    'I want to sell my work',
                onTap:       () => setState(() => _selected = 'tailor'),
              ),

              const Spacer(),

              // ── Continue button ────────────────────────────────────────
              ElevatedButton.icon(
                onPressed: _selected == null ? null : () {
                  if (_selected == 'customer') {
                    context.push(Routes.customerRegister);
                  } else {
                    context.push(Routes.tailorRegister);
                  }
                },
                icon:  const Icon(Icons.arrow_forward_rounded, size: 20),
                label: const Text('Continue'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                  disabledBackgroundColor: AppColors.surfaceContainerHighest,
                  disabledForegroundColor: AppColors.outline,
                ),
              ),
              const SizedBox(height: 16),

              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Already have an account? ',
                      style: AppTheme.bodyMedium.copyWith(color: AppColors.onSurfaceVariant)),
                    TextButton(
                      onPressed: () => context.push(Routes.login),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        minimumSize: Size.zero,
                      ),
                      child: Text('Log in',
                        style: AppTheme.labelLarge.copyWith(color: AppColors.primary)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final String   type, title, subtitle;
  final IconData icon;
  final bool     selected;
  final VoidCallback onTap;

  const _TypeCard({
    required this.type, required this.title, required this.subtitle,
    required this.icon, required this.selected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: selected ? AppColors.surfaceContainerHighest : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:  selected ? AppColors.primary : AppColors.outlineVariant,
          width:  selected ? 2 : 0.5,
        ),
        boxShadow: selected ? [
          BoxShadow(color: AppColors.primary.withValues(alpha:0.10),
              blurRadius: 20, offset: const Offset(0, 8)),
        ] : [],
      ),
      child: InkWell(
        onTap:        onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color:        selected ? AppColors.primary : AppColors.primaryFixed,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 28,
                    color: selected ? AppColors.onPrimary : AppColors.primary),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTheme.titleLarge.copyWith(
                      color: selected ? AppColors.primary : AppColors.onBackground,
                    )),
                    const SizedBox(height: 4),
                    Text(subtitle, style: AppTheme.bodyMedium.copyWith(
                        color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}
