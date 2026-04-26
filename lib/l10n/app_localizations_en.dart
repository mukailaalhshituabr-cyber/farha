// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppL10nEn extends AppL10n {
  AppL10nEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Farha';

  @override
  String get tagline => 'The Digital Atelier';

  @override
  String get login => 'Login';

  @override
  String get logout => 'Log Out';

  @override
  String get signUp => 'Sign Up';

  @override
  String get continueGuest => 'Continue as Guest';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get email => 'Email Address';

  @override
  String get phone => 'Phone Number';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get sendResetCode => 'Send Reset Code';

  @override
  String get verifyCode => 'Verify Code';

  @override
  String get resendCode => 'Resend Code';

  @override
  String get newPassword => 'New Password';

  @override
  String get verifyEmailTitle => 'Check Your Email';

  @override
  String verifyEmailBody(String email) {
    return 'We sent a verification link to $email. Click it to verify your account.';
  }

  @override
  String get createCustomerAccount => 'Create Customer Account';

  @override
  String get createTailorAccount => 'Create Tailor Account';

  @override
  String get firstName => 'First Name';

  @override
  String get lastName => 'Last Name';

  @override
  String get gender => 'Gender';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get other => 'Other';

  @override
  String get preferNotToSay => 'Prefer not to say';

  @override
  String get preferredLanguage => 'Preferred Language';

  @override
  String get shopName => 'Shop / Business Name';

  @override
  String get shopLocation => 'Shop Location';

  @override
  String get yearsExperience => 'Years of Experience';

  @override
  String get aboutWork => 'About Your Work (optional)';

  @override
  String get termsAgreement =>
      'I agree to the Terms of Service and Privacy Policy';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get signInDetails => 'Please enter your details to sign in';

  @override
  String get emailOrPhone => 'Email or Phone';

  @override
  String get iAm => 'I am a...';

  @override
  String get chooseAccountType =>
      'Choose the account type that best fits your journey in the atelier.';

  @override
  String get customer => 'Customer';

  @override
  String get customerSubtitle => 'I want to order clothes';

  @override
  String get tailor => 'Tailor';

  @override
  String get tailorSubtitle => 'I want to sell my work';

  @override
  String get home => 'Home';

  @override
  String get shop => 'Shop';

  @override
  String get orders => 'Orders';

  @override
  String get messages => 'Messages';

  @override
  String get profile => 'Profile';

  @override
  String get products => 'Products';

  @override
  String get clients => 'Clients';

  @override
  String get revenue => 'Revenue';

  @override
  String get ourCollection => 'Our Collection';

  @override
  String get readyMade => 'Ready-Made';

  @override
  String get customMade => 'Custom Made';

  @override
  String get shopNow => 'Shop now';

  @override
  String get orderNow => 'Order now';

  @override
  String get allCategories => 'All';

  @override
  String get filterProducts => 'Filter';

  @override
  String get sortProducts => 'Sort';

  @override
  String get addToCart => 'Add to Cart';

  @override
  String get addToWishlist => 'Add to Wishlist';

  @override
  String get selectSize => 'Select Size';

  @override
  String get sizeGuide => 'Size Guide';

  @override
  String get quantity => 'Quantity';

  @override
  String get description => 'Description';

  @override
  String get craftedBy => 'Crafted By';

  @override
  String get viewProfile => 'View Profile';

  @override
  String get messageTailor => 'Message Tailor';

  @override
  String get reviews => 'Reviews';

  @override
  String get allReviews => 'All Reviews';

  @override
  String get verifiedBuyer => 'Verified Buyer';

  @override
  String get orderHistory => 'Order History';

  @override
  String get trackOrder => 'Track Order';

  @override
  String get viewDetails => 'View Details';

  @override
  String get cancelOrder => 'Cancel Order';

  @override
  String get payBalance => 'Pay Remaining Balance';

  @override
  String get inProgress => 'In Progress';

  @override
  String get completed => 'Completed';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get refundProcessed => 'Refund Processed';

  @override
  String get createCustomOrder => 'Create Custom Order';

  @override
  String get chooseTailor => 'Choose Tailor';

  @override
  String get orderReview => 'Review Order';

  @override
  String get placeOrder => 'Place Order';

  @override
  String get orderSuccess => 'Order Placed Successfully!';

  @override
  String get orderSuccessBody => 'Your celebration of craftsmanship has begun.';

  @override
  String get payment => 'Payment';

  @override
  String get totalInvoice => 'Total Invoice';

  @override
  String get depositPlan => 'Deposit (50%)';

  @override
  String get fullAmount => 'Full Amount';

  @override
  String get payNow => 'Pay Now';

  @override
  String get securePayment => 'Secure Payment Gateway';

  @override
  String get paymentMethod => 'Payment Methods';

  @override
  String get measurements => 'Measurements';

  @override
  String get savedMeasurements => 'Saved Measurements';

  @override
  String get addProfile => 'Add New Profile';

  @override
  String get useForOrder => 'Use for New Order';

  @override
  String get chest => 'Chest Circumference';

  @override
  String get waist => 'Waist Circumference';

  @override
  String get hips => 'Hips Circumference';

  @override
  String get shoulder => 'Shoulder Width';

  @override
  String get sleeve => 'Sleeve Length';

  @override
  String get totalLength => 'Total Garment Length';

  @override
  String get unit_cm => 'cm';

  @override
  String get unit_inches => 'inches';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get settings => 'Settings';

  @override
  String get helpSupport => 'Help & Support';

  @override
  String get language => 'Language';

  @override
  String get notifications => 'Notifications';

  @override
  String get memberSince => 'Member since';

  @override
  String get sharePortfolio => 'Share Portfolio';

  @override
  String get listNewGarment => 'List New Garment';

  @override
  String get productName => 'Product Name';

  @override
  String get category => 'Category';

  @override
  String get basePrice => 'Base Price';

  @override
  String get stockQuantity => 'Stock Quantity';

  @override
  String get allowCustom => 'Customization Available';

  @override
  String get availableForSale => 'Available for Sale';

  @override
  String get addPhotos => 'Add Photos';

  @override
  String get totalRevenue => 'Total Revenue';

  @override
  String get pendingBalances => 'Pending Balances';

  @override
  String get thisWeek => 'This Week';

  @override
  String get thisMonth => 'This Month';

  @override
  String get thisYear => 'This Year';

  @override
  String get requestPayout => 'Request Payout';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get search => 'Search';

  @override
  String get filter => 'Filter';

  @override
  String get sort => 'Sort';

  @override
  String get viewAll => 'View All';

  @override
  String get retry => 'Try Again';

  @override
  String get loading => 'Loading...';

  @override
  String get noResults => 'No results found';

  @override
  String get noInternet => 'No internet connection';

  @override
  String get somethingWrong => 'Something went wrong';

  @override
  String get fieldRequired => 'This field is required';

  @override
  String get continueLabel => 'Continue';

  @override
  String get continueAsGuest => 'Continue as Guest';

  @override
  String get logoutConfirmTitle => 'Log Out';

  @override
  String get logoutConfirmBody => 'Are you sure you want to log out of Farha?';

  @override
  String get goodMorning => 'Good morning';

  @override
  String get goodAfternoon => 'Good afternoon';

  @override
  String get goodEvening => 'Good evening';

  @override
  String get activeOrders => 'Active Orders';

  @override
  String get noActiveOrders => 'No active orders';

  @override
  String get ordersAppearHere => 'Your orders will appear here';

  @override
  String get featuredTailors => 'Featured Tailors';

  @override
  String get recentOrders => 'Recent Orders';

  @override
  String get noOrdersYet => 'No orders yet';

  @override
  String get trackOrderArrow => 'Track Order →';

  @override
  String completePercent(int percent) {
    return '$percent% complete';
  }

  @override
  String get stagePending => 'Pending';

  @override
  String get stageCutting => 'Cutting';

  @override
  String get stageSewing => 'Sewing';

  @override
  String get stageReady => 'Ready';

  @override
  String get stageDelivered => 'Delivered';

  @override
  String get stageConfirmed => 'Confirmed';

  @override
  String get stageCancelled => 'Cancelled';

  @override
  String get todaysRevenue => 'Today\'s Revenue';

  @override
  String get digitalAtelierBuzzing => 'The Digital Atelier is buzzing.';

  @override
  String get onboardingTitle1 => 'The Digital Atelier';

  @override
  String get onboardingSubtitle1 =>
      'Bridging Tailors and Customers with Joy. Crafting Tailored Joy.';

  @override
  String get onboardingTitle2 => 'Perfect Measurements';

  @override
  String get onboardingSubtitle2 =>
      'Save your measurements once, use them for every custom order you place.';

  @override
  String get onboardingTitle3 => 'Track Every Stitch';

  @override
  String get onboardingSubtitle3 =>
      'Watch your garment come to life — from cutting to delivery.';

  @override
  String get orContinueWith => 'Or continue with';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get googleSignInComingSoon => 'Google sign-in coming soon.';

  @override
  String get emailOrPhoneHint => 'name@example.com or +1234567890';

  @override
  String get signInToContinue => 'Sign in to continue to your account';

  @override
  String get emailPhoneRequired => 'Email or phone number is required';

  @override
  String get invalidEmail =>
      'Please enter a valid email address (e.g. name@example.com)';

  @override
  String get invalidPhone =>
      'Enter a valid email (name@domain.com) or phone (+1234567890)';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get passwordTooShort => 'Password must be at least 8 characters';

  @override
  String get passwordNeedsUppercase =>
      'Password must contain at least one uppercase letter';

  @override
  String get passwordNeedsLowercase =>
      'Password must contain at least one lowercase letter';

  @override
  String get passwordNeedsNumber => 'Password must contain at least one number';

  @override
  String get passwordNeedsSpecial =>
      'Password must contain at least one special character (!@#\$...)';

  @override
  String get emailNotVerified =>
      'Your email is not verified. Please check your inbox.';

  @override
  String get connectionError =>
      'Cannot connect to server. Please check your internet connection.';

  @override
  String get attemptsExceeded =>
      'You have exceeded 3 login attempts. Redirecting...';

  @override
  String get wrongCredentials1 =>
      'Wrong email or password. You have 1 attempt left.';

  @override
  String wrongCredentialsN(int remaining) {
    return 'Wrong email or password. You have $remaining attempts left.';
  }

  @override
  String get english => 'English';

  @override
  String get french => 'Français';

  @override
  String balanceDue(String amount) {
    return 'Balance: $amount';
  }

  @override
  String get changePhoto => 'Change Photo';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get chooseFromGallery => 'Choose from Gallery';

  @override
  String get permissionRequired => 'Permission Required';

  @override
  String get permissionCameraBody =>
      'Camera access is needed to take a profile photo. Please grant permission in Settings.';

  @override
  String get permissionGalleryBody =>
      'Photo library access is needed to choose a profile photo. Please grant permission in Settings.';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get photoUpdated => 'Profile photo updated';

  @override
  String get photoFailed => 'Failed to update photo';

  @override
  String get experienceLevel => 'Experience Level';

  @override
  String get rating => 'Rating';

  @override
  String get verified => 'Verified';

  @override
  String get notVerified => 'Not Verified';

  @override
  String get accountInfo => 'Account Info';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get appLanguage => 'App Language';

  @override
  String get notificationsEnabled => 'Notifications Enabled';

  @override
  String get pushNotifications => 'Push Notifications';

  @override
  String get appearance => 'Appearance';

  @override
  String get about => 'About';

  @override
  String get version => 'Version';
}
