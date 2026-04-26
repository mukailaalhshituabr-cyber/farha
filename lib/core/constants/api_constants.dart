// lib/core/constants/api_constants.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  ApiConstants._();

  // Base URL — flat structure, all PHP files at root of farha_api/
  // Android emulator: 10.0.2.2 maps to your dev machine's localhost
  // School server:    change API_BASE_URL in your .env file
  static String get baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2/farha_api';

  // ── Auth ─────────────────────────────────────────────────────────────────
  static String get googleAuth       => '$baseUrl/google_auth.php';
  static String get registerCustomer => '$baseUrl/register_customer.php';
  static String get registerTailor   => '$baseUrl/register_tailor.php';
  static String get login            => '$baseUrl/login.php';
  static String get logout           => '$baseUrl/logout.php';
  static String get verifyEmail      => '$baseUrl/verify_email.php';
  static String get forgotPassword   => '$baseUrl/forgot_password.php';
  static String get verifyOtp        => '$baseUrl/verify_otp.php';
  static String get resetPassword    => '$baseUrl/reset_password.php';
  static String get refreshToken     => '$baseUrl/refresh_token.php';

  // ── Users ────────────────────────────────────────────────────────────────
  static String get profile     => '$baseUrl/profile.php';
  static String get uploadPhoto        => '$baseUrl/upload_photo.php';
  static String get uploadProductImage => '$baseUrl/upload_product_image.php';
  static String get settings    => '$baseUrl/settings.php';

  // ── Products ─────────────────────────────────────────────────────────────
  static String get productList   => '$baseUrl/products_list.php';
  static String get productDetail => '$baseUrl/products_detail.php';
  static String get productSearch => '$baseUrl/products_search.php';
  static String get productCreate => '$baseUrl/products_create.php';
  static String get productUpdate => '$baseUrl/products_update.php';
  static String get productDelete => '$baseUrl/products_delete.php';

  // ── Tailors ──────────────────────────────────────────────────────────────
  static String get tailorList    => '$baseUrl/tailors_list.php';
  static String get tailorProfile => '$baseUrl/tailors_profile.php';
  static String get tailorSearch  => '$baseUrl/tailors_search.php';

  // ── Orders ───────────────────────────────────────────────────────────────
  static String get orderCreate       => '$baseUrl/orders_create.php';
  static String get orderList         => '$baseUrl/orders_list.php';
  static String get orderDetail       => '$baseUrl/orders_detail.php';
  static String get orderUpdateStatus => '$baseUrl/orders_update_status.php';
  static String get orderCancel       => '$baseUrl/orders_cancel.php';

  // ── Measurements ─────────────────────────────────────────────────────────
  static String get measurementList   => '$baseUrl/measurements_list.php';
  static String get measurementCreate => '$baseUrl/measurements_create.php';
  static String get measurementUpdate => '$baseUrl/measurements_update.php';
  static String get measurementDelete => '$baseUrl/measurements_delete.php';

  // ── Payments ─────────────────────────────────────────────────────────────
  static String get paymentInitiate => '$baseUrl/payments_initiate.php';
  static String get paymentVerify   => '$baseUrl/payments_verify.php';
  static String get paymentHistory  => '$baseUrl/payments_history.php';

  // ── Cart ─────────────────────────────────────────────────────────────────
  static String get cartGet    => '$baseUrl/cart_get.php';
  static String get cartAdd    => '$baseUrl/cart_add.php';
  static String get cartUpdate => '$baseUrl/cart_update.php';
  static String get cartRemove => '$baseUrl/cart_remove.php';

  // ── Wishlist ─────────────────────────────────────────────────────────────
  static String get wishlistGet    => '$baseUrl/wishlist_get.php';
  static String get wishlistAdd    => '$baseUrl/wishlist_add.php';
  static String get wishlistRemove => '$baseUrl/wishlist_remove.php';

  // ── Chat ─────────────────────────────────────────────────────────────────
  static String get conversations => '$baseUrl/conversations.php';
  static String get messages      => '$baseUrl/messages.php';
  static String get markRead      => '$baseUrl/messages_mark_read.php';

  // ── Notifications ─────────────────────────────────────────────────────────
  static String get notificationList     => '$baseUrl/notifications_list.php';
  static String get notificationMarkRead => '$baseUrl/notifications_mark_read.php';

  // ── Reviews ───────────────────────────────────────────────────────────────
  static String get reviewList   => '$baseUrl/reviews_list.php';
  static String get reviewCreate => '$baseUrl/reviews_create.php';

  // ── Revenue (tailor) ──────────────────────────────────────────────────────
  static String get revenueSummary => '$baseUrl/revenue_summary.php';
  static String get payout         => '$baseUrl/revenue_payout.php';

  // ── Admin ─────────────────────────────────────────────────────────────────
  static String get adminLogin          => '$baseUrl/admin_login.php';
  static String get adminStats          => '$baseUrl/admin_stats.php';
  static String get adminUsers          => '$baseUrl/admin_users.php';
  static String get adminTailorApprove  => '$baseUrl/admin_tailor_approve.php';
  static String get adminOrders         => '$baseUrl/admin_orders.php';
  static String get adminPayments       => '$baseUrl/admin_payments.php';
  static String get adminPayouts        => '$baseUrl/admin_payouts.php';
  static String get adminProducts       => '$baseUrl/admin_products.php';
  static String get adminBroadcast      => '$baseUrl/admin_broadcast.php';
  static String get adminManage         => '$baseUrl/admin_manage.php';

  // ── Timeouts ──────────────────────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 60);
  static const Duration sendTimeout    = Duration(seconds: 120);
}
