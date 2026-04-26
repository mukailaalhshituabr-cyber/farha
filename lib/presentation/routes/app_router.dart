// lib/routes/app_router.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/screens/auth/splash_screen.dart';
import '../../presentation/screens/auth/onboarding_screen.dart';
import '../../presentation/screens/auth/choose_user_type_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/customer_registration_screen.dart';
import '../../presentation/screens/auth/tailor_registration_screen.dart';
import '../../presentation/screens/auth/forgot_password_screen.dart';
import '../../presentation/screens/auth/otp_verification_screen.dart';
import '../../presentation/screens/auth/reset_password_screen.dart';
import '../../presentation/screens/customer/dashboard/customer_dashboard_screen.dart';
import '../../presentation/screens/customer/notifications/notifications_screen.dart';
import '../../presentation/screens/customer/orders/order_history_screen.dart';
import '../../presentation/screens/customer/orders/order_tracking_screen.dart';
import '../../presentation/screens/customer/profile/customer_profile_screen.dart';
import '../../presentation/screens/customer/shop/product_detail_screen.dart';
import '../../presentation/screens/customer/shop/product_listing_screen.dart';
import '../../data/models/conversation_model.dart';
import '../../presentation/screens/customer/measurements/saved_measurements_screen.dart';
import '../../presentation/screens/customer/orders/custom_order_screen.dart';
import '../../presentation/screens/messages/chat_inbox_screen.dart';
import '../../presentation/screens/messages/chat_screen.dart';
import '../../presentation/screens/orders/order_detail_screen.dart';
import '../../presentation/screens/profile/edit_profile_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import '../../presentation/screens/support/help_support_screen.dart';
import '../../presentation/screens/tailor/dashboard/tailor_dashboard_screen.dart';
import '../../presentation/screens/tailor/orders/tailor_order_management_screen.dart';
import '../../presentation/screens/tailor/profile/tailor_profile_screen.dart';
import '../../data/models/product_model.dart';
import '../../presentation/screens/tailor/products/tailor_product_management_screen.dart';
import '../../presentation/screens/tailor/products/add_edit_product_screen.dart';
import '../../presentation/screens/tailor/revenue/payout_screen.dart';
import '../../presentation/screens/tailor/revenue/revenue_dashboard_screen.dart';
import '../../presentation/screens/customer/shop/cart_screen.dart';
import '../../presentation/screens/customer/shop/checkout_screen.dart';
import '../../presentation/screens/customer/shop/search_screen.dart';
import '../../presentation/screens/customer/shop/wishlist_screen.dart';
import '../../presentation/screens/customer/orders/order_success_screen.dart';
import '../../presentation/screens/customer/orders/pay_balance_screen.dart';
import '../../presentation/screens/customer/tailor/tailor_public_profile_screen.dart';
import '../../presentation/screens/admin/admin_login_screen.dart';
import '../../presentation/screens/admin/admin_dashboard_screen.dart';
import '../../presentation/screens/admin/admin_users_screen.dart';
import '../../presentation/screens/admin/admin_orders_screen.dart';
import '../../presentation/screens/admin/admin_payments_screen.dart';
import '../../presentation/screens/admin/admin_payouts_screen.dart';
import '../../presentation/screens/admin/admin_products_screen.dart';
import '../../presentation/screens/admin/admin_broadcast_screen.dart';

// ── Route paths ────────────────────────────────────────────────────────────
class Routes {
  // Auth
  static const splash                   = '/';
  static const onboarding               = '/onboarding';
  static const chooseUserType           = '/choose-type';
  static const login                    = '/login';
  static const customerRegister         = '/register/customer';
  static const tailorRegister           = '/register/tailor';
  static const forgotPassword           = '/forgot-password';
  static const otpVerification          = '/otp-verify';
  static const resetPassword            = '/reset-password';
  static const emailVerificationPending = '/verify-email-pending';

  // Customer
  static const customerDashboard        = '/customer/dashboard';
  static const productListing           = '/customer/shop';
  static const productDetail            = '/customer/product/:id';
  static const search                   = '/customer/search';
  static const cart                     = '/customer/cart';
  static const wishlist                 = '/customer/wishlist';
  static const tailorPublicProfile      = '/customer/tailor/:id';
  static const sizeGuide                = '/customer/size-guide';
  static const allReviews               = '/customer/reviews/:id';
  static const customOrderMeasurements  = '/customer/order/measurements';
  static const chooseTailor             = '/customer/order/choose-tailor';
  static const orderReview              = '/customer/order/review';
  static const payment                  = '/customer/payment';
  static const orderSuccess             = '/customer/order/success';
  static const orderHistory             = '/customer/orders';
  static const orderTracking            = '/customer/order/track/:id';
  static const orderDetail              = '/customer/order/:id';
  static const orderCancellation        = '/customer/order/cancel/:id';
  static const payBalance               = '/customer/order/pay-balance/:id';
  static const chatInbox                = '/customer/messages';
  static const chatScreen               = '/customer/chat/:id';
  static const notifications            = '/customer/notifications';
  static const customerProfile          = '/customer/profile';
  static const editCustomerProfile      = '/customer/profile/edit';
  static const customerSettings         = '/customer/settings';
  static const savedMeasurements        = '/customer/measurements';
  static const measurementDetail        = '/customer/measurement/:id';
  static const helpSupport              = '/customer/help';

  // Tailor
  static const tailorDashboard          = '/tailor/dashboard';
  static const tailorOrderManagement    = '/tailor/orders';
  static const tailorOrderDetail        = '/tailor/order/:id';
  static const tailorProductManagement  = '/tailor/products';
  static const addEditProduct           = '/tailor/product/edit';
  static const clientList               = '/tailor/clients';
  static const clientProfile            = '/tailor/client/:id';
  static const tailorChatInbox          = '/tailor/messages';
  static const tailorChatScreen         = '/tailor/chat/:id';
  static const revenueDashboard         = '/tailor/revenue';
  static const payout                   = '/tailor/payout';
  static const tailorProfile            = '/tailor/profile';
  static const editTailorProfile        = '/tailor/profile/edit';
  static const tailorSettings           = '/tailor/settings';

  // Shared
  static const styleGuide               = '/style-guide';
  static const fabricLibrary            = '/fabric-library';
  static const savedInspirations        = '/inspirations';

  // Admin
  static const adminLogin               = '/admin';
  static const adminDashboard           = '/admin/dashboard';
  static const adminUsers               = '/admin/users';
  static const adminOrders              = '/admin/orders';
  static const adminPayments            = '/admin/payments';
  static const adminPayouts             = '/admin/payouts';
  static const adminProducts            = '/admin/products';
  static const adminBroadcast           = '/admin/broadcast';
}

// ── Auth state notifier — used as GoRouter refreshListenable ───────────────
class _AuthChangeNotifier extends ChangeNotifier {
  AuthStatus _lastStatus = AuthStatus.initial;

  void update(AuthStatus newStatus) {
    if (newStatus != _lastStatus) {
      _lastStatus = newStatus;
      notifyListeners();
    }
  }

  AuthStatus get status => _lastStatus;
}

// ── Placeholder for unbuilt screens ───────────────────────────────────────
class _Placeholder extends StatelessWidget {
  final String name;
  const _Placeholder(this.name);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(name)),
    body: Center(
      child: Text('$name\n(Coming soon)',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 16)),
    ),
  );
}

// ── Router provider ────────────────────────────────────────────────────────
final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = _AuthChangeNotifier();

  ref.listen<AuthState>(authProvider, (_, next) {
    authNotifier.update(next.status);
  });

  return GoRouter(
    initialLocation: Routes.splash,
    debugLogDiagnostics: false,
    refreshListenable: authNotifier,

    redirect: (context, state) {
      final path   = state.matchedLocation;
      final status = authNotifier.status;

      // Admin routes manage their own auth — skip all redirect logic for them
      if (path.startsWith('/admin')) return null;

      if (status == AuthStatus.initial) {
        return path == Routes.splash ? null : Routes.splash;
      }

      final isAuthed = status == AuthStatus.authenticated;

      final isPublicRoute =
          path == Routes.splash                       ||
          path == Routes.onboarding                   ||
          path == Routes.chooseUserType               ||
          path == Routes.login                        ||
          path == Routes.customerRegister             ||
          path == Routes.tailorRegister               ||
          path == Routes.forgotPassword               ||
          path == Routes.emailVerificationPending     ||
          path.startsWith('/otp')                     ||
          path.startsWith('/reset');

      if (!isAuthed && !isPublicRoute) {
        return Routes.login;
      }

      if (isAuthed && isPublicRoute && path != Routes.splash) {
        final container = ProviderScope.containerOf(context, listen: false);
        final userType  = container.read(authProvider).user?.userType ?? 'customer';
        return userType == 'tailor'
            ? Routes.tailorDashboard
            : Routes.customerDashboard;
      }

      return null;
    },

    routes: [
      // ── Auth ──────────────────────────────────────────────────────
      GoRoute(path: Routes.splash,
          builder: (_, __) => const SplashScreen()),
      GoRoute(path: Routes.onboarding,
          builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: Routes.chooseUserType,
          builder: (_, __) => const ChooseUserTypeScreen()),
      GoRoute(path: Routes.login,
          builder: (_, __) => const LoginScreen()),
      GoRoute(path: Routes.customerRegister,
          builder: (_, __) => const CustomerRegistrationScreen()),
      GoRoute(path: Routes.tailorRegister,
          builder: (_, __) => const TailorRegistrationScreen()),
      GoRoute(path: Routes.forgotPassword,
          builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(
        path: Routes.otpVerification,
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return OtpVerificationScreen(
              email: extra['email'] as String? ?? '');
        },
      ),
      GoRoute(
        path: Routes.resetPassword,
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return ResetPasswordScreen(
            resetToken: extra['reset_token'] as String? ?? '',
            email:      extra['email']       as String? ?? '',
          );
        },
      ),
      GoRoute(
        path: Routes.emailVerificationPending,
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return EmailVerificationPendingScreen(
              email: extra['email'] as String? ?? '');
        },
      ),

      // ── Customer ──────────────────────────────────────────────────
      GoRoute(path: Routes.customerDashboard,
          builder: (_, __) => const CustomerDashboardScreen()),
      GoRoute(path: Routes.productListing,
          builder: (_, __) => const ProductListingScreen()),
      GoRoute(path: Routes.productDetail,
          builder: (_, s) => ProductDetailScreen(
              productId: s.pathParameters['id'] ?? '')),
      GoRoute(path: Routes.search,
          builder: (_, __) => const SearchScreen()),
      GoRoute(path: Routes.cart,
          builder: (_, __) => const CartScreen()),
      GoRoute(path: Routes.wishlist,
          builder: (_, __) => const WishlistScreen()),
      GoRoute(path: Routes.tailorPublicProfile,
          builder: (_, s) => TailorPublicProfileScreen(
              tailorId: s.pathParameters['id'] ?? '')),
      GoRoute(path: Routes.sizeGuide,
          builder: (_, __) => const _Placeholder('Size Guide')),
      GoRoute(path: Routes.allReviews,
          builder: (_, s) =>
              _Placeholder('Reviews #${s.pathParameters['id']}')),
      GoRoute(path: Routes.customOrderMeasurements,
          builder: (_, __) => const CustomOrderScreen()),
      GoRoute(path: Routes.chooseTailor,
          builder: (_, __) => const _Placeholder('Choose Tailor')),
      GoRoute(path: Routes.orderReview,
          builder: (_, __) => const _Placeholder('Order Review')),
      GoRoute(
        path: Routes.payment,
        builder: (_, s) => CheckoutScreen(
            cartItems: (s.extra as List?)?.cast() ?? const []),
      ),
      GoRoute(
        path: Routes.orderSuccess,
        builder: (_, s) => OrderSuccessScreen(
            references: (s.extra as List?)?.cast<String>() ?? const []),
      ),
      GoRoute(path: Routes.orderHistory,
          builder: (_, __) => const OrderHistoryScreen()),
      GoRoute(path: Routes.orderTracking,
          builder: (_, s) => OrderTrackingScreen(
              orderId: s.pathParameters['id'] ?? '')),
      GoRoute(path: Routes.orderDetail,
          builder: (_, s) => OrderDetailScreen(
              orderId: s.pathParameters['id'] ?? '')),
      GoRoute(path: Routes.orderCancellation,
          builder: (_, s) => OrderDetailScreen(
              orderId: s.pathParameters['id'] ?? '')),
      GoRoute(path: Routes.payBalance,
          builder: (_, s) => PayBalanceScreen(
              orderId: s.pathParameters['id'] ?? '')),
      GoRoute(path: Routes.chatInbox,
          builder: (_, __) => const ChatInboxScreen()),
      GoRoute(path: Routes.chatScreen,
          builder: (_, s) => ChatScreen(
              conversationId: s.pathParameters['id'] ?? '',
              conversation: s.extra as ConversationModel?)),
      GoRoute(path: Routes.notifications,
          builder: (_, __) => const NotificationsScreen()),
      GoRoute(path: Routes.customerProfile,
          builder: (_, __) => const CustomerProfileScreen()),
      GoRoute(path: Routes.editCustomerProfile,
          builder: (_, __) => const EditProfileScreen()),
      GoRoute(path: Routes.customerSettings,
          builder: (_, __) => const SettingsScreen()),
      GoRoute(path: Routes.savedMeasurements,
          builder: (_, __) => const SavedMeasurementsScreen()),
      GoRoute(path: Routes.measurementDetail,
          builder: (_, s) =>
              _Placeholder('Measurement #${s.pathParameters['id']}')),
      GoRoute(path: Routes.helpSupport,
          builder: (_, __) => const HelpSupportScreen()),

      // ── Tailor ────────────────────────────────────────────────────
      GoRoute(path: Routes.tailorDashboard,
          builder: (_, __) => const TailorDashboardScreen()),
      GoRoute(path: Routes.tailorOrderManagement,
          builder: (_, __) => const TailorOrderManagementScreen()),
      GoRoute(path: Routes.tailorOrderDetail,
          builder: (_, s) => OrderDetailScreen(
              orderId: s.pathParameters['id'] ?? '')),
      GoRoute(path: Routes.tailorProductManagement,
          builder: (_, __) => const TailorProductManagementScreen()),
      GoRoute(path: Routes.addEditProduct,
          builder: (_, s) => AddEditProductScreen(
              product: s.extra as ProductModel?)),
      GoRoute(path: Routes.clientList,
          builder: (_, __) => const _Placeholder('My Clients')),
      GoRoute(path: Routes.clientProfile,
          builder: (_, s) =>
              _Placeholder('Client #${s.pathParameters['id']}')),
      GoRoute(path: Routes.tailorChatInbox,
          builder: (_, __) => const ChatInboxScreen()),
      GoRoute(path: Routes.tailorChatScreen,
          builder: (_, s) => ChatScreen(
              conversationId: s.pathParameters['id'] ?? '',
              conversation: s.extra as ConversationModel?)),
      GoRoute(path: Routes.revenueDashboard,
          builder: (_, __) => const RevenueDashboardScreen()),
      GoRoute(path: Routes.payout,
          builder: (_, __) => const PayoutScreen()),
      GoRoute(path: Routes.tailorProfile,
          builder: (_, __) => const TailorProfileScreen()),
      GoRoute(path: Routes.editTailorProfile,
          builder: (_, __) => const EditProfileScreen()),
      GoRoute(path: Routes.tailorSettings,
          builder: (_, __) => const SettingsScreen()),

      // ── Shared ────────────────────────────────────────────────────
      GoRoute(path: Routes.styleGuide,
          builder: (_, __) => const _Placeholder('Style Guide')),
      GoRoute(path: Routes.fabricLibrary,
          builder: (_, __) => const _Placeholder('Fabric Library')),
      GoRoute(path: Routes.savedInspirations,
          builder: (_, __) => const _Placeholder('Saved Inspirations')),

      // ── Admin ─────────────────────────────────────────────────────
      GoRoute(path: Routes.adminLogin,
          builder: (_, __) => const AdminLoginScreen()),
      GoRoute(path: Routes.adminDashboard,
          builder: (_, __) => const AdminDashboardScreen()),
      GoRoute(path: Routes.adminUsers,
          builder: (_, __) => const AdminUsersScreen()),
      GoRoute(path: Routes.adminOrders,
          builder: (_, __) => const AdminOrdersScreen()),
      GoRoute(path: Routes.adminPayments,
          builder: (_, __) => const AdminPaymentsScreen()),
      GoRoute(path: Routes.adminPayouts,
          builder: (_, __) => const AdminPayoutsScreen()),
      GoRoute(path: Routes.adminProducts,
          builder: (_, __) => const AdminProductsScreen()),
      GoRoute(path: Routes.adminBroadcast,
          builder: (_, __) => const AdminBroadcastScreen()),
    ],
  );
});
