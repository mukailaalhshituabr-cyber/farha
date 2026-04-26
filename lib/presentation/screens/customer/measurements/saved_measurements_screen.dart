// lib/presentation/screens/customer/measurements/saved_measurements_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/measurement_model.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../providers/order_provider.dart';
import '../../../widgets/common/farha_bottom_nav.dart';
import '../../../widgets/common/farha_confirm_dialog.dart';
import '../../../widgets/common/farha_snackbar.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final measurementsProvider =
    FutureProvider<List<MeasurementModel>>((ref) async {
  final repo = ref.watch(measurementRepositoryProvider);
  final result = await repo.getProfiles();
  return result.items;
});

// ── Screen ────────────────────────────────────────────────────────────────────

class SavedMeasurementsScreen extends ConsumerWidget {
  const SavedMeasurementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l       = AppL10n.of(context);
    final async   = ref.watch(measurementsProvider);

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
        title: Text(l.savedMeasurements,
            style: AppTheme.titleLarge.copyWith(
                fontFamily: 'PlusJakartaSans')),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded,
                color: AppColors.primary, size: 26),
            onPressed: () => _showAddSheet(context, ref, l),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.outline, size: 48),
            const SizedBox(height: 12),
            Text(l.somethingWrong,
                style: AppTheme.bodyMedium
                    .copyWith(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 16),
            FilledButton(
                onPressed: () => ref.invalidate(measurementsProvider),
                child: Text(l.retry)),
          ]),
        ),
        data: (items) => items.isEmpty
            ? _EmptyState(
                l: l,
                onAdd: () => _showAddSheet(context, ref, l),
              )
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async =>
                    ref.invalidate(measurementsProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 10),
                  itemBuilder: (_, i) => _MeasurementCard(
                    profile: items[i],
                    l: l,
                    onEdit: () => _showEditSheet(
                        context, ref, l, items[i]),
                    onDelete: () async {
                      final confirmed = await FarhaConfirmDialog.show(
                        context,
                        title: 'Delete Profile?',
                        body:  '"${items[i].profileName}" will be permanently removed.',
                        confirmLabel: 'Delete',
                        isDangerous: true,
                      );
                      if (!confirmed || !context.mounted) return;
                      final repo = ref.read(measurementRepositoryProvider);
                      final ok = (await repo.delete(items[i].id)).success;
                      if (!context.mounted) return;
                      if (ok) {
                        ref.invalidate(measurementsProvider);
                        FarhaSnackbar.success(context, 'Profile deleted.');
                      } else {
                        FarhaSnackbar.error(context, 'Could not delete profile.');
                      }
                    },
                  ),
                ),
              ),
      ),
      bottomNavigationBar: const CustomerBottomNav(currentIndex: 4),
    );
  }

  void _showAddSheet(
      BuildContext context, WidgetRef ref, AppL10n l) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AddMeasurementSheet(
        l: l,
        onSaved: () => ref.invalidate(measurementsProvider),
      ),
    );
  }

  void _showEditSheet(BuildContext context, WidgetRef ref, AppL10n l,
      MeasurementModel profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AddMeasurementSheet(
        l: l,
        existing: profile,
        onSaved: () => ref.invalidate(measurementsProvider),
      ),
    );
  }
}

// ── Measurement card ──────────────────────────────────────────────────────────

class _MeasurementCard extends StatelessWidget {
  final MeasurementModel profile;
  final AppL10n          l;
  final VoidCallback     onEdit;
  final VoidCallback     onDelete;

  const _MeasurementCard({
    required this.profile,
    required this.l,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final u = profile.unit;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(profile.profileName,
                style: AppTheme.titleSmall
                    .copyWith(fontWeight: FontWeight.w600)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primaryFixed,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(profile.garmentType.toUpperCase(),
                style: AppTheme.labelSmall.copyWith(
                    color: AppColors.primary, fontSize: 9)),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined,
                color: AppColors.primary, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppColors.error, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ]),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            if (profile.chest != null)
              _Stat(l.chest, '${profile.chest} $u'),
            if (profile.waist != null)
              _Stat(l.waist, '${profile.waist} $u'),
            if (profile.hips != null)
              _Stat(l.hips, '${profile.hips} $u'),
            if (profile.shoulderWidth != null)
              _Stat(l.shoulder, '${profile.shoulderWidth} $u'),
            if (profile.sleeveLength != null)
              _Stat(l.sleeve, '${profile.sleeveLength} $u'),
            if (profile.totalLength != null)
              _Stat(l.totalLength, '${profile.totalLength} $u'),
          ],
        ),
        if (profile.notes != null && profile.notes!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(profile.notes!,
              style: AppTheme.bodySmall
                  .copyWith(color: AppColors.onSurfaceVariant),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ],
      ]),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat(this.label, this.value);

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(label,
          style: AppTheme.labelSmall
              .copyWith(color: AppColors.onSurfaceVariant, fontSize: 10)),
      Text(value,
          style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600)),
    ],
  );
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final AppL10n l;
  final VoidCallback onAdd;
  const _EmptyState({required this.l, required this.onAdd});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.straighten_rounded,
          color: AppColors.outline, size: 56),
      const SizedBox(height: 16),
      Text(l.savedMeasurements,
          style: AppTheme.titleMedium
              .copyWith(color: AppColors.onSurface)),
      const SizedBox(height: 6),
      Text('Save your measurements once,\nuse them for every order.',
          style: AppTheme.bodyMedium
              .copyWith(color: AppColors.onSurfaceVariant),
          textAlign: TextAlign.center),
      const SizedBox(height: 24),
      FilledButton.icon(
        onPressed: onAdd,
        icon: const Icon(Icons.add_rounded, size: 18),
        label: Text(l.addProfile),
      ),
    ]),
  );
}

// ── Add measurement sheet ─────────────────────────────────────────────────────

class _AddMeasurementSheet extends ConsumerStatefulWidget {
  final AppL10n            l;
  final VoidCallback       onSaved;
  final MeasurementModel?  existing;
  const _AddMeasurementSheet({
    required this.l,
    required this.onSaved,
    this.existing,
  });

  @override
  ConsumerState<_AddMeasurementSheet> createState() =>
      _AddMeasurementSheetState();
}

class _AddMeasurementSheetState
    extends ConsumerState<_AddMeasurementSheet> {
  final _formKey      = GlobalKey<FormState>();
  final _nameCtrl     = TextEditingController();
  final _chestCtrl    = TextEditingController();
  final _waistCtrl    = TextEditingController();
  final _hipsCtrl     = TextEditingController();
  final _shoulderCtrl = TextEditingController();
  final _sleeveCtrl   = TextEditingController();
  final _lengthCtrl   = TextEditingController();
  final _notesCtrl    = TextEditingController();
  String _unit        = 'cm';
  String _garmentType = 'agbada';
  bool   _saving      = false;

  static const _garmentTypes = [
    'agbada', 'kaftan', 'jalabia', 'shirt', 'dress', 'trouser', 'general'
  ];

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    if (p != null) {
      _nameCtrl.text    = p.profileName;
      _unit             = p.unit;
      _garmentType      = p.garmentType;
      if (p.chest   != null) _chestCtrl.text    = p.chest!.toString();
      if (p.waist   != null) _waistCtrl.text    = p.waist!.toString();
      if (p.hips    != null) _hipsCtrl.text     = p.hips!.toString();
      if (p.shoulderWidth  != null) _shoulderCtrl.text = p.shoulderWidth!.toString();
      if (p.sleeveLength   != null) _sleeveCtrl.text   = p.sleeveLength!.toString();
      if (p.totalLength    != null) _lengthCtrl.text   = p.totalLength!.toString();
      if (p.notes != null) _notesCtrl.text = p.notes!;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _chestCtrl.dispose();
    _waistCtrl.dispose();
    _hipsCtrl.dispose();
    _shoulderCtrl.dispose();
    _sleeveCtrl.dispose();
    _lengthCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final data = {
      'profile_name': _nameCtrl.text.trim(),
      'garment_type': _garmentType,
      'unit':         _unit,
      if (_chestCtrl.text.isNotEmpty)
        'chest': double.tryParse(_chestCtrl.text),
      if (_waistCtrl.text.isNotEmpty)
        'waist': double.tryParse(_waistCtrl.text),
      if (_hipsCtrl.text.isNotEmpty)
        'hips': double.tryParse(_hipsCtrl.text),
      if (_shoulderCtrl.text.isNotEmpty)
        'shoulder_width': double.tryParse(_shoulderCtrl.text),
      if (_sleeveCtrl.text.isNotEmpty)
        'sleeve_length': double.tryParse(_sleeveCtrl.text),
      if (_lengthCtrl.text.isNotEmpty)
        'total_length': double.tryParse(_lengthCtrl.text),
      if (_notesCtrl.text.trim().isNotEmpty)
        'notes': _notesCtrl.text.trim(),
    };

    final repo = ref.read(measurementRepositoryProvider);
    final res = _isEdit
        ? await repo.update(widget.existing!.id, data)
        : await repo.create(data);
    final ok = res.success;
    setState(() => _saving = false);
    if (!mounted) return;
    if (ok) {
      widget.onSaved();
      Navigator.pop(context);
      FarhaSnackbar.success(
          context, _isEdit ? 'Measurements updated.' : 'Measurements saved.');
    } else {
      FarhaSnackbar.error(context, 'Could not save measurements.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.l;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
            // handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(_isEdit ? 'Edit Profile' : l.addProfile,
                style: AppTheme.titleLarge
                    .copyWith(fontFamily: 'PlusJakartaSans')),
            const SizedBox(height: 16),

            // Profile name
            _MiniField(
                controller: _nameCtrl,
                label: 'Profile Name (e.g. "My Kaftan")',
                required: true, l: l),
            const SizedBox(height: 12),

            // Garment type
            Text('Garment Type',
                style: AppTheme.labelMedium
                    .copyWith(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                children: _garmentTypes.map((g) {
                  final sel = _garmentType == g;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(g.toUpperCase(),
                          style: AppTheme.labelSmall.copyWith(
                              color: sel ? AppColors.primary
                                  : AppColors.onSurfaceVariant)),
                      selected: sel,
                      onSelected: (_) =>
                          setState(() => _garmentType = g),
                      backgroundColor: AppColors.surfaceContainerLow,
                      selectedColor: AppColors.primaryFixed,
                      showCheckmark: false,
                      side: BorderSide(
                          color: sel
                              ? AppColors.primary
                              : AppColors.outlineVariant),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100)),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // Unit toggle
            Text(l.unit_cm,
                style: AppTheme.labelMedium
                    .copyWith(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 6),
            Row(children: [
              _UnitBtn(label: 'cm',     selected: _unit == 'cm',
                  onTap: () => setState(() => _unit = 'cm')),
              const SizedBox(width: 8),
              _UnitBtn(label: 'inches', selected: _unit == 'inches',
                  onTap: () => setState(() => _unit = 'inches')),
            ]),
            const SizedBox(height: 12),

            // Measurement fields — 2 per row
            Row(children: [
              Expanded(child: _MiniField(
                  controller: _chestCtrl, label: l.chest, l: l)),
              const SizedBox(width: 10),
              Expanded(child: _MiniField(
                  controller: _waistCtrl, label: l.waist, l: l)),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _MiniField(
                  controller: _hipsCtrl, label: l.hips, l: l)),
              const SizedBox(width: 10),
              Expanded(child: _MiniField(
                  controller: _shoulderCtrl,
                  label: l.shoulder, l: l)),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _MiniField(
                  controller: _sleeveCtrl, label: l.sleeve, l: l)),
              const SizedBox(width: 10),
              Expanded(child: _MiniField(
                  controller: _lengthCtrl,
                  label: l.totalLength, l: l)),
            ]),
            const SizedBox(height: 10),
            _MiniField(
                controller: _notesCtrl,
                label: 'Notes (optional)',
                maxLines: 2, l: l),
            const SizedBox(height: 20),

            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white))
                  : Text(l.save, style: AppTheme.labelLarge),
            ),
          ]),
        ),
      ),
    );
  }
}

class _MiniField extends StatelessWidget {
  final TextEditingController controller;
  final String  label;
  final bool    required;
  final int     maxLines;
  final AppL10n l;

  const _MiniField({
    required this.controller,
    required this.label,
    required this.l,
    this.required = false,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(label,
          style: AppTheme.labelSmall
              .copyWith(color: AppColors.onSurfaceVariant)),
      const SizedBox(height: 4),
      TextFormField(
        controller: controller,
        maxLines:   maxLines,
        minLines:   1,
        keyboardType: maxLines == 1
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        validator: required
            ? (v) => (v == null || v.trim().isEmpty)
                ? l.fieldRequired : null
            : null,
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.surfaceContainerLow,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
                color: AppColors.primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 10),
        ),
      ),
    ],
  );
}

class _UnitBtn extends StatelessWidget {
  final String   label;
  final bool     selected;
  final VoidCallback onTap;
  const _UnitBtn({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? AppColors.primaryFixed : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
            color: selected ? AppColors.primary : AppColors.outlineVariant,
            width: selected ? 1.5 : 0.5),
      ),
      child: Text(label,
          style: AppTheme.labelMedium.copyWith(
              color: selected ? AppColors.primary
                  : AppColors.onSurfaceVariant)),
    ),
  );
}
