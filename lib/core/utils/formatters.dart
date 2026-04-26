// lib/core/utils/formatters.dart
import 'package:intl/intl.dart';

class AppFormatters {
  AppFormatters._();

  // ── Currency ─────────────────────────────────────────────────────────────
  static String currency(double amount, {String symbol = 'CFA'}) {
    final formatter = NumberFormat('#,##0', 'en_US');
    return '${formatter.format(amount)} $symbol';
  }

  static String currencyCompact(double amount, {String symbol = 'CFA'}) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M $symbol';
    if (amount >= 1000)    return '${(amount / 1000).toStringAsFixed(0)}k $symbol';
    return currency(amount, symbol: symbol);
  }

  // ── Dates ─────────────────────────────────────────────────────────────────
  static String date(DateTime dt) => DateFormat('MMM dd, yyyy').format(dt);
  static String dateShort(DateTime dt) => DateFormat('dd MMM').format(dt);
  static String dateTime(DateTime dt) => DateFormat('MMM dd, yyyy • hh:mm a').format(dt);
  static String timeOnly(DateTime dt) => DateFormat('hh:mm a').format(dt);

  static String relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    if (diff.inDays < 7)     return '${diff.inDays}d ago';
    return date(dt);
  }

  static String? parseDate(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    try { return date(DateTime.parse(iso)); } catch (_) { return iso; }
  }

  // ── Phone ─────────────────────────────────────────────────────────────────
  static String phone(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^\d+]'), '');
    return digits;
  }

  // ── Order reference ───────────────────────────────────────────────────────
  static String orderRef(String ref) => ref.startsWith('#') ? ref : '#$ref';

  // ── Initials (for avatar) ─────────────────────────────────────────────────
  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
  }

  // ── Masked email ─────────────────────────────────────────────────────────
  static String maskedEmail(String email) {
    final at = email.indexOf('@');
    if (at <= 3) return email;
    return '${email.substring(0, 3)}***${email.substring(at)}';
  }

  // ── File size ─────────────────────────────────────────────────────────────
  static String fileSize(int bytes) {
    if (bytes < 1024)       return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  // ── Rating ────────────────────────────────────────────────────────────────
  static String rating(double r) => r.toStringAsFixed(1);
}
