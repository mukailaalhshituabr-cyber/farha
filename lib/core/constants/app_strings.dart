// lib/core/constants/app_strings.dart
// String keys used across the app — values live in app_en.arb / app_fr.arb
// Use these as keys when implementing full localization with flutter_localizations

class AppStrings {
  AppStrings._();

  // ── App ──────────────────────────────────────────────────────────────
  static const appName         = 'Farha';
  static const tagline         = 'The Digital Atelier';

  // ── Auth ─────────────────────────────────────────────────────────────
  static const login           = 'Login';
  static const logout          = 'Log Out';
  static const signUp          = 'Sign Up';
  static const email           = 'Email Address';
  static const phone           = 'Phone Number';
  static const password        = 'Password';
  static const confirmPassword = 'Confirm Password';
  static const forgotPassword  = 'Forgot Password?';
  static const resetPassword   = 'Reset Password';
  static const verifyEmail     = 'Verify Email';
  static const resendCode      = 'Resend Code';
  static const continueGuest   = 'Continue as Guest';
  static const alreadyAccount  = 'Already have an account?';
  static const noAccount       = "Don't have an account?";

  // ── Navigation ────────────────────────────────────────────────────────
  static const navHome         = 'Home';
  static const navShop         = 'Shop';
  static const navOrders       = 'Orders';
  static const navMessages     = 'Messages';
  static const navProfile      = 'Profile';
  static const navProducts     = 'Products';
  static const navClients      = 'Clients';

  // ── Products ──────────────────────────────────────────────────────────
  static const ourCollection   = 'Our Collection';
  static const readyMade       = 'Ready-Made';
  static const customMade      = 'Custom Made';
  static const addToCart       = 'Add to Cart';
  static const selectSize      = 'Select Size';
  static const sizeGuide       = 'Size Guide';
  static const description     = 'Description';
  static const craftedBy       = 'Crafted By';
  static const viewProfile     = 'View Profile';
  static const messageATailor  = 'Message Tailor';
  static const inStock         = 'In Stock';
  static const outOfStock      = 'Out of Stock';

  // ── Orders ────────────────────────────────────────────────────────────
  static const orderHistory    = 'Order History';
  static const trackOrder      = 'Track Order';
  static const orderSuccess    = 'Order Placed Successfully!';
  static const createOrder     = 'Create Custom Order';
  static const chooseTailor    = 'Choose Tailor';
  static const orderReview     = 'Review Order';
  static const cancelOrder     = 'Cancel Order';
  static const payBalance      = 'Pay Remaining Balance';

  // ── Measurements ─────────────────────────────────────────────────────
  static const measurements     = 'Measurements';
  static const savedMeasurements= 'Saved Measurements';
  static const addProfile       = 'Add New Profile';
  static const useForOrder      = 'Use for New Order';
  static const chestCirc        = 'Chest Circumference';
  static const waistCirc        = 'Waist Circumference';
  static const hipsCirc         = 'Hips Circumference';
  static const shoulderWidth    = 'Shoulder Width';
  static const sleeveLength     = 'Sleeve Length';
  static const totalLength      = 'Total Garment Length';

  // ── Payment ───────────────────────────────────────────────────────────
  static const payment          = 'Payment';
  static const totalInvoice     = 'Total Invoice';
  static const depositAmount    = 'Deposit (50%)';
  static const fullAmount       = 'Full Amount';
  static const payNow           = 'Pay Now';
  static const paymentSuccess   = 'Payment Successful';
  static const securePayment    = 'Secure Payment Gateway';

  // ── Profile ───────────────────────────────────────────────────────────
  static const editProfile      = 'Edit Profile';
  static const settings         = 'Settings';
  static const helpSupport      = 'Help & Support';
  static const language         = 'Language';
  static const notifications    = 'Notifications';
  static const memberSince      = 'Member since';

  // ── Tailor ───────────────────────────────────────────────────────────
  static const theAtelier       = 'The Digital Atelier';
  static const addProduct       = 'Add Product';
  static const listNewGarment   = 'List New Garment';
  static const revenue          = 'Revenue';
  static const totalRevenue     = 'Total Revenue';
  static const pendingBalance   = 'Pending Balances';
  static const requestPayout    = 'Request Payout';

  // ── Common ────────────────────────────────────────────────────────────
  static const save             = 'Save';
  static const cancel           = 'Cancel';
  static const confirm          = 'Confirm';
  static const delete           = 'Delete';
  static const edit             = 'Edit';
  static const search           = 'Search';
  static const filter           = 'Filter';
  static const sort             = 'Sort';
  static const viewAll          = 'View All';
  static const retry            = 'Try Again';
  static const loading          = 'Loading...';
  static const noResults        = 'No results found';
  static const noInternet       = 'No internet connection';
  static const somethingWrong   = 'Something went wrong';
  static const required         = 'This field is required';
}
