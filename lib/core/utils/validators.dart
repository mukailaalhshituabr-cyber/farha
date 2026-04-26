// lib/core/utils/validators.dart

class AppValidators {
  AppValidators._();

  static String? Function(String?) required(String label) =>
      (v) => (v == null || v.trim().isEmpty) ? '$label is required.' : null;

  static String? Function(String?) email() => (v) {
    if (v == null || v.isEmpty) return null;
    final re = RegExp(r'^[\w.+\-]+@[a-zA-Z\d\-]+\.[a-zA-Z\d\.\-]+$');
    return re.hasMatch(v.trim()) ? null : 'Please enter a valid email address.';
  };

  static String? Function(String?) phone() => (v) {
    if (v == null || v.isEmpty) return null;
    final clean = v.replaceAll(RegExp(r'[\s\-\(\)\.]'), '');
    // International: +CC... or CC... or 00CC...
    if (RegExp(r'^\+?[1-9]\d{6,14}$').hasMatch(clean)) return null;
    if (RegExp(r'^00[1-9]\d{5,13}$').hasMatch(clean)) return null;
    // Local format: 0 followed by 7–11 digits (e.g. 0543249743 in Ghana)
    if (RegExp(r'^0\d{7,11}$').hasMatch(clean)) return null;
    return 'Please enter a valid phone number (e.g. +233543249743 or 0543249743).';
  };

  static String? Function(String?) strongPassword() => (v) {
    if (v == null || v.isEmpty) return null;
    final errs = <String>[];
    if (v.length < 8)                           errs.add('at least 8 characters');
    if (!RegExp(r'[A-Z]').hasMatch(v))           errs.add('one uppercase letter');
    if (!RegExp(r'[a-z]').hasMatch(v))           errs.add('one lowercase letter');
    if (!RegExp(r'[0-9]').hasMatch(v))           errs.add('one number');
    if (!RegExp(r'[\W_]').hasMatch(v))           errs.add('one special character');
    return errs.isEmpty ? null : 'Password needs ${errs.join(', ')}.';
  };

  static String? Function(String?) minLength(int min, String label) => (v) {
    if (v == null || v.isEmpty) return null;
    return v.trim().length < min ? '$label must be at least $min characters.' : null;
  };

  static String? Function(String?) matchPassword(String Function() getOther) => (v) {
    if (v == null || v.isEmpty) return null;
    return v != getOther() ? 'Passwords do not match.' : null;
  };

  static String? Function(String?) otp() => (v) {
    if (v == null || v.isEmpty) return 'Please enter the 6-digit code.';
    return RegExp(r'^\d{6}$').hasMatch(v) ? null : 'Code must be exactly 6 digits.';
  };

  // Live password strength (0.0 – 1.0)
  static double passwordStrength(String password) {
    if (password.isEmpty) return 0;
    double score = 0;
    if (password.length >= 8)                 score += 0.2;
    if (password.length >= 12)                score += 0.1;
    if (RegExp(r'[A-Z]').hasMatch(password))  score += 0.2;
    if (RegExp(r'[a-z]').hasMatch(password))  score += 0.2;
    if (RegExp(r'[0-9]').hasMatch(password))  score += 0.15;
    if (RegExp(r'[\W_]').hasMatch(password))  score += 0.15;
    return score.clamp(0.0, 1.0);
  }
}
