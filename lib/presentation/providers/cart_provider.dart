// lib/presentation/providers/cart_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/models/cart_model.dart';
import '../../data/models/wishlist_model.dart';
import '../../data/repositories/cart_repository.dart';
import '../../data/repositories/wishlist_repository.dart';
import 'auth_provider.dart';

final cartRepositoryProvider = Provider<CartRepository>(
    (ref) => CartRepository(ref.watch(apiClientProvider)));

final wishlistRepositoryProvider = Provider<WishlistRepository>(
    (ref) => WishlistRepository(ref.watch(apiClientProvider)));

class CartState {
  final List<CartItemModel> items;
  final bool    isLoading;
  final String? error;
  const CartState({this.items = const [], this.isLoading = false, this.error});
  double get total   => items.fold(0.0, (s, i) => s + i.subtotal);
  int    get count   => items.fold(0, (s, i) => s + i.quantity);
  bool   get isEmpty => items.isEmpty;

  CartState copyWith({List<CartItemModel>? items, bool? isLoading, String? error}) =>
      CartState(
        items:     items     ?? this.items,
        isLoading: isLoading ?? this.isLoading,
        error:     error,
      );
}

class CartNotifier extends StateNotifier<CartState> {
  final CartRepository _repo;
  CartNotifier(this._repo) : super(const CartState()) { fetch(); }

  Future<void> fetch() async {
    state = state.copyWith(isLoading: true);
    final r = await _repo.getCart();
    state = r.success
        ? CartState(items: r.items)
        : CartState(error: r.error);
  }

  Future<bool> addItem(String productId, int qty, String? size) async {
    final r = await _repo.addItem(productId: productId, quantity: qty, size: size);
    if (r.success) await fetch();
    return r.success;
  }

  Future<bool> removeItem(String id) async {
    // Optimistic removal
    state = state.copyWith(
        items: state.items.where((i) => i.id != id).toList());
    final r = await _repo.removeItem(id);
    if (!r.success) await fetch(); // revert on error
    return r.success;
  }

  Future<bool> updateQuantity(String id, int qty) async {
    if (qty <= 0) return removeItem(id);
    // Optimistic update
    state = state.copyWith(
      items: state.items
          .map((i) => i.id == id ? i.copyWith(quantity: qty) : i)
          .toList(),
    );
    final r = await _repo.updateItem(id, qty);
    if (!r.success) await fetch(); // revert on error
    return r.success;
  }

  void clear() => state = const CartState();
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>(
    (ref) => CartNotifier(ref.watch(cartRepositoryProvider)));

final cartCountProvider = Provider<int>((ref) => ref.watch(cartProvider).count);

// ── Wishlist ──────────────────────────────────────────────────────────────

class WishlistState {
  final Set<String>             productIds;
  final List<WishlistItemModel> items;
  final bool                    isLoading;
  const WishlistState({this.productIds = const {}, this.items = const [], this.isLoading = false});
  bool isFavorite(String id) => productIds.contains(id);
}

class WishlistNotifier extends StateNotifier<WishlistState> {
  final WishlistRepository _repo;
  WishlistNotifier(this._repo) : super(const WishlistState()) { _load(); }

  Future<void> _load() async {
    state = const WishlistState(isLoading: true);
    final r = await _repo.getWishlist();
    if (r.success) {
      state = WishlistState(
        items: r.items,
        productIds: r.items.map((i) => i.productId).toSet(),
      );
    } else {
      state = const WishlistState();
    }
  }

  Future<void> toggle(String productId) async {
    if (state.isFavorite(productId)) {
      state = WishlistState(
        productIds: {...state.productIds}..remove(productId),
        items: state.items.where((i) => i.productId != productId).toList(),
      );
      await _repo.remove(productId);
    } else {
      await _repo.add(productId);
      await _load();
    }
  }

  Future<void> refresh() => _load();
}

final wishlistProvider = StateNotifierProvider<WishlistNotifier, WishlistState>(
    (ref) => WishlistNotifier(ref.watch(wishlistRepositoryProvider)));
