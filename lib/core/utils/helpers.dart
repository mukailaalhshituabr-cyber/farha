// lib/core/utils/helpers.dart
import 'dart:async';
import 'package:flutter/material.dart';

// ── Debouncer (for search input) ──────────────────────────────────────────
class Debouncer {
  final Duration delay;
  Timer? _timer;
  Debouncer({this.delay = const Duration(milliseconds: 500)});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() => _timer?.cancel();
}

// ── String extensions ─────────────────────────────────────────────────────
extension StringX on String {
  String get capitalised =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  String get titleCase => split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
      .join(' ');

  bool get isValidEmail =>
      RegExp(r'^[\w.+\-]+@[a-zA-Z\d\-]+\.[a-zA-Z\d\.\-]+$').hasMatch(this);
}

// ── Order status helpers ──────────────────────────────────────────────────
class OrderStatusHelper {
  static const _order = ['pending','confirmed','cutting','sewing','ready','delivered','cancelled'];

  static int stepIndex(String status) => _order.indexOf(status);

  static bool isCompleted(String status) => status == 'delivered';
  static bool isCancelled(String status) => status == 'cancelled';
  static bool isActive(String status)    =>
      !isCompleted(status) && !isCancelled(status);

  static Color color(String status, BuildContext context) {
    switch (status) {
      case 'pending':   return const Color(0xFFB45309);
      case 'confirmed': return const Color(0xFF1D4ED8);
      case 'cutting':   return const Color(0xFF7C3AED);
      case 'sewing':    return const Color(0xFF7C3AED);
      case 'ready':     return const Color(0xFF059669);
      case 'delivered': return const Color(0xFF1E6F3E);
      case 'cancelled': return const Color(0xFFBA1A1A);
      default:          return const Color(0xFF887272);
    }
  }

  static String label(String status) => status.titleCase;

  static IconData icon(String status) {
    switch (status) {
      case 'pending':   return Icons.schedule_rounded;
      case 'confirmed': return Icons.check_circle_outline_rounded;
      case 'cutting':   return Icons.content_cut_rounded;
      case 'sewing':    return Icons.checkroom_rounded;
      case 'ready':     return Icons.inventory_2_rounded;
      case 'delivered': return Icons.local_shipping_rounded;
      case 'cancelled': return Icons.cancel_outlined;
      default:          return Icons.help_outline_rounded;
    }
  }
}

// ── Payment method helpers ────────────────────────────────────────────────
class PaymentMethodHelper {
  static String label(String method) {
    const map = {
      'mtn_momo':    'MTN Mobile Money',
      'orange_money':'Orange Money',
      'moov_money':  'Moov Money',
      'mynita':      'myNita Wallet',
      'bank_card':   'Bank Card (VISA/MC)',
    };
    return map[method] ?? method;
  }

  static IconData icon(String method) {
    switch (method) {
      case 'bank_card': return Icons.credit_card_rounded;
      default:          return Icons.account_balance_wallet_outlined;
    }
  }
}

// ── Garment type helpers ──────────────────────────────────────────────────
class GarmentHelper {
  static String label(String type) {
    const map = {
      'agbada':  'Agbada',
      'kaftan':  'Kaftan',
      'jalabia': 'Jalabia',
      'shirt':   'Shirt',
      'dress':   'Dress',
      'trousers':'Trousers',
      'jacket':  'Jacket',
      'buba_iro':'Buba & Iro',
      'other':   'Other',
    };
    return map[type] ?? type.titleCase;
  }

  static IconData icon(String type) {
    switch (type) {
      case 'trousers': return Icons.straighten_rounded;
      case 'dress':    return Icons.style_rounded;
      case 'kaftan':
      case 'jalabia':
      case 'agbada':   return Icons.dry_cleaning_rounded;
      default:         return Icons.checkroom_rounded;
    }
  }
}

// ── Experience level helpers ──────────────────────────────────────────────
class ExperienceHelper {
  static String label(String level) {
    const map = {
      'apprentice':   '1–3 Years (Apprentice)',
      'intermediate': '3–7 Years (Intermediate)',
      'master':       '7–15 Years (Master Tailor)',
      'grandmaster':  '15+ Years (Grandmaster)',
    };
    return map[level] ?? level.titleCase;
  }

  static String badge(String level) {
    const map = {
      'apprentice':   'Apprentice',
      'intermediate': 'Intermediate',
      'master':       'Master Tailor',
      'grandmaster':  'Grandmaster',
    };
    return map[level] ?? level.titleCase;
  }
}
