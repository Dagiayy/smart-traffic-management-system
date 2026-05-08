import 'package:flutter/material.dart';

/// Officer App palette — authoritative, high-contrast for outdoor/sunlight use.
/// Navy-blue primary conveys authority; semantic colors are vivid for quick scanning.
class AppColors {
  AppColors._();

  // ── Brand ─────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF0D2B4E);      // Deep navy — authority
  static const Color primaryDark = Color(0xFF061828);
  static const Color primaryLight = Color(0xFF1A4D8F);
  static const Color primarySurface = Color(0xFFEEF3FA);
  static const Color accent = Color(0xFF1565C0);        // Action blue

  // ── Neutrals ──────────────────────────────────────────────────────────
  static const Color black = Color(0xFF0A0E14);
  static const Color gray900 = Color(0xFF111827);
  static const Color gray800 = Color(0xFF1F2937);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray50  = Color(0xFFF9FAFB);
  static const Color white   = Color(0xFFFFFFFF);

  // ── Surfaces ──────────────────────────────────────────────────────────
  static const Color background   = Color(0xFFF4F6F9);
  static const Color surface      = white;
  static const Color divider      = Color(0xFFE2E8F0);
  static const Color border       = Color(0xFFDDE3ED);

  // ── Semantic ──────────────────────────────────────────────────────────
  static const Color success        = Color(0xFF15803D);
  static const Color successSurface = Color(0xFFE8F5EE);
  static const Color successText    = Color(0xFF166534);

  static const Color warning        = Color(0xFFB45309);
  static const Color warningSurface = Color(0xFFFEF6E7);
  static const Color warningText    = Color(0xFF92400E);

  static const Color danger         = Color(0xFFB91C1C);
  static const Color dangerSurface  = Color(0xFFFDECEC);
  static const Color dangerText     = Color(0xFF991B1B);

  static const Color info           = Color(0xFF1D4ED8);
  static const Color infoSurface    = Color(0xFFE7EEFB);
  static const Color infoText       = Color(0xFF1E40AF);

  // ── Sync status colors ────────────────────────────────────────────────
  static const Color syncedColor       = success;
  static const Color pendingSyncColor  = warning;
  static const Color failedSyncColor   = danger;

  // ── Severity ──────────────────────────────────────────────────────────
  static const Color severityMinor    = Color(0xFF0369A1);  // calm blue
  static const Color severityMajor    = Color(0xFFB45309);  // amber
  static const Color severityCritical = Color(0xFFB91C1C);  // red

  // ── Text ──────────────────────────────────────────────────────────────
  static const Color textPrimary   = gray900;
  static const Color textSecondary = gray600;
  static const Color textTertiary  = gray500;
  static const Color textDisabled  = gray400;
  static const Color textInverse   = white;
}
