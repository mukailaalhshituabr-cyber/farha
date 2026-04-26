// lib/presentation/screens/support/help_support_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const _faqs = [
    {
      'q': 'How do I place a custom order?',
      'a': 'Go to the Shop tab and tap "Custom Made", or tap "Create Custom Order" from your dashboard. Choose your tailor, enter your measurements and preferences, then confirm and pay.',
    },
    {
      'q': 'How do I track my order?',
      'a': 'Go to Orders → tap any order → tap "Track Order". You\'ll see the real-time progress of your garment from cutting through delivery.',
    },
    {
      'q': 'Can I cancel my order?',
      'a': 'You can cancel an order as long as it hasn\'t been delivered. Go to Orders → select the order → tap "Cancel Order" and provide a reason.',
    },
    {
      'q': 'How do I pay the remaining balance?',
      'a': 'When your order is ready, you\'ll see a "Pay Remaining Balance" button on the order detail page. Tap it to complete your payment.',
    },
    {
      'q': 'How do I save my measurements?',
      'a': 'Go to Profile → Saved Measurements → tap "Add New Profile" to save a set of measurements you can reuse for future orders.',
    },
    {
      'q': 'How do I contact my tailor?',
      'a': 'Tap the Messages tab at the bottom of the screen. You\'ll see all your conversations. Tap a conversation to send a message.',
    },
    {
      'q': 'How do I update my profile photo?',
      'a': 'Go to Profile → tap your profile photo → choose "Take Photo" or "Choose from Gallery".',
    },
    {
      'q': 'How do I change the app language?',
      'a': 'Go to Profile → Settings → App Language and select English or Français.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0, scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.onBackground, size: 20),
          onPressed: () => context.canPop() ? context.pop() : context.go('/customer/home'),
        ),
        title: Text(l.helpSupport,
            style: AppTheme.titleLarge.copyWith(
                fontFamily: 'PlusJakartaSans')),
      ),
      body: ListView(
        children: [
          // ── Hero banner ─────────────────────────────────────────
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('How can we help?',
                      style: AppTheme.titleLarge
                          .copyWith(color: Colors.white,
                              fontFamily: 'PlusJakartaSans')),
                  const SizedBox(height: 6),
                  Text('Find answers below or reach out to us directly.',
                      style: AppTheme.bodySmall
                          .copyWith(color: Colors.white70)),
                ]),
              ),
              const Icon(Icons.support_agent_rounded,
                  color: Colors.white, size: 48),
            ]),
          ),

          // ── Contact options ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Expanded(
                child: _ContactCard(
                  icon: Icons.email_outlined,
                  label: 'Email Us',
                  sublabel: 'support@farha.app',
                  onTap: () => _launch('mailto:support@farha.app'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ContactCard(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Live Chat',
                  sublabel: 'Mon–Sat 8am–8pm',
                  onTap: () => _launch('https://farha.app/support'),
                ),
              ),
            ]),
          ),

          const SizedBox(height: 24),

          // ── FAQ section ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Frequently Asked Questions',
                style: AppTheme.titleMedium
                    .copyWith(fontFamily: 'PlusJakartaSans')),
          ),
          const SizedBox(height: 8),
          ..._faqs.map((faq) => _FaqTile(
              question: faq['q']!, answer: faq['a']!)),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   sublabel;
  final VoidCallback onTap;

  const _ContactCard({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.outlineVariant, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 26),
          const SizedBox(height: 10),
          Text(label, style: AppTheme.titleSmall),
          const SizedBox(height: 2),
          Text(sublabel,
              style: AppTheme.bodySmall
                  .copyWith(color: AppColors.onSurfaceVariant)),
        ],
      ),
    ),
  );
}

class _FaqTile extends StatefulWidget {
  final String question;
  final String answer;
  const _FaqTile({required this.question, required this.answer});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: ExpansionTile(
        tilePadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding:
            const EdgeInsets.fromLTRB(16, 0, 16, 16),
        backgroundColor: AppColors.surfaceContainerLowest,
        collapsedBackgroundColor: AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        iconColor: AppColors.primary,
        collapsedIconColor: AppColors.onSurfaceVariant,
        onExpansionChanged: (v) => setState(() => _expanded = v),
        title: Text(widget.question,
            style: AppTheme.bodyMedium.copyWith(
              fontWeight:
                  _expanded ? FontWeight.w600 : FontWeight.w400,
              color: _expanded
                  ? AppColors.primary
                  : AppColors.onSurface,
            )),
        children: [
          Text(widget.answer,
              style: AppTheme.bodyMedium
                  .copyWith(color: AppColors.onSurfaceVariant)),
        ],
      ),
    ),
  );
}
