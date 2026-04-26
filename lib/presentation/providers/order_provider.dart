// lib/presentation/providers/order_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/models/order_model.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/review_repository.dart';
import '../../data/repositories/payment_repository.dart';
import '../../data/repositories/measurement_repository.dart';
import 'auth_provider.dart';

// ── Repository providers ──────────────────────────────────────────────────
final orderRepositoryProvider = Provider<OrderRepository>(
    (ref) => OrderRepository(ref.watch(apiClientProvider)));

final chatRepositoryProvider = Provider<ChatRepository>(
    (ref) => ChatRepository(ref.watch(apiClientProvider)));

final reviewRepositoryProvider = Provider<ReviewRepository>(
    (ref) => ReviewRepository(ref.watch(apiClientProvider)));

final paymentRepositoryProvider = Provider<PaymentRepository>(
    (ref) => PaymentRepository(ref.watch(apiClientProvider)));

final measurementRepositoryProvider = Provider<MeasurementRepository>(
    (ref) => MeasurementRepository(ref.watch(apiClientProvider)));

// ── Order list ────────────────────────────────────────────────────────────
class OrderListState {
  final List<OrderModel> items;
  final bool    isLoading;
  final bool    isLoadingMore;
  final bool    hasMore;
  final String? error;
  final String? statusFilter;
  final int     page;

  const OrderListState({
    this.items         = const [],
    this.isLoading     = false,
    this.isLoadingMore = false,
    this.hasMore       = true,
    this.error,
    this.statusFilter,
    this.page          = 1,
  });

  OrderListState copyWith({
    List<OrderModel>? items, bool? isLoading, bool? isLoadingMore,
    bool? hasMore, String? error, String? statusFilter, int? page,
  }) => OrderListState(
    items:         items         ?? this.items,
    isLoading:     isLoading     ?? this.isLoading,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    hasMore:       hasMore       ?? this.hasMore,
    error:         error,
    statusFilter:  statusFilter  ?? this.statusFilter,
    page:          page          ?? this.page,
  );
}

class OrderNotifier extends StateNotifier<OrderListState> {
  final OrderRepository _repo;

  OrderNotifier(this._repo) : super(const OrderListState()) { load(); }

  Future<void> load({bool refresh = false}) async {
    if (state.isLoading && !refresh) return;
    final page = refresh ? 1 : state.page;
    state = state.copyWith(isLoading: true, page: page);

    final result = await _repo.getOrders(status: state.statusFilter, page: page);
    if (!result.success) {
      state = state.copyWith(isLoading: false, error: result.error);
      return;
    }
    state = state.copyWith(
      items:     refresh ? result.items : [...state.items, ...result.items],
      hasMore:   result.hasMore,
      isLoading: false,
      page:      page + 1,
    );
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore) return;
    state = state.copyWith(isLoadingMore: true);
    await load();
    state = state.copyWith(isLoadingMore: false);
  }

  void filterByStatus(String? status) {
    state = OrderListState(statusFilter: status);
    load();
  }

  void refresh() => load(refresh: true);

  Future<bool> updateStatus(String orderId, String newStatus) async {
    final res = await _repo.updateStatus(orderId, newStatus);
    if (res.success) refresh();
    return res.success;
  }

  Future<bool> cancelOrder(String orderId, String reason) async {
    final res = await _repo.cancelOrder(orderId, reason);
    if (res.success) refresh();
    return res.success;
  }
}

final orderProvider = StateNotifierProvider<OrderNotifier, OrderListState>((ref) {
  // Re-create whenever the logged-in user changes so a new login never
  // sees a previous user's cached orders.
  ref.watch(authProvider.select((s) => s.user?.id));
  return OrderNotifier(ref.watch(orderRepositoryProvider));
});

final orderDetailProvider = FutureProvider.family<OrderModel?, String>(
    (ref, id) => ref.watch(orderRepositoryProvider).getOrder(id));

// ── Custom order form state ───────────────────────────────────────────────
class CustomOrderFormState {
  final String?  garmentType;
  final Map<String, double> measurements;
  final String   unit;
  final String?  specialInstructions;
  final String?  designRefPath;
  final String?  selectedMeasurementProfileId;
  final String?  selectedTailorId;
  final String?  selectedTailorName;
  final String?  selectedTailorShop;

  const CustomOrderFormState({
    this.garmentType,
    this.measurements                  = const {},
    this.unit                          = 'cm',
    this.specialInstructions,
    this.designRefPath,
    this.selectedMeasurementProfileId,
    this.selectedTailorId,
    this.selectedTailorName,
    this.selectedTailorShop,
  });

  CustomOrderFormState copyWith({
    String? garmentType,
    Map<String, double>? measurements,
    String? unit, String? specialInstructions,
    String? designRefPath, String? selectedMeasurementProfileId,
    String? selectedTailorId, String? selectedTailorName,
    String? selectedTailorShop,
  }) => CustomOrderFormState(
    garmentType:                  garmentType                  ?? this.garmentType,
    measurements:                 measurements                 ?? this.measurements,
    unit:                         unit                         ?? this.unit,
    specialInstructions:          specialInstructions          ?? this.specialInstructions,
    designRefPath:                designRefPath                ?? this.designRefPath,
    selectedMeasurementProfileId: selectedMeasurementProfileId ?? this.selectedMeasurementProfileId,
    selectedTailorId:             selectedTailorId             ?? this.selectedTailorId,
    selectedTailorName:           selectedTailorName           ?? this.selectedTailorName,
    selectedTailorShop:           selectedTailorShop           ?? this.selectedTailorShop,
  );

  void clear() {}
}

final customOrderFormProvider =
    StateProvider<CustomOrderFormState>((ref) => const CustomOrderFormState());
