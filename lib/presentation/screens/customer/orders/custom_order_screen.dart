// lib/presentation/screens/customer/orders/custom_order_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/order_provider.dart';
import '../../../widgets/common/farha_snackbar.dart';

// ── Tailor model (lightweight, for this screen only) ─────────────────────────

class _TailorItem {
  final String  id;
  final String  name;
  final String  shopName;
  final String  location;
  final double  rating;
  final int     totalReviews;
  final bool    isAvailable;
  final String? photoUrl;

  const _TailorItem({
    required this.id,
    required this.name,
    required this.shopName,
    required this.location,
    required this.rating,
    required this.totalReviews,
    required this.isAvailable,
    this.photoUrl,
  });

  factory _TailorItem.fromJson(Map<String, dynamic> j) => _TailorItem(
    id:           j['id'].toString(),
    name:         j['full_name'] as String? ?? '',
    shopName:     j['shop_name'] as String? ?? '',
    location:     j['shop_location'] as String? ?? '',
    rating:       (j['rating'] as num?)?.toDouble() ?? 0,
    totalReviews: j['total_reviews'] as int? ?? 0,
    isAvailable:  j['is_available'] as bool? ?? true,
    photoUrl:     j['profile_photo'] as String?,
  );
}

// ── Provider ──────────────────────────────────────────────────────────────────

final _tailorsProvider = FutureProvider<List<_TailorItem>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final res = await api.get(ApiConstants.tailorList, params: {'limit': 50});
  if (!res.success) return [];
  final data = res.data as Map<String, dynamic>;
  final list = data['tailors'] as List<dynamic>? ?? [];
  return list.map((e) => _TailorItem.fromJson(e as Map<String, dynamic>)).toList();
});

// ── Screen ────────────────────────────────────────────────────────────────────

class CustomOrderScreen extends ConsumerStatefulWidget {
  const CustomOrderScreen({super.key});

  @override
  ConsumerState<CustomOrderScreen> createState() => _CustomOrderScreenState();
}

class _CustomOrderScreenState extends ConsumerState<CustomOrderScreen> {
  int _step = 0; // 0: garment+measurements, 1: choose tailor, 2: details+submit

  // Step 0
  String _garmentType = 'Agbada';
  final _chestCtrl    = TextEditingController();
  final _waistCtrl    = TextEditingController();
  final _hipsCtrl     = TextEditingController();
  final _lengthCtrl   = TextEditingController();
  String _unit        = 'cm';

  static const _garmentTypes = [
    'Agbada', 'Kaftan', 'Boubou', 'Dress', 'Suit', "Children's Wear", 'Wedding Attire', 'Other',
  ];

  // Step 1
  _TailorItem? _selectedTailor;

  // Step 2
  final _budgetCtrl       = TextEditingController();
  final _instructionsCtrl = TextEditingController();
  bool _submitting        = false;

  @override
  void dispose() {
    _chestCtrl.dispose();
    _waistCtrl.dispose();
    _hipsCtrl.dispose();
    _lengthCtrl.dispose();
    _budgetCtrl.dispose();
    _instructionsCtrl.dispose();
    super.dispose();
  }

  bool get _step0Valid => true; // garment type always selected

  bool get _step1Valid => _selectedTailor != null;

  bool get _step2Valid {
    final budget = double.tryParse(_budgetCtrl.text.trim());
    return budget != null && budget > 0;
  }

  Future<void> _submit() async {
    if (!_step2Valid || _selectedTailor == null) return;
    setState(() => _submitting = true);

    final measurements = <String, String>{};
    if (_chestCtrl.text.isNotEmpty)  measurements['chest']  = _chestCtrl.text.trim();
    if (_waistCtrl.text.isNotEmpty)  measurements['waist']  = _waistCtrl.text.trim();
    if (_hipsCtrl.text.isNotEmpty)   measurements['hips']   = _hipsCtrl.text.trim();
    if (_lengthCtrl.text.isNotEmpty) measurements['length'] = _lengthCtrl.text.trim();

    final mStr = measurements.entries
        .map((e) => '${e.key}: ${e.value} $_unit')
        .join(', ');

    final instructions = [
      'Garment: $_garmentType',
      if (mStr.isNotEmpty) 'Measurements ($mStr)',
      if (_instructionsCtrl.text.trim().isNotEmpty)
        _instructionsCtrl.text.trim(),
    ].join('\n');

    final repo = ref.read(orderRepositoryProvider);
    final res = await repo.createOrder({
      'tailor_id':            _selectedTailor!.id,
      'order_type':           'custom',
      'quantity':             1,
      'total_amount':         double.parse(_budgetCtrl.text.trim()),
      'currency':             'CFA',
      'special_instructions': instructions,
    });

    setState(() => _submitting = false);
    if (!mounted) return;

    if (res.success) {
      ref.read(orderProvider.notifier).refresh();
      FarhaSnackbar.success(context, 'Custom order placed successfully!');
      context.go('/customer/orders');
    } else {
      FarhaSnackbar.error(context, res.message.isNotEmpty
          ? res.message
          : 'Could not place order. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.onBackground, size: 20),
          onPressed: () {
            if (_step > 0) {
              setState(() => _step--);
            } else {
              context.canPop() ? context.pop() : context.go('/customer/home');
            }
          },
        ),
        title: Text('Custom Order',
            style: AppTheme.titleLarge.copyWith(fontFamily: 'PlusJakartaSans')),
      ),
      body: Column(children: [
        // ── Step indicator ────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
          child: Row(children: List.generate(3, (i) {
            final done    = i < _step;
            final current = i == _step;
            return Expanded(
              child: Row(children: [
                if (i > 0)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: done ? AppColors.primary : AppColors.outlineVariant,
                    ),
                  ),
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: current || done ? AppColors.primary : AppColors.surfaceContainerLow,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: current || done ? AppColors.primary : AppColors.outlineVariant,
                    ),
                  ),
                  child: Center(
                    child: done
                        ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                        : Text('${i + 1}',
                            style: AppTheme.labelSmall.copyWith(
                                color: current ? Colors.white : AppColors.onSurfaceVariant)),
                  ),
                ),
                if (i < 2)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: _step > i + 1 ? AppColors.primary : AppColors.outlineVariant,
                    ),
                  ),
              ]),
            );
          })),
        ),

        // ── Step content ──────────────────────────────────────────────
        Expanded(
          child: IndexedStack(
            index: _step,
            children: [
              _StepGarment(
                garmentType: _garmentType,
                onGarmentChanged: (v) => setState(() => _garmentType = v),
                garmentTypes: _garmentTypes,
                chestCtrl: _chestCtrl,
                waistCtrl: _waistCtrl,
                hipsCtrl: _hipsCtrl,
                lengthCtrl: _lengthCtrl,
                unit: _unit,
                onUnitChanged: (v) => setState(() => _unit = v),
              ),
              _StepTailor(
                selected: _selectedTailor,
                onSelect: (t) => setState(() => _selectedTailor = t),
              ),
              _StepDetails(
                budgetCtrl: _budgetCtrl,
                instructionsCtrl: _instructionsCtrl,
                garmentType: _garmentType,
                tailor: _selectedTailor,
              ),
            ],
          ),
        ),

        // ── Bottom action ─────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: FilledButton(
            onPressed: _submitting ? null : () {
              if (_step == 0 && _step0Valid) {
                setState(() => _step = 1);
              } else if (_step == 1 && _step1Valid) {
                setState(() => _step = 2);
              } else if (_step == 2 && _step2Valid) {
                _submit();
              }
            },
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white))
                : Text(
                    _step < 2 ? 'Continue' : 'Place Custom Order',
                    style: AppTheme.labelLarge,
                  ),
          ),
        ),
      ]),
    );
  }
}

// ── Step 0: Garment type + measurements ──────────────────────────────────────

class _StepGarment extends StatelessWidget {
  final String garmentType;
  final ValueChanged<String> onGarmentChanged;
  final List<String> garmentTypes;
  final TextEditingController chestCtrl;
  final TextEditingController waistCtrl;
  final TextEditingController hipsCtrl;
  final TextEditingController lengthCtrl;
  final String unit;
  final ValueChanged<String> onUnitChanged;

  const _StepGarment({
    required this.garmentType,
    required this.onGarmentChanged,
    required this.garmentTypes,
    required this.chestCtrl,
    required this.waistCtrl,
    required this.hipsCtrl,
    required this.lengthCtrl,
    required this.unit,
    required this.onUnitChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('What would you like made?',
            style: AppTheme.titleMedium.copyWith(fontFamily: 'PlusJakartaSans')),
        const SizedBox(height: 4),
        Text('Select a garment type and optionally enter your measurements.',
            style: AppTheme.bodySmall.copyWith(color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 16),

        Wrap(
          spacing: 8, runSpacing: 8,
          children: garmentTypes.map((g) {
            final sel = garmentType == g;
            return FilterChip(
              label: Text(g),
              selected: sel,
              onSelected: (_) => onGarmentChanged(g),
              backgroundColor: AppColors.surfaceContainerLow,
              selectedColor: AppColors.primaryFixed,
              checkmarkColor: AppColors.primary,
              labelStyle: AppTheme.labelMedium.copyWith(
                  color: sel ? AppColors.primary : AppColors.onSurfaceVariant),
              side: BorderSide(
                  color: sel ? AppColors.primary : AppColors.outlineVariant),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100)),
              showCheckmark: false,
            );
          }).toList(),
        ),

        const SizedBox(height: 24),
        Text('Measurements (optional)',
            style: AppTheme.titleSmall),
        const SizedBox(height: 4),
        Text('Enter your measurements or the tailor will contact you.',
            style: AppTheme.bodySmall.copyWith(color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 12),

        Row(children: [
          _unitBtn('cm',     unit == 'cm',     () => onUnitChanged('cm')),
          const SizedBox(width: 8),
          _unitBtn('inches', unit == 'inches', () => onUnitChanged('inches')),
        ]),
        const SizedBox(height: 12),

        Row(children: [
          Expanded(child: _field('Chest', chestCtrl)),
          const SizedBox(width: 12),
          Expanded(child: _field('Waist', waistCtrl)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _field('Hips', hipsCtrl)),
          const SizedBox(width: 12),
          Expanded(child: _field('Total Length', lengthCtrl)),
        ]),
        const SizedBox(height: 16),
      ]),
    );
  }

  Widget _unitBtn(String label, bool sel, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: sel ? AppColors.primaryFixed : AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
                color: sel ? AppColors.primary : AppColors.outlineVariant,
                width: sel ? 1.5 : 0.5),
          ),
          child: Text(label,
              style: AppTheme.labelMedium.copyWith(
                  color: sel ? AppColors.primary : AppColors.onSurfaceVariant)),
        ),
      );

  Widget _field(String label, TextEditingController ctrl) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label,
          style: AppTheme.labelSmall.copyWith(color: AppColors.onSurfaceVariant)),
      const SizedBox(height: 4),
      TextField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.surfaceContainerLow,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    ],
  );
}

// ── Step 1: Choose tailor ─────────────────────────────────────────────────────

class _StepTailor extends ConsumerWidget {
  final _TailorItem? selected;
  final ValueChanged<_TailorItem> onSelect;

  const _StepTailor({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_tailorsProvider);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Choose a Tailor',
              style: AppTheme.titleMedium.copyWith(fontFamily: 'PlusJakartaSans')),
          const SizedBox(height: 4),
          Text('Select the tailor you want to work with.',
              style: AppTheme.bodySmall.copyWith(color: AppColors.onSurfaceVariant)),
        ]),
      ),
      Expanded(
        child: async.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary)),
          error: (_, __) => Center(
            child: Text('Could not load tailors.',
                style: AppTheme.bodyMedium
                    .copyWith(color: AppColors.onSurfaceVariant)),
          ),
          data: (tailors) => tailors.isEmpty
              ? Center(
                  child: Text('No tailors available.',
                      style: AppTheme.bodyMedium
                          .copyWith(color: AppColors.onSurfaceVariant)))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  itemCount: tailors.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final t   = tailors[i];
                    final sel = selected?.id == t.id;
                    return GestureDetector(
                      onTap: () => onSelect(t),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: sel
                              ? AppColors.primaryFixed
                              : AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: sel
                                ? AppColors.primary
                                : AppColors.outlineVariant,
                            width: sel ? 1.5 : 0.5,
                          ),
                        ),
                        child: Row(children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: AppColors.surfaceContainerLow,
                            backgroundImage: t.photoUrl != null
                                ? CachedNetworkImageProvider(t.photoUrl!)
                                : null,
                            child: t.photoUrl == null
                                ? const Icon(Icons.person_rounded,
                                    color: AppColors.onSurfaceVariant)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t.shopName.isNotEmpty ? t.shopName : t.name,
                                    style: AppTheme.titleSmall
                                        .copyWith(fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                if (t.location.isNotEmpty)
                                  Text(t.location,
                                      style: AppTheme.bodySmall.copyWith(
                                          color: AppColors.onSurfaceVariant),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                Row(children: [
                                  const Icon(Icons.star_rounded,
                                      size: 12, color: AppColors.secondary),
                                  const SizedBox(width: 2),
                                  Text(t.rating.toStringAsFixed(1),
                                      style: AppTheme.labelSmall
                                          .copyWith(color: AppColors.secondary)),
                                  const SizedBox(width: 6),
                                  Text('(${t.totalReviews})',
                                      style: AppTheme.labelSmall.copyWith(
                                          color: AppColors.onSurfaceVariant)),
                                ]),
                              ],
                            ),
                          ),
                          if (!t.isAvailable)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text('Busy',
                                  style: AppTheme.labelSmall
                                      .copyWith(color: AppColors.warning, fontSize: 10)),
                            )
                          else if (sel)
                            const Icon(Icons.check_circle_rounded,
                                color: AppColors.primary, size: 22),
                        ]),
                      ),
                    );
                  },
                ),
        ),
      ),
    ]);
  }
}

// ── Step 2: Budget + special instructions ─────────────────────────────────────

class _StepDetails extends StatelessWidget {
  final TextEditingController budgetCtrl;
  final TextEditingController instructionsCtrl;
  final String garmentType;
  final _TailorItem? tailor;

  const _StepDetails({
    required this.budgetCtrl,
    required this.instructionsCtrl,
    required this.garmentType,
    required this.tailor,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Order Details',
            style: AppTheme.titleMedium.copyWith(fontFamily: 'PlusJakartaSans')),
        const SizedBox(height: 4),
        Text('Confirm your order and add any special instructions.',
            style: AppTheme.bodySmall.copyWith(color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 20),

        // Summary card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryFixed.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _summaryRow(Icons.checkroom_rounded, 'Garment', garmentType),
            if (tailor != null) ...[
              const SizedBox(height: 8),
              _summaryRow(Icons.store_rounded, 'Tailor',
                  tailor!.shopName.isNotEmpty ? tailor!.shopName : tailor!.name),
            ],
          ]),
        ),
        const SizedBox(height: 20),

        Text('Your Budget (CFA)', style: AppTheme.labelMedium),
        const SizedBox(height: 6),
        TextField(
          controller: budgetCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: 'e.g. 25000',
            prefixText: 'CFA ',
            filled: true,
            fillColor: AppColors.surfaceContainerLow,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        const SizedBox(height: 16),

        Text('Special Instructions (optional)', style: AppTheme.labelMedium),
        const SizedBox(height: 6),
        TextField(
          controller: instructionsCtrl,
          maxLines: 4,
          minLines: 3,
          textInputAction: TextInputAction.newline,
          decoration: InputDecoration(
            hintText: 'Fabric preferences, color, design details, etc.',
            filled: true,
            fillColor: AppColors.surfaceContainerLow,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.info_outline_rounded,
                size: 16, color: AppColors.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Your order will be sent to the tailor. '
                'The tailor will confirm and may adjust the final price based on your requirements.',
                style: AppTheme.bodySmall
                    .copyWith(color: AppColors.onSurfaceVariant),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _summaryRow(IconData icon, String label, String value) => Row(
    children: [
      Icon(icon, size: 16, color: AppColors.primary),
      const SizedBox(width: 8),
      Text('$label: ',
          style: AppTheme.bodySmall
              .copyWith(color: AppColors.onSurfaceVariant)),
      Expanded(
        child: Text(value,
            style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ),
    ],
  );
}
