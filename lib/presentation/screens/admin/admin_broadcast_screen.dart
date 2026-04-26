// lib/presentation/screens/admin/admin_broadcast_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/farha_snackbar.dart';
import 'admin_shell.dart';

class AdminBroadcastScreen extends ConsumerStatefulWidget {
  const AdminBroadcastScreen({super.key});
  @override
  ConsumerState<AdminBroadcastScreen> createState() => _AdminBroadcastScreenState();
}

class _AdminBroadcastScreenState extends ConsumerState<AdminBroadcastScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _titleCtrl   = TextEditingController();
  final _bodyCtrl    = TextEditingController();
  String  _target    = 'all';
  bool    _sending   = false;
  int?    _lastCount;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _sending = true; _lastCount = null; });
    final res = await ref.read(apiClientProvider).post(ApiConstants.adminBroadcast, data: {
      'title':  _titleCtrl.text.trim(),
      'body':   _bodyCtrl.text.trim(),
      'target': _target,
    });
    setState(() => _sending = false);
    if (!mounted) return;
    if (res.success) {
      final recipients = (res.data as Map<String, dynamic>?)?['recipients'] as int? ?? 0;
      setState(() => _lastCount = recipients);
      _titleCtrl.clear();
      _bodyCtrl.clear();
      FarhaSnackbar.success(context, 'Broadcast sent to $recipients users.');
    } else {
      FarhaSnackbar.error(context, res.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Broadcast Notification',
              style: AppTheme.headlineMedium.copyWith(
                  color: Colors.white, fontFamily: 'PlusJakartaSans')),
          const SizedBox(height: 4),
          Text('Send a push notification to your users.',
              style: AppTheme.bodySmall.copyWith(color: Colors.white54)),
          const SizedBox(height: 28),

          Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Target audience
              Text('Target Audience',
                  style: AppTheme.labelMedium.copyWith(color: Colors.white54)),
              const SizedBox(height: 10),
              Wrap(spacing: 10, children: [
                for (final entry in {
                  'All Users': 'all',
                  'Customers': 'customers',
                  'Tailors':   'tailors',
                }.entries)
                  ChoiceChip(
                    label: Text(entry.key),
                    selected: _target == entry.value,
                    selectedColor: AppColors.primary,
                    backgroundColor: const Color(0xFF2A1010),
                    labelStyle: TextStyle(
                      color: _target == entry.value ? Colors.white : Colors.white54,
                    ),
                    onSelected: (_) => setState(() => _target = entry.value),
                  ),
              ]),
              const SizedBox(height: 24),

              // Title
              Text('Notification Title',
                  style: AppTheme.labelMedium.copyWith(color: Colors.white54)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: _dec('e.g. New Collection Available!'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),

              // Body
              Text('Message',
                  style: AppTheme.labelMedium.copyWith(color: Colors.white54)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bodyCtrl,
                style: const TextStyle(color: Colors.white),
                maxLines: 4,
                decoration: _dec('Write your message here…'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Message is required' : null,
              ),
              const SizedBox(height: 28),

              // Preview card
              if (_titleCtrl.text.isNotEmpty || _bodyCtrl.text.isNotEmpty) ...[
                Text('Preview',
                    style: AppTheme.labelMedium.copyWith(color: Colors.white54)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Row(children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.notifications_rounded,
                          color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_titleCtrl.text.isEmpty ? 'Title' : _titleCtrl.text,
                          style: AppTheme.labelMedium.copyWith(
                              color: Colors.white, fontWeight: FontWeight.w600)),
                      Text(_bodyCtrl.text.isEmpty ? 'Message body…' : _bodyCtrl.text,
                          style: AppTheme.bodySmall.copyWith(color: Colors.white60),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                    ])),
                  ]),
                ),
                const SizedBox(height: 20),
              ],

              // Success banner
              if (_lastCount != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
                    const SizedBox(width: 8),
                    Text('Sent to $_lastCount users',
                        style: AppTheme.bodySmall.copyWith(color: Colors.green)),
                  ]),
                ),
              ],

              SizedBox(
                width: double.infinity, height: 52,
                child: FilledButton.icon(
                  onPressed: _sending ? null : _send,
                  icon: _sending
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_rounded, size: 18),
                  label: Text(_sending ? 'Sending…' : 'Send Broadcast'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Colors.white24),
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.05),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.error),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}
