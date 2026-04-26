// lib/presentation/screens/customer/tailor/tailor_public_profile_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/product_model.dart';
import '../../../../data/models/review_model.dart';
import '../../../../data/models/tailor_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../widgets/common/farha_snackbar.dart';
import '../../../providers/cart_provider.dart';
import '../../../../routes/app_router.dart';

// ── Providers ──────────────────────────────────────────────────────────────────

final _tailorProfileProvider = FutureProvider.autoDispose
    .family<TailorModel?, String>((ref, id) =>
        ref.watch(tailorRepositoryProvider).getTailorProfile(id));

final _tailorProductsProvider = FutureProvider.autoDispose
    .family<List<ProductModel>, String>((ref, tailorId) async {
  final result = await ref
      .watch(productRepositoryProvider)
      .getProducts(tailorId: tailorId, limit: 20);
  return result.items;
});

final _tailorReviewsProvider = FutureProvider.autoDispose
    .family<List<ReviewModel>, String>((ref, tailorId) async {
  final result = await ref
      .watch(tailorRepositoryProvider)
      .getReviews(tailorId);
  return result.items;
});

// ── Screen ─────────────────────────────────────────────────────────────────────

class TailorPublicProfileScreen extends ConsumerStatefulWidget {
  final String tailorId;
  const TailorPublicProfileScreen({super.key, required this.tailorId});

  @override
  ConsumerState<TailorPublicProfileScreen> createState() => _State();
}

class _State extends ConsumerState<TailorPublicProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(_tailorProfileProvider(widget.tailorId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: profileAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, __) => _ErrorBody(
          onRetry: () =>
              ref.invalidate(_tailorProfileProvider(widget.tailorId)),
        ),
        data: (tailor) => tailor == null
            ? _ErrorBody(
                onRetry: () =>
                    ref.invalidate(_tailorProfileProvider(widget.tailorId)))
            : _ProfileBody(tailor: tailor, tabs: _tabs, tailorId: widget.tailorId),
      ),
    );
  }
}

// ── Main profile body ──────────────────────────────────────────────────────────

class _ProfileBody extends ConsumerWidget {
  final TailorModel    tailor;
  final TabController  tabs;
  final String         tailorId;

  const _ProfileBody({
    required this.tailor,
    required this.tabs,
    required this.tailorId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NestedScrollView(
      headerSliverBuilder: (context, _) => [
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.onBackground, size: 20),
            onPressed: () => context.pop(),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: _HeaderBanner(tailor: tailor),
          ),
        ),
        SliverToBoxAdapter(child: _TailorInfo(tailor: tailor)),
        SliverPersistentHeader(
          pinned: true,
          delegate: _TabBarDelegate(
            TabBar(
              controller: tabs,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.onSurfaceVariant,
              indicatorColor: AppColors.primary,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: AppTheme.labelMedium
                  .copyWith(fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'Products'),
                Tab(text: 'Reviews'),
              ],
            ),
          ),
        ),
      ],
      body: TabBarView(
        controller: tabs,
        children: [
          _ProductsTab(tailorId: tailorId),
          _ReviewsTab(tailorId: tailorId),
        ],
      ),
    );
  }
}

// ── Header banner ──────────────────────────────────────────────────────────────

class _HeaderBanner extends StatelessWidget {
  final TailorModel tailor;
  const _HeaderBanner({required this.tailor});

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Container(color: AppColors.primaryFixed),
      Positioned(
        bottom: 0, left: 0, right: 0,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                AppColors.background.withValues(alpha: 0.95),
              ],
            ),
          ),
          child: Row(children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.onPrimary, width: 2),
              ),
              child: CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.primary,
                backgroundImage: tailor.profilePhoto != null
                    ? CachedNetworkImageProvider(tailor.profilePhoto!)
                    : null,
                child: tailor.profilePhoto == null
                    ? Text(
                        AppFormatters.initials(tailor.fullName),
                        style: AppTheme.titleMedium
                            .copyWith(color: AppColors.onPrimary),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Flexible(
                      child: Text(tailor.shopName,
                          style: AppTheme.titleLarge
                              .copyWith(fontFamily: 'PlusJakartaSans'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (tailor.isVerified) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.verified_rounded,
                          color: AppColors.primary, size: 18),
                    ],
                  ]),
                  Text(tailor.fullName,
                      style: AppTheme.bodySmall.copyWith(
                          color: AppColors.onSurfaceVariant)),
                ],
              ),
            ),
          ]),
        ),
      ),
    ],
  );
}

// ── Tailor info section ────────────────────────────────────────────────────────

class _TailorInfo extends ConsumerStatefulWidget {
  final TailorModel tailor;
  const _TailorInfo({required this.tailor});

  @override
  ConsumerState<_TailorInfo> createState() => _TailorInfoState();
}

class _TailorInfoState extends ConsumerState<_TailorInfo> {
  bool _openingChat = false;

  Future<void> _openChat() async {
    setState(() => _openingChat = true);
    final api = ref.read(apiClientProvider);
    final res = await api.post(
      ApiConstants.conversations,
      data: {'tailor_id': widget.tailor.id},
    );
    if (!mounted) return;
    setState(() => _openingChat = false);
    if (res.success) {
      final convId =
          (res.data as Map<String, dynamic>?)?['conversation_id'] as String? ??
              '';
      if (convId.isNotEmpty) {
        context.push(Routes.chatScreen.replaceFirst(':id', convId));
        return;
      }
    }
    FarhaSnackbar.error(context, 'Could not open chat. Try again.');
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tailor;
    return Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Stats row
      Row(children: [
        _Stat(t.rating.toStringAsFixed(1),
            Icons.star_rounded, AppColors.secondary),
        const SizedBox(width: 4),
        Text('(${t.totalReviews})',
            style: AppTheme.bodySmall.copyWith(
                color: AppColors.onSurfaceVariant)),
        const SizedBox(width: 16),
        _Stat('${t.totalOrders}',
            Icons.receipt_long_rounded, AppColors.info),
        const SizedBox(width: 4),
        Text('orders',
            style: AppTheme.bodySmall.copyWith(
                color: AppColors.onSurfaceVariant)),
        const SizedBox(width: 16),
        _Stat('${t.yearsExperience}y',
            Icons.workspace_premium_rounded, AppColors.primary),
        const SizedBox(width: 4),
        Text('experience',
            style: AppTheme.bodySmall.copyWith(
                color: AppColors.onSurfaceVariant)),
      ]),

      const SizedBox(height: 12),

      // Availability
      Row(children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: t.isAvailable ? AppColors.success : AppColors.outline,
          ),
        ),
        const SizedBox(width: 6),
        Text(t.isAvailable ? 'Available for orders' : 'Not taking orders',
            style: AppTheme.bodySmall.copyWith(
              color: t.isAvailable
                  ? AppColors.success : AppColors.onSurfaceVariant,
            )),
      ]),

      // Bio
      if (t.bio != null && t.bio!.isNotEmpty) ...[
        const SizedBox(height: 12),
        Text(t.bio!,
            style: AppTheme.bodyMedium.copyWith(color: AppColors.onSurface)),
      ],

      // Location
      if (t.shopLocation != null && t.shopLocation!.isNotEmpty) ...[
        const SizedBox(height: 12),
        _LocationRow(tailor: t),
      ],

      const SizedBox(height: 12),

      // ── Message in app button ──────────────────────────────
      FilledButton.icon(
        onPressed: _openingChat ? null : _openChat,
        icon: _openingChat
            ? const SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.chat_bubble_outline_rounded, size: 16),
        label: Text(_openingChat ? 'Opening...' : 'Message in App'),
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 44),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100)),
        ),
      ),

      // Contact row (Call / Email)
      if (t.phone != null || t.email != null) ...[
        const SizedBox(height: 8),
        Row(children: [
          if (t.phone != null)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _call(context, t.phone!),
                icon: const Icon(Icons.call_outlined, size: 16),
                label: const Text('Call'),
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 42),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100))),
              ),
            ),
          if (t.phone != null && t.email != null)
            const SizedBox(width: 10),
          if (t.email != null)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _email(context, t.email!),
                icon: const Icon(Icons.mail_outline_rounded, size: 16),
                label: const Text('Email'),
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 42),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100))),
              ),
            ),
        ]),
      ],

      const SizedBox(height: 8),
    ]),
  );
  }

  Future<void> _call(BuildContext context, String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      FarhaSnackbar.error(context, 'Cannot open dialer.');
    }
  }

  Future<void> _email(BuildContext context, String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      FarhaSnackbar.error(context, 'Cannot open email app.');
    }
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final IconData icon;
  final Color color;
  const _Stat(this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 14, color: color),
    const SizedBox(width: 4),
    Text(value, style: AppTheme.labelMedium.copyWith(color: color)),
  ]);
}

class _LocationRow extends StatelessWidget {
  final TailorModel tailor;
  const _LocationRow({required this.tailor});

  Future<void> _openMap(BuildContext context) async {
    final Uri uri;
    if (tailor.latitude != null && tailor.longitude != null) {
      uri = Uri.parse('https://www.google.com/maps/search/?api=1'
          '&query=${tailor.latitude},${tailor.longitude}');
    } else {
      uri = Uri.parse('https://www.google.com/maps/search/?api=1'
          '&query=${Uri.encodeComponent(tailor.shopLocation!)}');
    }
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      FarhaSnackbar.error(context, 'Could not open maps.');
    }
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => _openMap(context),
    child: Row(children: [
      const Icon(Icons.location_on_outlined,
          size: 16, color: AppColors.primary),
      const SizedBox(width: 4),
      Expanded(
        child: Text(tailor.shopLocation!,
            style: AppTheme.bodySmall.copyWith(
                color: AppColors.primary,
                decoration: TextDecoration.underline),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ),
    ]),
  );
}

// ── Products tab ───────────────────────────────────────────────────────────────

class _ProductsTab extends ConsumerWidget {
  final String tailorId;
  const _ProductsTab({required this.tailorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(_tailorProductsProvider(tailorId));

    return productsAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary)),
      error: (_, __) => const Center(child: Text('Could not load products.')),
      data: (items) => items.isEmpty
          ? const Center(
              child: Text('No products listed yet.',
                  style: TextStyle(color: AppColors.onSurfaceVariant)))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.72,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: items.length,
              itemBuilder: (_, i) => _ProductCard(product: items[i]),
            ),
    );
  }
}

class _ProductCard extends ConsumerWidget {
  final ProductModel product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inWishlist = ref.watch(wishlistProvider).isFavorite(product.id);

    return GestureDetector(
      onTap: () => context.push('/customer/product/${product.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: AppColors.outlineVariant, width: 0.5),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Stack(children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(15)),
                child: product.displayImage != null
                    ? CachedNetworkImage(
                        imageUrl: product.displayImage!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorWidget: (_, __, ___) => _ImgPlaceholder(),
                      )
                    : _ImgPlaceholder(),
              ),
              Positioned(
                top: 6, right: 6,
                child: GestureDetector(
                  onTap: () => ref
                      .read(wishlistProvider.notifier)
                      .toggle(product.id),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      inWishlist
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 16,
                      color: inWishlist
                          ? AppColors.error : AppColors.outline,
                    ),
                  ),
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(product.name,
                  style: AppTheme.labelMedium
                      .copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(
                AppFormatters.currency(product.basePrice,
                    symbol: product.currency),
                style: AppTheme.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _ImgPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.surfaceContainerLow,
    child: const Center(child: Icon(Icons.image_outlined,
        color: AppColors.outline, size: 36)),
  );
}

// ── Reviews tab ────────────────────────────────────────────────────────────────

class _ReviewsTab extends ConsumerWidget {
  final String tailorId;
  const _ReviewsTab({required this.tailorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(_tailorReviewsProvider(tailorId));

    return reviewsAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary)),
      error: (_, __) => const Center(child: Text('Could not load reviews.')),
      data: (items) => items.isEmpty
          ? const Center(
              child: Text('No reviews yet.',
                  style: TextStyle(color: AppColors.onSurfaceVariant)))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _ReviewCard(review: items[i]),
            ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ReviewModel review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.outlineVariant, width: 0.5),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.primaryFixed,
          backgroundImage: review.customerPhoto != null
              ? CachedNetworkImageProvider(review.customerPhoto!) : null,
          child: review.customerPhoto == null
              ? Text(AppFormatters.initials(review.customerName),
                  style: AppTheme.labelSmall
                      .copyWith(color: AppColors.primary))
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(review.customerName, style: AppTheme.labelMedium),
            Text(AppFormatters.date(review.createdAt),
                style: AppTheme.bodySmall.copyWith(
                    color: AppColors.onSurfaceVariant)),
          ]),
        ),
        Row(
          children: List.generate(5, (i) => Icon(
            i < review.rating
                ? Icons.star_rounded
                : Icons.star_border_rounded,
            size: 14,
            color: AppColors.secondary,
          )),
        ),
      ]),
      if (review.comment != null && review.comment!.isNotEmpty) ...[
        const SizedBox(height: 10),
        Text(review.comment!,
            style: AppTheme.bodyMedium
                .copyWith(color: AppColors.onSurface)),
      ],
    ]),
  );
}

// ── Tab bar persistent header ──────────────────────────────────────────────────

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  const _TabBarDelegate(this._tabBar);

  @override
  Widget build(_, __, ___) => Container(
    color: AppColors.background,
    child: _tabBar,
  );

  @override double get maxExtent => _tabBar.preferredSize.height;
  @override double get minExtent => _tabBar.preferredSize.height;
  @override bool shouldRebuild(_) => false;
}

// ── Error body ─────────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorBody({required this.onRetry});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(backgroundColor: AppColors.background, elevation: 0),
    backgroundColor: AppColors.background,
    body: Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline_rounded,
            color: AppColors.outline, size: 48),
        const SizedBox(height: 12),
        Text('Could not load profile.',
            style: AppTheme.bodyMedium
                .copyWith(color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Retry'),
        ),
      ]),
    ),
  );
}
