// lib/presentation/screens/profile/edit_profile_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/image_service.dart';
import '../../../data/services/permission_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/farha_snackbar.dart';

/// Shared edit-profile screen — auto-adapts to customer vs tailor fields.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey         = GlobalKey<FormState>();
  late final _firstCtrl  = TextEditingController();
  late final _lastCtrl   = TextEditingController();
  late final _phoneCtrl  = TextEditingController();
  late final _shopCtrl   = TextEditingController();
  late final _locCtrl    = TextEditingController();
  late final _bioCtrl    = TextEditingController();
  bool _uploadingPhoto   = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    if (user == null) return;
    _firstCtrl.text = user.firstName;
    _lastCtrl.text  = user.lastName;
    _phoneCtrl.text = user.phone ?? '';
    if (user.isTailor && user.profile != null) {
      final p = user.profile;
      _shopCtrl.text = p.shopName ?? '';
    }
  }

  @override
  void dispose() {
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _phoneCtrl.dispose();
    _shopCtrl.dispose();
    _locCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  // ── Photo picking ──────────────────────────────────────────────────────────

  String _avatarInitials(dynamic user) {
    final first = (user?.firstName as String? ?? '');
    final last  = (user?.lastName  as String? ?? '');
    if (first.isEmpty && last.isEmpty) return '?';
    return '${first.isNotEmpty ? first[0] : ''}${last.isNotEmpty ? last[0] : ''}'
        .toUpperCase();
  }

  Future<void> _showPhotoSourceSheet() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const Text('Change Profile Photo',
                style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontWeight: FontWeight.w600,
                    fontSize: 16)),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined,
                  color: AppColors.primary),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.primary),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.cancel_outlined,
                  color: AppColors.onSurfaceVariant),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ]),
        ),
      ),
    );
    if (source == null || !mounted) return;
    await _pickPhoto(source);
  }

  Future<void> _pickPhoto(ImageSource source) async {
    if (source == ImageSource.camera) {
      final granted = await PermissionService.request(
        context, AppPermission.camera,
      );
      if (!granted || !mounted) return;
    }
    // Gallery: Android 13+ uses system photo picker — no permission needed.

    final svc  = ImageService(ref.read(apiClientProvider));
    final File? file = source == ImageSource.camera
        ? await svc.pickFromCamera()
        : await svc.pickFromGallery();
    if (!mounted) return;
    if (file == null) {
      FarhaSnackbar.error(context,
          'Could not read photo. Try a JPEG or PNG under 5 MB.');
      return;
    }

    setState(() => _uploadingPhoto = true);
    String? serverError;
    final photoUrl = await svc.uploadProfilePhoto(
      file,
      onError: (msg) => serverError = msg,
    );
    setState(() => _uploadingPhoto = false);

    if (!mounted) return;
    if (photoUrl != null) {
      final updated = ref.read(authProvider).user?.copyWith(profilePhoto: photoUrl);
      if (updated != null) ref.read(authProvider.notifier).updateUser(updated);
      FarhaSnackbar.success(context, 'Profile photo updated.');
    } else {
      FarhaSnackbar.error(context, serverError ?? 'Could not upload photo. Try again.');
    }
  }

  // ── Save ───────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(authProvider).user;
    final ok = await ref.read(authProvider.notifier).updateProfile(
      firstName:    _firstCtrl.text.trim(),
      lastName:     _lastCtrl.text.trim(),
      phone:        _phoneCtrl.text.trim().isEmpty
                        ? null : _phoneCtrl.text.trim(),
      shopName:     user?.isTailor == true && _shopCtrl.text.trim().isNotEmpty
                        ? _shopCtrl.text.trim() : null,
      shopLocation: user?.isTailor == true && _locCtrl.text.trim().isNotEmpty
                        ? _locCtrl.text.trim() : null,
      bio:          user?.isTailor == true && _bioCtrl.text.trim().isNotEmpty
                        ? _bioCtrl.text.trim() : null,
    );
    if (!mounted) return;
    if (ok) {
      FarhaSnackbar.success(context, 'Profile updated successfully.');
      Navigator.pop(context);
    } else {
      FarhaSnackbar.error(context, 'Could not save changes. Try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l        = AppL10n.of(context);
    final user     = ref.watch(authProvider).user;
    final isTailor = user?.isTailor ?? false;
    final isLoading = ref.watch(authProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0, scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.onBackground, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(l.editProfile,
            style: AppTheme.titleLarge.copyWith(
                fontFamily: 'PlusJakartaSans')),
        actions: [
          TextButton(
            onPressed: isLoading ? null : _save,
            child: isLoading
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary))
                : Text(l.save,
                    style: AppTheme.labelLarge.copyWith(
                        color: AppColors.primary)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Avatar ──────────────────────────────────────────────
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: AppColors.primaryFixed,
                    backgroundImage: user?.profilePhoto != null
                        ? NetworkImage(user!.profilePhoto!) : null,
                    child: _uploadingPhoto
                        ? const CircularProgressIndicator(
                            color: AppColors.primary, strokeWidth: 2)
                        : user?.profilePhoto == null
                            ? Text(
                                _avatarInitials(user),
                                style: AppTheme.headlineMedium
                                    .copyWith(color: AppColors.primary),
                              )
                            : null,
                  ),
                  GestureDetector(
                    onTap: _uploadingPhoto ? null : _showPhotoSourceSheet,
                    child: Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.background, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt_rounded,
                          color: Colors.white, size: 15),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Basic info ──────────────────────────────────────────
            _SectionLabel(l.firstName),
            _Field(
              controller: _firstCtrl,
              hint: l.firstName,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l.fieldRequired : null,
            ),
            const SizedBox(height: 14),
            _SectionLabel(l.lastName),
            _Field(
              controller: _lastCtrl,
              hint: l.lastName,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l.fieldRequired : null,
            ),
            const SizedBox(height: 14),
            _SectionLabel(l.phone),
            _Field(
              controller: _phoneCtrl,
              hint: '+1 234 567 8900',
              keyboardType: TextInputType.phone,
            ),

            // ── Tailor-only fields ──────────────────────────────────
            if (isTailor) ...[
              const SizedBox(height: 14),
              _SectionLabel(l.shopName),
              _Field(
                controller: _shopCtrl,
                hint: l.shopName,
              ),
              const SizedBox(height: 14),
              _SectionLabel(l.shopLocation),
              _Field(
                controller: _locCtrl,
                hint: l.shopLocation,
              ),
              const SizedBox(height: 14),
              _SectionLabel(l.aboutWork),
              _Field(
                controller: _bioCtrl,
                hint: l.aboutWork,
                maxLines: 4,
              ),
            ],

            const SizedBox(height: 32),
            FilledButton(
              onPressed: isLoading ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white))
                  : Text(l.save, style: AppTheme.labelLarge),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text,
        style: AppTheme.labelMedium
            .copyWith(color: AppColors.onSurfaceVariant)),
  );
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String  hint;
  final int     maxLines;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller:   controller,
    maxLines:     maxLines,
    minLines:     1,
    keyboardType: keyboardType,
    textCapitalization: TextCapitalization.words,
    validator:    validator,
    decoration: InputDecoration(
      hintText:    hint,
      hintStyle:   AppTheme.bodyMedium
          .copyWith(color: AppColors.onSurfaceVariant),
      filled:      true,
      fillColor:   AppColors.surfaceContainerLow,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:   BorderSide.none,
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:   const BorderSide(color: AppColors.error),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
            color: AppColors.primary, width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}
