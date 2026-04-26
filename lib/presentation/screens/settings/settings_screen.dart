// lib/presentation/screens/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/locale_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../routes/app_router.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final l      = AppL10n.of(context);
    final locale = ref.watch(localeProvider);
    final user   = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.onBackground, size: 20),
          onPressed: () {
            // Go back to profile depending on user type
            if (context.canPop()) {
              context.pop();
            } else if (user?.isTailor == true) {
              context.go(Routes.tailorProfile);
            } else {
              context.go(Routes.customerProfile);
            }
          },
        ),
        title: Text(l.settings,
            style: AppTheme.titleLarge.copyWith(
                fontFamily: 'PlusJakartaSans')),
      ),
      body: ListView(
        children: [

          // ── Language ──────────────────────────────────────────
          _SectionHeader(title: l.appLanguage),
          _RadioTile<String>(
            value: 'en',
            groupValue: locale.languageCode,
            title: l.english,
            subtitle: 'English',
            onChanged: (v) =>
                ref.read(localeProvider.notifier).setLanguage(v),
          ),
          _RadioTile<String>(
            value: 'fr',
            groupValue: locale.languageCode,
            title: l.french,
            subtitle: 'Français',
            onChanged: (v) =>
                ref.read(localeProvider.notifier).setLanguage(v),
          ),

          const _Divider(),

          // ── Notifications ─────────────────────────────────────
          _SectionHeader(title: l.notifications),
          SwitchListTile(
            value: _notificationsEnabled,
            onChanged: (v) => setState(() => _notificationsEnabled = v),
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primaryFixed,
            title: Text(l.pushNotifications, style: AppTheme.bodyMedium),
            subtitle: Text(l.notificationsEnabled,
                style: AppTheme.bodySmall.copyWith(
                    color: AppColors.onSurfaceVariant)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16),
          ),

          const _Divider(),

          // ── Support ───────────────────────────────────────────
          _SectionHeader(title: l.helpSupport),
          _ActionTile(
            icon: Icons.help_outline_rounded,
            title: l.helpSupport,
            onTap: () => context.push(Routes.helpSupport),
          ),
          _ActionTile(
            icon: Icons.privacy_tip_outlined,
            title: l.privacyPolicy,
            onTap: () => _launchUrl('https://farha.app/privacy'),
          ),
          _ActionTile(
            icon: Icons.description_outlined,
            title: l.termsOfService,
            onTap: () => _launchUrl('https://farha.app/terms'),
          ),

          const _Divider(),

          // ── About ─────────────────────────────────────────────
          _SectionHeader(title: l.about),
          _ActionTile(
            icon: Icons.info_outline_rounded,
            title: '${l.about} Farha',
            onTap: () => _showAboutDialog(context, l),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '${l.version} 1.0.0',
              style: AppTheme.bodySmall.copyWith(
                  color: AppColors.outline),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showAboutDialog(BuildContext context, AppL10n l) {
    showAboutDialog(
      context: context,
      applicationName: 'Farha',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2024 Farha — The Digital Atelier',
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
    child: Text(title.toUpperCase(),
        style: AppTheme.labelSmall.copyWith(
            color: AppColors.onSurfaceVariant, letterSpacing: 1.2)),
  );
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) =>
      const Divider(indent: 16, endIndent: 16, height: 1);
}

class _RadioTile<T> extends StatelessWidget {
  final T       value;
  final T       groupValue;
  final String  title;
  final String  subtitle;
  final void Function(T) onChanged;

  const _RadioTile({
    required this.value,
    required this.groupValue,
    required this.title,
    required this.subtitle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return ListTile(
      leading: Icon(
        selected
            ? Icons.radio_button_checked_rounded
            : Icons.radio_button_unchecked_rounded,
        color: selected ? AppColors.primary : AppColors.outline,
        size: 22,
      ),
      title: Text(title,
          style: AppTheme.bodyMedium.copyWith(
              fontWeight:
                  selected ? FontWeight.w600 : FontWeight.w400,
              color: selected
                  ? AppColors.primary
                  : AppColors.onSurface)),
      subtitle: Text(subtitle,
          style: AppTheme.bodySmall.copyWith(
              color: AppColors.onSurfaceVariant)),
      onTap: () => onChanged(value),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData    icon;
  final String      title;
  final VoidCallback onTap;

  const _ActionTile(
      {required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: AppColors.onSurfaceVariant, size: 22),
    title: Text(title, style: AppTheme.bodyMedium),
    trailing: const Icon(Icons.chevron_right_rounded,
        color: AppColors.outline, size: 20),
    onTap: onTap,
    contentPadding:
        const EdgeInsets.symmetric(horizontal: 16),
  );
}
