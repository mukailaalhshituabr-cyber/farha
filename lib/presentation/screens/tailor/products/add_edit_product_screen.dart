// lib/presentation/screens/tailor/products/add_edit_product_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/product_model.dart';
import '../../../../data/services/image_service.dart';
import '../../../../data/services/permission_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../widgets/common/farha_snackbar.dart';

// Available sizes the tailor can select
const _kSizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL', 'XXXL'];

// Fixed categories — must match farha_database.sql seeds
const _kCategories = [
  {'id': 'cat00000-0000-0000-0000-000000000001', 'name': 'Boubou'},
  {'id': 'cat00000-0000-0000-0000-000000000002', 'name': 'Kaftan'},
  {'id': 'cat00000-0000-0000-0000-000000000003', 'name': 'Agbada'},
  {'id': 'cat00000-0000-0000-0000-000000000004', 'name': 'Dress / Robe'},
  {'id': 'cat00000-0000-0000-0000-000000000005', 'name': 'Suit / Costume'},
  {'id': 'cat00000-0000-0000-0000-000000000006', 'name': "Children's Wear"},
  {'id': 'cat00000-0000-0000-0000-000000000007', 'name': 'Wedding Attire'},
  {'id': 'cat00000-0000-0000-0000-000000000008', 'name': 'Accessories'},
];

class AddEditProductScreen extends ConsumerStatefulWidget {
  /// Pass an existing [ProductModel] to edit; null to create new.
  final ProductModel? product;

  const AddEditProductScreen({super.key, this.product});

  @override
  ConsumerState<AddEditProductScreen> createState() =>
      _AddEditProductScreenState();
}

class _AddEditProductScreenState
    extends ConsumerState<AddEditProductScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _nameCtrl   = TextEditingController();
  final _descCtrl   = TextEditingController();
  final _priceCtrl  = TextEditingController();
  final _stockCtrl  = TextEditingController();

  Set<String> _selectedSizes    = {};
  String?     _selectedCategoryId;
  bool _allowsCustom = false;
  bool _isAvailable  = true;
  bool _isDraft      = false;
  bool _saving       = false;

  // Existing image URLs (from server) + newly picked local files
  List<String> _existingImages = [];
  final List<File> _newImages = <File>[];

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    if (p != null) {
      _nameCtrl.text         = p.name;
      _descCtrl.text         = p.description ?? '';
      _priceCtrl.text        = p.basePrice.toString();
      _stockCtrl.text        = p.stockQuantity.toString();
      _selectedSizes         = Set<String>.from(p.availableSizes);
      _selectedCategoryId    = p.categoryId.isNotEmpty ? p.categoryId : null;
      _allowsCustom          = p.allowsCustom;
      _isAvailable           = p.isAvailable;
      _isDraft               = p.isDraft;
      _existingImages        = p.images.map((i) => i.imageUrl).toList();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  // ── Image picking ──────────────────────────────────────────────────────────

  Future<void> _pickImages() async {
    final source = await _showImageSourceSheet();
    if (source == null || !mounted) return;

    if (source == ImageSource.camera) {
      final granted = await PermissionService.request(
        context, AppPermission.camera,
      );
      if (!granted || !mounted) return;
    }
    // Gallery: Android 13+ uses system photo picker — no permission needed.

    final svc = ImageService(ref.read(apiClientProvider));
    List<File> picked = [];
    if (source == ImageSource.camera) {
      final f = await svc.pickFromCamera();
      if (f != null) picked = [f];
    } else {
      picked = await svc.pickMultiple(
          max: 5 - _existingImages.length - _newImages.length);
    }

    if (!mounted) return;
    setState(() => _newImages.addAll(picked));
  }

  Future<ImageSource?> _showImageSourceSheet() =>
      showModalBottomSheet<ImageSource>(
        context: context,
        shape: const RoundedRectangleBorder(
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(20))),
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
              Text('Add Photo',
                  style: AppTheme.titleMedium
                      .copyWith(fontFamily: 'PlusJakartaSans')),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined,
                    color: AppColors.primary),
                title: const Text('Take Photo'),
                onTap: () =>
                    Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: AppColors.primary),
                title: const Text('Choose from Gallery'),
                onTap: () =>
                    Navigator.pop(context, ImageSource.gallery),
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

  // ── Save ───────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final price = double.tryParse(_priceCtrl.text.trim());
    if (price == null || price <= 0) {
      FarhaSnackbar.error(context, 'Please enter a valid price.');
      return;
    }

    setState(() => _saving = true);

    final repo = ref.read(productRepositoryProvider);

    // Upload any new images using the dedicated product image endpoint
    final uploadedUrls = <String>[];
    String? uploadError;
    if (_newImages.isNotEmpty) {
      final svc = ImageService(ref.read(apiClientProvider));
      for (final file in _newImages) {
        final url = await svc.uploadProductImage(
          file,
          onError: (msg) => uploadError ??= msg,
        );
        if (url != null) uploadedUrls.add(url);
      }
    }

    if (!mounted) return;

    // All photos failed and there are no existing images — report the error and stop
    if (_newImages.isNotEmpty && uploadedUrls.isEmpty && _existingImages.isEmpty) {
      setState(() => _saving = false);
      FarhaSnackbar.error(
        context,
        uploadError ?? 'Photos could not be uploaded. Please check your connection and try again.',
      );
      return;
    }
    // Some (not all) photos failed — warn but continue saving with the ones that succeeded
    if (uploadError != null) {
      FarhaSnackbar.error(context, 'Some photos failed to upload: $uploadError');
    }

    final allImages = [..._existingImages, ...uploadedUrls];

    final data = <String, dynamic>{
      'name':            _nameCtrl.text.trim(),
      'description':     _descCtrl.text.trim(),
      'base_price':      price,
      'stock_quantity':  int.tryParse(_stockCtrl.text.trim()) ?? 0,
      'allows_custom':   _allowsCustom,
      'is_available':    _isAvailable,
      'is_draft':        _isDraft,
      'available_sizes': _selectedSizes.toList(),
      'images':          allImages,
      if (_selectedCategoryId != null) 'category_id': _selectedCategoryId,
    };

    final res = _isEdit
        ? await repo.updateProduct(widget.product!.id, data)
        : await repo.createProduct(data);

    setState(() => _saving = false);
    if (!mounted) return;

    if (res.success) {
      FarhaSnackbar.success(
          context, _isEdit ? 'Product updated.' : 'Product created.');
      context.pop();
    } else {
      FarhaSnackbar.error(
          context,
          res.message.isNotEmpty
              ? res.message
              : (_isEdit ? 'Could not update product.' : 'Could not create product.'));
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

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
          onPressed: () => context.pop(),
        ),
        title: Text(
          _isEdit ? 'Edit Product' : 'New Product',
          style: AppTheme.titleLarge
              .copyWith(fontFamily: 'PlusJakartaSans'),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary))
                : Text(l.save,
                    style: AppTheme.labelLarge
                        .copyWith(color: AppColors.primary)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Photos ──────────────────────────────────────────────
            _SectionLabel('Photos'),
            _ImageGrid(
              existingUrls: _existingImages,
              newFiles:     _newImages,
              onAdd:        _pickImages,
              onRemoveExisting: (url) =>
                  setState(() => _existingImages.remove(url)),
              onRemoveNew: (file) =>
                  setState(() => _newImages.remove(file)),
              maxCount: 5,
            ),

            const SizedBox(height: 20),

            // ── Category ─────────────────────────────────────────────
            _SectionLabel('Category'),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategoryId,
              hint: Text('Select a category',
                  style: AppTheme.bodyMedium
                      .copyWith(color: AppColors.onSurfaceVariant)),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: AppColors.primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
              items: _kCategories
                  .map((c) => DropdownMenuItem<String>(
                        value: c['id'],
                        child: Text(c['name']!,
                            style: AppTheme.bodyMedium),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCategoryId = v),
            ),

            const SizedBox(height: 16),

            // ── Name ────────────────────────────────────────────────
            _SectionLabel('Product Name *'),
            _FormField(
              controller: _nameCtrl,
              hint: 'e.g. Premium Kaftan',
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l.fieldRequired : null,
            ),

            const SizedBox(height: 16),

            // ── Description ─────────────────────────────────────────
            _SectionLabel('Description'),
            _FormField(
              controller: _descCtrl,
              hint: 'Describe your product…',
              maxLines: 4,
            ),

            const SizedBox(height: 16),

            // ── Price + Stock ────────────────────────────────────────
            Row(children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel('Base Price (CFA) *'),
                  _FormField(
                    controller: _priceCtrl,
                    hint: '5000',
                    keyboardType: const TextInputType
                        .numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return l.fieldRequired;
                      }
                      if (double.tryParse(v.trim()) == null) {
                        return 'Invalid price';
                      }
                      return null;
                    },
                  ),
                ],
              )),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel('Stock Qty'),
                  _FormField(
                    controller: _stockCtrl,
                    hint: '0',
                    keyboardType: TextInputType.number,
                  ),
                ],
              )),
            ]),

            const SizedBox(height: 20),

            // ── Sizes ───────────────────────────────────────────────
            _SectionLabel('Available Sizes'),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _kSizes.map((s) {
                final sel = _selectedSizes.contains(s);
                return FilterChip(
                  label: Text(s,
                      style: AppTheme.labelMedium.copyWith(
                          color: sel ? AppColors.primary
                              : AppColors.onSurfaceVariant)),
                  selected: sel,
                  onSelected: (_) => setState(() {
                    if (sel) {
                      _selectedSizes.remove(s);
                    } else {
                      _selectedSizes.add(s);
                    }
                  }),
                  backgroundColor: AppColors.surfaceContainerLow,
                  selectedColor: AppColors.primaryFixed,
                  showCheckmark: false,
                  side: BorderSide(
                      color: sel
                          ? AppColors.primary
                          : AppColors.outlineVariant),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100)),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // ── Toggles ─────────────────────────────────────────────
            _ToggleTile(
              title: 'Allow Custom Orders',
              subtitle: 'Customers can request custom measurements',
              value: _allowsCustom,
              onChanged: (v) => setState(() => _allowsCustom = v),
            ),
            _ToggleTile(
              title: 'Available',
              subtitle: 'Show this product in your shop',
              value: _isAvailable,
              onChanged: (v) => setState(() => _isAvailable = v),
            ),
            _ToggleTile(
              title: 'Draft',
              subtitle: 'Save as draft — not visible to customers',
              value: _isDraft,
              onChanged: (v) => setState(() => _isDraft = v),
            ),

            const SizedBox(height: 32),

            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white))
                  : Text(
                      _isEdit ? 'Save Changes' : 'Create Product',
                      style: AppTheme.labelLarge),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── Image grid ────────────────────────────────────────────────────────────────

class _ImageGrid extends StatelessWidget {
  final List<String>   existingUrls;
  final List<File>     newFiles;
  final VoidCallback   onAdd;
  final void Function(String) onRemoveExisting;
  final void Function(File)   onRemoveNew;
  final int maxCount;

  const _ImageGrid({
    required this.existingUrls,
    required this.newFiles,
    required this.onAdd,
    required this.onRemoveExisting,
    required this.onRemoveNew,
    required this.maxCount,
  });

  void _openGallery(BuildContext context, int initialIndex) {
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _ImageGalleryViewer(
        existingUrls:      existingUrls,
        newFiles:          newFiles,
        initialIndex:      initialIndex,
        onDeleteExisting:  onRemoveExisting,
        onDeleteNew:       onRemoveNew,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final total = existingUrls.length + newFiles.length;
    final canAdd = total < maxCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(spacing: 8, runSpacing: 8, children: [
          // Existing server images
          for (int i = 0; i < existingUrls.length; i++)
            _ImageTile(
              child: CachedNetworkImage(
                  imageUrl: existingUrls[i], fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => const Icon(
                      Icons.broken_image_outlined,
                      color: AppColors.outline)),
              onRemove: () => onRemoveExisting(existingUrls[i]),
              onTap:    () => _openGallery(context, i),
            ),

          // Newly picked local files
          for (int i = 0; i < newFiles.length; i++)
            _ImageTile(
              child:    Image.file(newFiles[i], fit: BoxFit.cover),
              onRemove: () => onRemoveNew(newFiles[i]),
              onTap:    () => _openGallery(context, existingUrls.length + i),
            ),

          // Add button
          if (canAdd)
            GestureDetector(
              onTap: onAdd,
              child: Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.outlineVariant, width: 1),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined,
                        color: AppColors.primary, size: 26),
                    SizedBox(height: 4),
                    Text('Add',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.primary)),
                  ],
                ),
              ),
            ),
        ]),

        if (total > 0) ...[
          const SizedBox(height: 6),
          Text('Tap any photo to view full-screen or delete it.',
              style: TextStyle(
                  fontSize: 11,
                  color: AppColors.onSurfaceVariant)),
        ],
      ],
    );
  }
}

class _ImageTile extends StatelessWidget {
  final Widget child;
  final VoidCallback onRemove;
  final VoidCallback onTap;
  const _ImageTile({required this.child, required this.onRemove,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(width: 80, height: 80, child: child),
        ),
        Positioned(
          top: 2, right: 2,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 22, height: 22,
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded,
                  color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    ),
  );
}

// ── Full-screen image gallery ─────────────────────────────────────────────────

class _ImageGalleryViewer extends StatefulWidget {
  final List<String> existingUrls;
  final List<File>   newFiles;
  final int          initialIndex;
  final void Function(String) onDeleteExisting;
  final void Function(File)   onDeleteNew;

  const _ImageGalleryViewer({
    required this.existingUrls,
    required this.newFiles,
    required this.initialIndex,
    required this.onDeleteExisting,
    required this.onDeleteNew,
  });

  @override
  State<_ImageGalleryViewer> createState() => _ImageGalleryViewerState();
}

class _ImageGalleryViewerState extends State<_ImageGalleryViewer> {
  late PageController _pageCtrl;
  late int _currentIndex;

  // Combined list: existing URLs first, then new File objects
  late List<dynamic> _items; // String | File

  @override
  void initState() {
    super.initState();
    _items        = [...widget.existingUrls, ...widget.newFiles];
    _currentIndex = widget.initialIndex.clamp(0, _items.length - 1);
    _pageCtrl     = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _deleteCurrent() {
    final item = _items[_currentIndex];
    if (item is String) {
      widget.onDeleteExisting(item);
    } else if (item is File) {
      widget.onDeleteNew(item);
    }

    setState(() {
      _items.removeAt(_currentIndex);
      if (_items.isEmpty) {
        Navigator.of(context).pop();
        return;
      }
      _currentIndex = _currentIndex.clamp(0, _items.length - 1);
    });

    // Jump to correct page without animation after rebuild
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageCtrl.hasClients) {
        _pageCtrl.jumpToPage(_currentIndex);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          '${_currentIndex + 1} / ${_items.length}',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: Colors.redAccent),
            tooltip: 'Delete this photo',
            onPressed: _deleteCurrent,
          ),
        ],
      ),
      body: PageView.builder(
        controller:   _pageCtrl,
        itemCount:    _items.length,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        itemBuilder: (_, i) {
          final item = _items[i];
          return InteractiveViewer(
            minScale: 0.8,
            maxScale: 4.0,
            child: Center(
              child: item is String
                  ? CachedNetworkImage(
                      imageUrl: item,
                      fit: BoxFit.contain,
                      placeholder: (_, __) => const Center(
                          child: CircularProgressIndicator(
                              color: Colors.white)),
                      errorWidget: (_, __, ___) => const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image_outlined,
                              color: Colors.white54, size: 60),
                          SizedBox(height: 8),
                          Text('Could not load image',
                              style: TextStyle(color: Colors.white54)),
                        ],
                      ),
                    )
                  : Image.file(item as File, fit: BoxFit.contain),
            ),
          );
        },
      ),
      // Dot indicator at bottom
      bottomNavigationBar: _items.length > 1
          ? Container(
              height: 40,
              color: Colors.black,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_items.length, (i) => Container(
                  width:  _currentIndex == i ? 10 : 6,
                  height: _currentIndex == i ? 10 : 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentIndex == i
                        ? Colors.white
                        : Colors.white38,
                  ),
                )),
              ),
            )
          : null,
    );
  }
}

// ── Toggle tile ───────────────────────────────────────────────────────────────

class _ToggleTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool   value;
  final void Function(bool) onChanged;

  const _ToggleTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
          color: AppColors.outlineVariant, width: 0.5),
    ),
    child: SwitchListTile.adaptive(
      title: Text(title,
          style: AppTheme.titleSmall
              .copyWith(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle,
          style: AppTheme.bodySmall
              .copyWith(color: AppColors.onSurfaceVariant)),
      value: value,
      onChanged: onChanged,
      activeTrackColor: AppColors.primary,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14)),
    ),
  );
}

// ── Shared form widgets ───────────────────────────────────────────────────────

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

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int    maxLines;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _FormField({
    required this.controller,
    required this.hint,
    this.maxLines    = 1,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller:   controller,
    maxLines:     maxLines,
    minLines:     1,
    keyboardType: keyboardType,
    validator:    validator,
    decoration: InputDecoration(
      hintText:  hint,
      hintStyle: AppTheme.bodyMedium
          .copyWith(color: AppColors.onSurfaceVariant),
      filled:      true,
      fillColor:   AppColors.surfaceContainerLow,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:   BorderSide.none,
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
            color: AppColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 14),
    ),
  );
}
