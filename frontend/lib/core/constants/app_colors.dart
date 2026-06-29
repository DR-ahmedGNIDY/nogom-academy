import 'package:flutter/material.dart';

/// Brand and semantic colors for the app — light mode only (professional blue identity).
class AppColors {
  AppColors._();

  // ── Primary — professional blue ────────────────────────────────────────
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFF60A5FA);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryContainer = Color(0xFFE3EDFD);

  // ── Secondary ───────────────────────────────────────────────────────────
  static const Color secondary = Color(0xFF3B82F6);
  static const Color secondaryLight = Color(0xFF60A5FA);
  static const Color secondaryDark = Color(0xFF1D4ED8);
  static const Color secondaryContainer = Color(0xFFE3EDFD);

  // ── Success / Warning / Error ──────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color successLight = Color(0xFFE8F7EC);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);

  static const Color error = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color errorDark = Color(0xFFB91C1C);

  // ── Absolute ────────────────────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF0A0A0A);

  // ── Neutral / text scale ───────────────────────────────────────────────
  static const Color grey900 = Color(0xFF0F172A);
  static const Color grey800 = Color(0xFF1F2937);
  static const Color grey700 = Color(0xFF374151);
  static const Color grey600 = Color(0xFF4B5563);
  static const Color grey500 = Color(0xFF64748B);
  static const Color grey400 = Color(0xFF9CA3AF);
  static const Color grey300 = Color(0xFFD1D5DB);
  static const Color grey200 = Color(0xFFE5E7EB);
  static const Color grey100 = Color(0xFFF3F4F6);
  static const Color grey50 = Color(0xFFF9FAFB);

  // ── Surfaces ────────────────────────────────────────────────────────────
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF3F4F6);
  static const Color card = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE2E8F0);
}
